// The render thread: command lists run on a thread of their own, the game's thread only queues them - the way a real
// GPU takes them, so the game's next frame (its CPU work) overlaps this one's command translation and driver calls.
// Phones need it: on an S20 FE the executor and the Vulkan driver are about a third of the game thread's time.
//
// What keeps it right is the order: one queue, run in order, and every place the game can see the GPU's progress
// waits for the queue to reach the point it asked about first:
//  - nvnSyncWait: the sync's last signal - a queue fence (nvnQueueFenceSync) or a fence inside a submitted list
//    (found when the list is queued) - has run here before the usual wait for the GPU;
//  - nvnQueueFinish, reboots, anything that touches the renderer from the game's side: the whole queue has run;
//  - present: at most one frame queued ahead, so input and pacing stay as they were.
// Host objects a queued list may still use (textures, programs, samplers, syncs) are freed from here, in order.
// LARECOMP_RENDER_THREAD=0/1: off / on (default on for Android; Vulkan only).
#include <pthread.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../platform.h"
#include "../rt.h"
#include "nvn.h"

enum { OP_EXEC, OP_FENCE, OP_PRESENT, OP_TEX_DESTROYED, OP_FREE, OP_CALL };
typedef struct {
    int op;
    uint64_t a;
    void *p;
    void (*fn)(void *);
} GtOp;

#define GT_N 1024
static GtOp ring[GT_N];
static uint64_t head, tail;  // ops queued / ops done (mu)
static bool idle;           // the render thread waits for work (mu): only then is it woken
static pthread_mutex_t mu = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t cv_work = PTHREAD_COND_INITIALIZER, cv_done = PTHREAD_COND_INITIALIZER;
static _Atomic int g_on = -1;
static pthread_t g_thread;
static _Atomic(pthread_t *) g_self;
static uint64_t last_present;  // ticket of the last queued present (game side)

extern __thread uint64_t g_blocked_ns;  // kernel.c: this thread's time blocked in waits (the pacing's busy time)
void renderer_sync(void);
void renderer_flush(void);
uint64_t renderer_fence_seq(void);
void renderer_wait_seq(uint64_t seq);
void nvn_sync_ticket(uint64_t guest, uint64_t ticket);  // objects.c

static void run(GtOp *o) {
    switch (o->op) {
    case OP_EXEC: backend_execute(o->a); break;
    case OP_FENCE: {
        extern void nvn_sync_set_seq(uint64_t guest, uint64_t seq);
        nvn_sync_set_seq(o->a, renderer_fence_seq());
        break;
    }
    case OP_PRESENT: {
        static unsigned n;
        if (n++ % 120 == 0) plat_thread_core(PLAT_CORE_RENDER);  // (as the game's thread: device.c present_game)
#ifndef __APPLE__
        extern void backend_present_gpu(NvnTexture *t);  // (the Vulkan backend's present without the game's hooks)
        backend_present_gpu(o->p);
#endif
        break;
    }
    case OP_TEX_DESTROYED: backend_texture_destroyed(o->p); free(o->p); break;
    case OP_FREE: free(o->p); break;
    case OP_CALL: o->fn(o->p); break;
    }
}

static void *gt_main(void *arg) {
    (void)arg;
    plat_thread_name("render");
    plat_thread_core(PLAT_CORE_RENDER);
    plat_crash_handler_install();
    pthread_mutex_lock(&mu);
    for (;;) {
        while (tail == head) {
            idle = true;
            pthread_cond_wait(&cv_work, &mu);
        }
        idle = false;
        GtOp o = ring[tail % GT_N];
        pthread_mutex_unlock(&mu);
        run(&o);
        pthread_mutex_lock(&mu);
        tail++;
        pthread_cond_broadcast(&cv_done);
    }
    return NULL;
}

static void start(void) {
    const char *e = getenv("LARECOMP_RENDER_THREAD");
#if defined(__ANDROID__)
    int on = !e || atoi(e) != 0;
#elif defined(__APPLE__)
    int on = 0;  // (the Metal backend presents on the game's thread)
    (void)e;
#else
    int on = e && atoi(e) != 0;
#endif
    if (on) {
        pthread_attr_t at;
        pthread_attr_init(&at);
        pthread_attr_setstacksize(&at, 8 << 20);
        pthread_create(&g_thread, &at, gt_main, NULL);
        pthread_attr_destroy(&at);
        atomic_store(&g_self, &g_thread);
        LOG("[gpu] command lists run on a render thread\n");
    }
    g_on = on;
}

bool gt_on(void) {
    static pthread_once_t once = PTHREAD_ONCE_INIT;
    if (g_on < 0) pthread_once(&once, start);
    return g_on > 0;
}

static bool on_render_thread(void) {
    pthread_t *t = atomic_load(&g_self);
    return t && pthread_equal(*t, pthread_self());
}

// Wait (counted as blocked time) until the ops up to ticket have run.
static void wait_ticket(uint64_t ticket) {
    pthread_mutex_lock(&mu);
    if (tail < ticket) {
        uint64_t t0 = plat_now_ns();
        while (tail < ticket) pthread_cond_wait(&cv_done, &mu);
        g_blocked_ns += plat_now_ns() - t0;
    }
    pthread_mutex_unlock(&mu);
}

static uint64_t push(GtOp o) {
    pthread_mutex_lock(&mu);
    if (head - tail >= GT_N) {
        uint64_t t0 = plat_now_ns();
        while (head - tail >= GT_N) pthread_cond_wait(&cv_done, &mu);
        g_blocked_ns += plat_now_ns() - t0;
    }
    ring[head % GT_N] = o;
    uint64_t t = ++head;
    if (idle) pthread_cond_signal(&cv_work);
    pthread_mutex_unlock(&mu);
    return t;
}

void gt_drain(void) {
    if (g_on <= 0 || on_render_thread()) return;
    pthread_mutex_lock(&mu);
    uint64_t t = head;
    pthread_mutex_unlock(&mu);
    wait_ticket(t);
}

// fn(arg) on the render thread after everything queued before it, and back when it's done.
void gt_call(void (*fn)(void *), void *arg) {
    if (!gt_on() || on_render_thread()) { fn(arg); return; }
    wait_ticket(push((GtOp){.op = OP_CALL, .fn = fn, .p = arg}));
}

// Fences recorded in a list (and the lists it calls): their syncs are signaled by this queued op.
static void mark_fences(uint64_t handle, uint64_t ticket, int depth) {
    const CmdRec *first = (const CmdRec *)(uintptr_t)handle;
    if (first->op == CMD_BARRIER && first->x[6] != CMD_LIST_FENCES) return;  // (none: cmdbuf.c EndRecording)
    uint64_t p = handle;
    for (int guard = 0; guard < 10000000; guard++) {
        const CmdRec *r = (const CmdRec *)(uintptr_t)p;
        switch (r->op) {
        case CMD_END: return;
        case CMD_JUMP: p = r->x[0]; continue;
        case CMD_CALL: {
            const uint64_t *h = (const uint64_t *)r->extra;
            for (uint64_t i = 0; i < r->x[0] && depth < 8; i++) mark_fences(h[i], ticket, depth + 1);
            break;
        }
        case CMD_FENCE_SYNC:
            if (r->x[1]) nvn_sync_ticket(r->x[1], ticket);
            break;
        }
        if (r->size < offsetof(CmdRec, extra)) return;  // (malformed: stop)
        p += r->size;
    }
}

void gt_submit(uint64_t handle) {
    if (!gt_on()) { backend_execute(handle); return; }
    uint64_t t = push((GtOp){.op = OP_EXEC, .a = handle});
    mark_fences(handle, t, 0);
}

uint64_t gt_fence(uint64_t sync_guest) {  // the ticket nvnSyncWait waits for (0: done already, off)
    if (!gt_on()) return 0;
    return push((GtOp){.op = OP_FENCE, .a = sync_guest});
}

void gt_sync_wait(uint64_t ticket) {
    if (g_on > 0 && ticket) wait_ticket(ticket);
}

void gt_finish(void) {
    gt_drain();
    renderer_sync();
}

void gt_present(NvnTexture *t) {
    // at most one frame ahead: the previous present has gone out before this one is queued
    if (last_present) wait_ticket(last_present);
    last_present = push((GtOp){.op = OP_PRESENT, .p = t});
}

void gt_texture_destroyed(NvnTexture *t) {
    if (!gt_on()) { backend_texture_destroyed(t); free(t); return; }
    push((GtOp){.op = OP_TEX_DESTROYED, .p = t});
}

void gt_free(void *p) {
    if (!p) return;
    if (!gt_on()) { free(p); return; }
    push((GtOp){.op = OP_FREE, .p = p});
}
