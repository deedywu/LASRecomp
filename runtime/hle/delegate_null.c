// Guard the two recycled-action delegate forwarders used by the game's task loop.
// A frame job can briefly have a null delegate while it is rebuilt in place. Dereferencing it
// crashes at main+0x10cce58; simply dropping the call can lose the release that queues the job
// and hang the main thread. Wait for a live job's delegate and owner lock, then forward it.
#include <stdint.h>
#include <pthread.h>

#include "../hle.h"
#include "../platform.h"

#define JOB_VTABLE_LIVE (GUEST_LO + 0x1c51308ull)

static uint64_t rd64(uint64_t a) { return __atomic_load_n((uint64_t *)(uintptr_t)a, __ATOMIC_ACQUIRE); }
static uint32_t rd32(uint64_t a) { return __atomic_load_n((uint32_t *)(uintptr_t)a, __ATOMIC_ACQUIRE); }

// The scheduler runs a job and then destroys its wrapper.  The next frame can rebuild that same
// wrapper after Run releases the owner lock but before the scheduler reaches the destructor.  In
// that ordering the old destructor must not clear the newly installed vtable and delegate.
typedef struct { uint64_t obj, generation; } JobGeneration;
static pthread_mutex_t job_generation_lock = PTHREAD_MUTEX_INITIALIZER;
static JobGeneration job_generations[16];
static _Thread_local uint64_t running_job;
static _Thread_local uint64_t running_generation;

static JobGeneration *job_generation(uint64_t obj, bool create) {
    JobGeneration *free_slot = NULL;
    for (unsigned i = 0; i < sizeof job_generations / sizeof job_generations[0]; i++) {
        if (job_generations[i].obj == obj) return &job_generations[i];
        if (!job_generations[i].obj && !free_slot) free_slot = &job_generations[i];
    }
    if (!create) return NULL;
    JobGeneration *p = free_slot ? free_slot :
        &job_generations[(obj >> 4) % (sizeof job_generations / sizeof job_generations[0])];
    *p = (JobGeneration){.obj = obj};
    return p;
}

void rt_delegate_job_built(uint64_t obj) {
    pthread_mutex_lock(&job_generation_lock);
    JobGeneration *p = job_generation(obj, true);
    p->generation++;
    pthread_mutex_unlock(&job_generation_lock);
}

void rt_delegate_job_run(uint64_t obj) {
    pthread_mutex_lock(&job_generation_lock);
    JobGeneration *p = job_generation(obj, false);
    running_job = obj;
    running_generation = p ? p->generation : 0;
    pthread_mutex_unlock(&job_generation_lock);
}

int rt_delegate_job_teardown(uint64_t obj) {
    pthread_mutex_lock(&job_generation_lock);
    JobGeneration *p = job_generation(obj, false);
    uint64_t current = p ? p->generation : 0;
    uint64_t ran = running_job == obj ? running_generation : 0;
    bool stale = ran && current != ran;
    if (running_job == obj) running_job = running_generation = 0;
    pthread_mutex_unlock(&job_generation_lock);

    static int logged;
    if (stale && logged++ < 16)
        LOG("[delegate] %#llx: skipped stale teardown (ran generation %llu, current %llu)\n",
            (unsigned long long)obj, (unsigned long long)ran,
            (unsigned long long)current);
    return stale;
}

int rt_delegate_null(Cpu *c, int slot) {
    uint64_t obj = c->x[0];
    if (obj && rd64(obj + 0x10)) return 0;
    if (!obj) return 1;

    uint64_t vt = rd64(obj);
    uint64_t owner = rd64(obj + 0x28);
    bool in_owner = owner && owner + 0xc8 == obj;
    uint64_t t0 = plat_now_ns(), waited = 0;
    bool forwarded = false;

    if (vt == JOB_VTABLE_LIVE && in_owner) {
        while ((waited = plat_now_ns() - t0) < 1000000000ull) {
            if (rd64(obj + 0x10) && !rd32(owner + 0x1f8)) {
                forwarded = true;
                break;
            }
            if (rd64(obj) != JOB_VTABLE_LIVE) break;
            plat_sleep_until_ns(plat_now_ns() + 50000);
        }
    }

    static int logged;
    if (logged++ < 16)
        LOG("[delegate] %#llx slot +0x%x: no delegate at [this+0x10] (vtable %#llx, count %#x, lr %#llx, owner %#llx done %d "
            "lock %#x) - %s after %llu us (issue #19)\n",
            (unsigned long long)obj, slot, (unsigned long long)vt, rd32(obj + 0x20),
            (unsigned long long)c->x[30], (unsigned long long)owner,
            in_owner ? *(uint8_t *)(uintptr_t)(owner + 0x1d8) : -1,
            in_owner ? rd32(owner + 0x1f8) : 0, forwarded ? "forwarded" : "skipped",
            (unsigned long long)(waited / 1000));
    if (forwarded) return 0;
    c->x[0] = 0;
    return 1;
}
