// Android host layer (runtime/platform.h). ARM64 only.
#define _GNU_SOURCE
#include <SDL3/SDL.h>
#include <android/log.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <ftw.h>
#include <pthread.h>
#include <sched.h>
#include <signal.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/ucontext.h>
#include <time.h>
#include <unistd.h>

#include "../platform.h"
#include "../rt.h"

#ifndef MAP_FIXED_NOREPLACE
#define MAP_FIXED_NOREPLACE 0x100000
#endif

bool plat_reserve_guest(uint64_t lo, uint64_t hi) {
    errno = 0;
    // Some vendor Android kernels mishandle MAP_FIXED_NOREPLACE for large app mappings as MAP_FIXED and overwrite
    // ART / Scudo VMAs. A plain hint is safe: mmap returns the requested address when it is free, otherwise another
    // address which we immediately release below.
    void *p = mmap((void *)(uintptr_t)lo, hi - lo, PROT_READ | PROT_WRITE,
                   MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0);
    if (p == MAP_FAILED) {
        __android_log_print(ANDROID_LOG_ERROR, "LASRecomp", "mmap %llx-%llx failed: errno %d (%s)",
                            (unsigned long long)lo, (unsigned long long)hi, errno, strerror(errno));
        return false;
    }
    if (p != (void *)(uintptr_t)lo) {
        __android_log_print(ANDROID_LOG_ERROR, "LASRecomp", "mmap %llx-%llx returned %p",
                            (unsigned long long)lo, (unsigned long long)hi, p);
        munmap(p, hi - lo);
        return false;
    }
    return true;
}

static void wt_forget(uint64_t lo, uint64_t hi);
bool plat_reset_guest(uint64_t lo, uint64_t hi) {
    bool ok = mmap((void *)(uintptr_t)lo, hi - lo, PROT_READ | PROT_WRITE,
                   MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE | MAP_FIXED, -1, 0) == (void *)(uintptr_t)lo;
    wt_forget(lo, hi);
    return ok;
}

// Track guest-heap writes by protecting clean pages. Vertex/index buffers can
// then stay cached on the GPU and only changed 4 KiB pages are uploaded.
enum { WT_UNTRACKED = 0, WT_CLEAN = 1, WT_WRITTEN = 2 };
static _Atomic uint8_t *wt_state;
static _Atomic int wt_on = -1;
#define WT_PAGE 4096ull

static void wt_setup(void) {
    const char *e = getenv("LARECOMP_WRITE_TRACKING");
    bool on = (!e || atoi(e)) && sysconf(_SC_PAGESIZE) == (long)WT_PAGE;
    if (on) wt_state = calloc(HEAP_MAX / WT_PAGE, 1);
    atomic_store(&wt_on, on && wt_state ? 1 : 0);
}

static bool wt_init(void) {
    static pthread_once_t once = PTHREAD_ONCE_INIT;
    if (atomic_load(&wt_on) < 0) pthread_once(&once, wt_setup);
    return atomic_load(&wt_on) > 0;
}

static void wt_forget(uint64_t lo, uint64_t hi) {
    if (atomic_load(&wt_on) <= 0 || hi <= HEAP_BASE || lo >= HEAP_BASE + HEAP_MAX) return;
    uint64_t a = lo > HEAP_BASE ? (lo - HEAP_BASE) / WT_PAGE : 0;
    uint64_t b = (hi - HEAP_BASE + WT_PAGE - 1) / WT_PAGE;
    if (b > HEAP_MAX / WT_PAGE) b = HEAP_MAX / WT_PAGE;
    for (uint64_t p = a; p < b; p++) atomic_store_explicit(&wt_state[p], WT_UNTRACKED, memory_order_relaxed);
}

static bool wt_range(uint64_t addr, uint64_t size, uint64_t *p0, uint64_t *p1) {
    if (!size || addr < HEAP_BASE || addr - HEAP_BASE >= HEAP_MAX) return false;
    uint64_t end = addr + size - HEAP_BASE;
    if (end > HEAP_MAX) end = HEAP_MAX;
    *p0 = (addr - HEAP_BASE) / WT_PAGE;
    *p1 = (end + WT_PAGE - 1) / WT_PAGE;
    return true;
}

int plat_written_pages(uint64_t addr, uint64_t size, uint64_t *pages, int max, uint64_t *page) {
    *page = WT_PAGE;
    uint64_t p0, p1;
    if (!wt_init() || !wt_range(addr, size, &p0, &p1)) return -1;
    int n = 0;
    uint64_t run = p1;
    for (uint64_t p = p0; p <= p1; p++) {
        if (p < p1 && atomic_load_explicit(&wt_state[p], memory_order_relaxed) != WT_CLEAN &&
            atomic_exchange(&wt_state[p], WT_CLEAN) != WT_CLEAN) {
            if (n < max) pages[n] = HEAP_BASE + p * WT_PAGE;
            n++;
            if (run == p1) run = p;
            continue;
        }
        if (run != p1) {
            mprotect((void *)(uintptr_t)(HEAP_BASE + run * WT_PAGE), (p - run) * WT_PAGE, PROT_READ);
            run = p1;
        }
    }
    return n > max ? max : n;
}

static bool wt_fault(uint64_t fa) {
    if (atomic_load(&wt_on) <= 0 || fa < HEAP_BASE || fa - HEAP_BASE >= HEAP_MAX) return false;
    uint64_t p = (fa - HEAP_BASE) / WT_PAGE;
    if (mprotect((void *)(uintptr_t)(HEAP_BASE + p * WT_PAGE), WT_PAGE, PROT_READ | PROT_WRITE) != 0) return false;
    atomic_store(&wt_state[p], WT_WRITTEN);
    return true;
}

void plat_commit(uint64_t addr, uint64_t size) {
    uint64_t p0, p1;
    if (atomic_load(&wt_on) <= 0 || !wt_range(addr, size, &p0, &p1)) return;
    mprotect((void *)(uintptr_t)(HEAP_BASE + p0 * WT_PAGE), (p1 - p0) * WT_PAGE, PROT_READ | PROT_WRITE);
    for (uint64_t p = p0; p < p1; p++) atomic_store(&wt_state[p], WT_WRITTEN);
}

int plat_protect(uint64_t addr, uint64_t size, int prot) {
    int native = prot == PLAT_PROT_NONE ? PROT_NONE : prot == PLAT_PROT_READ ? PROT_READ : PROT_READ | PROT_WRITE;
    return mprotect((void *)(uintptr_t)addr, size, native);
}

uint64_t plat_now_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
}

void plat_sleep_until_ns(uint64_t target) {
    struct timespec ts = {.tv_sec = (time_t)(target / 1000000000ull), .tv_nsec = (long)(target % 1000000000ull)};
    while (clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &ts, NULL) == EINTR) {}
}

void plat_thread_realtime(uint64_t period_ns) {
    (void)period_ns;
    setpriority(PRIO_PROCESS, 0, -10);
}

void plat_init(void) {
    __android_log_print(ANDROID_LOG_INFO, "LASRecomp", "plat_init begin");
    // Turn Android's Back key into SDL_SCANCODE_AC_BACK instead of letting SDL finish the Activity.
    SDL_SetHint(SDL_HINT_ANDROID_TRAP_BACK_BUTTON, "1");
    const char *root = getenv("LARECOMP_DATA_ROOT");
    __android_log_print(ANDROID_LOG_INFO, "LASRecomp", "data root env=%s", root ? root : "(null)");
    if (!root || !*root) root = "/sdcard/LASRecomp";
    mkdir(root, 0755);
    char log[1200];
    snprintf(log, sizeof log, "%s/lasrecomp.log", root);
    FILE *stream = freopen(log, "w", stderr);
    if (stream) dup2(STDERR_FILENO, STDOUT_FILENO);
}

bool plat_exe_path(char *buf, size_t size) {
    Dl_info info = {0};
    if (!dladdr((void *)plat_exe_path, &info) || !info.dli_fname) return false;
    return (size_t)snprintf(buf, size, "%s", info.dli_fname) < size;
}

void plat_exec(char *const argv[]) { (void)argv; }

PlatProc plat_spawn(const char *const argv[], const char *log_path, bool append_log) {
    (void)argv; (void)log_path; (void)append_log;
    return 0;
}
int plat_proc_wait(PlatProc proc, bool block) { (void)proc; (void)block; return 255; }
void plat_proc_kill(PlatProc proc) { (void)proc; }

static int remove_entry(const char *path, const struct stat *statbuf, int type, struct FTW *state) {
    (void)statbuf; (void)type; (void)state;
    return remove(path);
}
bool plat_remove_tree(const char *dir) { return nftw(dir, remove_entry, 16, FTW_DEPTH | FTW_PHYS) == 0; }

const char *plat_symbol(uint64_t pc, uint64_t *offset) {
    Dl_info info = {0};
    if (!dladdr((void *)(uintptr_t)pc, &info) || !info.dli_sname) return NULL;
    if (offset) *offset = pc - (uint64_t)(uintptr_t)info.dli_saddr;
    return info.dli_sname;
}

void plat_print_backtrace(void) { fprintf(stderr, "  Android native backtrace: see logcat tombstone\n"); }
void plat_fatal_notice(void) { fflush(stderr); }

static void crash_handler(int signal_number, siginfo_t *info, void *context) {
    ucontext_t *uc = context;
    static volatile int depth;
    if (signal_number == SIGABRT && depth++ > 0) {
        signal(SIGABRT, SIG_DFL);
        abort();
    }
    uint64_t fault = (uint64_t)(uintptr_t)info->si_addr;
#if defined(__aarch64__)
    uint64_t pc = uc->uc_mcontext.pc, lr = uc->uc_mcontext.regs[30];
#else
    uint64_t pc = 0, lr = 0;
#endif
    if (signal_number == SIGSEGV && info->si_code == SEGV_ACCERR && wt_fault(fault)) return;
    if (rt_fault_watch(fault, pc)) return;
    char what[32];
    snprintf(what, sizeof what, "signal %d", signal_number);
    rt_fault_report(what, fault, pc, lr);
}

void plat_crash_handler_install(void) {
    stack_t stack = {.ss_sp = malloc(1 << 20), .ss_size = 1 << 20};
    sigaltstack(&stack, NULL);
    struct sigaction action = {0};
    action.sa_sigaction = crash_handler;
    action.sa_flags = SA_SIGINFO | SA_ONSTACK;
    sigaction(SIGSEGV, &action, NULL);
    sigaction(SIGBUS, &action, NULL);
    sigaction(SIGILL, &action, NULL);
    sigaction(SIGFPE, &action, NULL);
    sigaction(SIGABRT, &action, NULL);
}

void plat_terminate(void) { _exit(0); }

void plat_thread_name(const char *name) { pthread_setname_np(pthread_self(), name); }

// Phones have one or two fastest cores. Keep the single-threaded game on one of them and render work on the remaining
// prime core(s), or on the next frequency tier on older SoCs. The previous single-prime-only rule disabled affinity
// entirely on Snapdragon 8 Elite, so a touch boost could make 60 fps while the same static scene downclocked to 30.
// LARECOMP_AFFINITY=0: leave placement to Android.
static cpu_set_t g_core_sets[3];
static bool g_core_on;

static void core_scan(void) {
    long freq[CPU_SETSIZE] = {0}, best = 0, second = 0;
    int n = 0, top = -1, ntop = 0, nsecond = 0;
    for (; n < CPU_SETSIZE; n++) {
        char path[96];
        snprintf(path, sizeof path, "/sys/devices/system/cpu/cpu%d/cpufreq/cpuinfo_max_freq", n);
        FILE *f = fopen(path, "r");
        if (!f) break;
        if (fscanf(f, "%ld", &freq[n]) != 1) freq[n] = 0;
        fclose(f);
        if (freq[n] > best) best = freq[n], top = n;
    }
    for (int i = 0; i < n; i++) if (freq[i] < best && freq[i] > second) second = freq[i];
    for (int i = 0; i < n; i++) ntop += freq[i] == best, nsecond += freq[i] == second;
    const char *e = getenv("LARECOMP_AFFINITY");
    if ((e && !atoi(e)) || ntop < 1 || (ntop == 1 && !nsecond)) return;
    for (int r = 0; r < 3; r++) CPU_ZERO(&g_core_sets[r]);
    int nrender = 0;
    long render_freq = ntop > 1 ? best : second;
    for (int i = 0; i < n; i++) {
        if (i == top) CPU_SET(i, &g_core_sets[PLAT_CORE_MAIN]);
        if (i != top && freq[i] == render_freq) {
            CPU_SET(i, &g_core_sets[PLAT_CORE_RENDER]);
            nrender++;
        }
        if (i != top) CPU_SET(i, &g_core_sets[PLAT_CORE_OTHER]);
    }
    g_core_on = true;
    fprintf(stderr, "[cpu] game thread on cpu%d (%ld MHz), render thread on the %d cores at %ld MHz\n", top, best / 1000,
            nrender, render_freq / 1000);
}

// Performance hints (APerformanceHint, Android 13+, looked up at run time: the app starts on Android 11): one session
// for the game's main thread and the render thread, told each frame how long the game thread worked against the
// frame's target. That is what gets a phone's fastest core out of isolation and the clocks up (core_ctl parks the
// prime core while nothing it counts as heavy runs; a 70% thread on a big core isn't).
static pid_t g_hint_tids[2];
static void *g_hint_session;
static void *(*p_get_manager)(void);
static void *(*p_create_session)(void *, const int32_t *, size_t, int64_t);
static int (*p_update_target)(void *, int64_t);
static int (*p_report)(void *, int64_t);
static int (*p_set_threads)(void *, const pid_t *, size_t);

static void hint_load(void) {
    void *lib = dlopen("libandroid.so", RTLD_NOW);
    if (!lib) return;
    p_get_manager = (void *(*)(void))dlsym(lib, "APerformanceHint_getManager");
    p_create_session = (void *(*)(void *, const int32_t *, size_t, int64_t))dlsym(lib, "APerformanceHint_createSession");
    p_update_target = (int (*)(void *, int64_t))dlsym(lib, "APerformanceHint_updateTargetWorkDuration");
    p_report = (int (*)(void *, int64_t))dlsym(lib, "APerformanceHint_reportActualWorkDuration");
    p_set_threads = (int (*)(void *, const pid_t *, size_t))dlsym(lib, "APerformanceHint_setThreads");
}

void plat_thread_core(int role) {
    static pthread_once_t once = PTHREAD_ONCE_INIT;
    pthread_once(&once, core_scan);
    if (role == PLAT_CORE_MAIN || role == PLAT_CORE_RENDER) {  // (the hint session's threads)
        pid_t tid = gettid(), *slot = &g_hint_tids[role == PLAT_CORE_RENDER];
        if (*slot != tid) {
            *slot = tid;
            if (g_hint_session && p_set_threads) {
                pid_t t[2];
                size_t n = 0;
                for (int i = 0; i < 2; i++) if (g_hint_tids[i]) t[n++] = g_hint_tids[i];
                p_set_threads(g_hint_session, t, n);
            }
        }
    }
    if (!g_core_on || role < 0 || role > 2) return;
    // the fastest core alone; while it's parked (isolated: EINVAL) the big ones
    if (sched_setaffinity(0, sizeof g_core_sets[role], &g_core_sets[role]) == 0) return;
    cpu_set_t big = g_core_sets[PLAT_CORE_RENDER];
    CPU_OR(&big, &big, &g_core_sets[PLAT_CORE_MAIN]);
    if (role != PLAT_CORE_MAIN || sched_setaffinity(0, sizeof big, &big) != 0)
        fprintf(stderr, "[cpu] affinity: %s\n", strerror(errno));
}

void plat_frame_work(uint64_t busy_ns, uint64_t target_ns) {
    static pthread_once_t once = PTHREAD_ONCE_INIT;
    static int64_t target;
    static bool failed;
    const char *e = getenv("LARECOMP_PERF_HINT");
    if (failed || (e && !atoi(e))) return;
    // Leave governor headroom so a frame approaching 16.7 ms raises clocks
    // before it misses vsync. The same 20% margin is used by the validated
    // Snapdragon 8 Elite Android port.
    static int margin = -1;
    if (margin < 0) {
        const char *m = getenv("LARECOMP_ADPF_MARGIN");
        margin = m ? atoi(m) : 20;
    }
    if (margin > 0 && margin < 100) target_ns = target_ns * (uint64_t)(100 - margin) / 100;
    pthread_once(&once, hint_load);
    if (!g_hint_session) {
        if (!p_get_manager || !p_create_session || !p_report || !g_hint_tids[0]) { failed = true; return; }
        void *m = p_get_manager();
        int32_t t[2];
        size_t n = 0;
        for (int i = 0; i < 2; i++) if (g_hint_tids[i]) t[n++] = g_hint_tids[i];
        g_hint_session = m ? p_create_session(m, t, n, (int64_t)target_ns) : NULL;
        if (!g_hint_session) {
            failed = true;
            fprintf(stderr, "[cpu] no performance hint session\n");
            return;
        }
        target = (int64_t)target_ns;
        fprintf(stderr, "[cpu] performance hint session: %zu threads, target %.1f ms\n", n, target_ns / 1e6);
    }
    if ((int64_t)target_ns != target && p_update_target) p_update_target(g_hint_session, target = (int64_t)target_ns);
    if (busy_ns) p_report(g_hint_session, (int64_t)busy_ns);
}
