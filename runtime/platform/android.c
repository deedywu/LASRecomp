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

#ifndef MAP_FIXED_NOREPLACE
#define MAP_FIXED_NOREPLACE 0x100000
#endif

bool plat_reserve_guest(uint64_t lo, uint64_t hi) {
    void *p = mmap((void *)(uintptr_t)lo, hi - lo, PROT_READ | PROT_WRITE,
                   MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE | MAP_FIXED_NOREPLACE, -1, 0);
    if (p == MAP_FAILED) return false;
    if (p != (void *)(uintptr_t)lo) { munmap(p, hi - lo); return false; }
    return true;
}

bool plat_reset_guest(uint64_t lo, uint64_t hi) {
    return mmap((void *)(uintptr_t)lo, hi - lo, PROT_READ | PROT_WRITE,
                MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE | MAP_FIXED, -1, 0) == (void *)(uintptr_t)lo;
}

void plat_commit(uint64_t addr, uint64_t size) { (void)addr; (void)size; }

int plat_written_pages(uint64_t addr, uint64_t size, uint64_t *pages, int max, uint64_t *page) {
    (void)addr; (void)size; (void)pages; (void)max; (void)page;
    return -1;
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
    if (depth++) _exit(128 + signal_number);
    uint64_t fault = (uint64_t)(uintptr_t)info->si_addr;
#if defined(__aarch64__)
    uint64_t pc = uc->uc_mcontext.pc, lr = uc->uc_mcontext.regs[30];
#else
    uint64_t pc = 0, lr = 0;
#endif
    if (rt_fault_watch(fault, pc)) { depth = 0; return; }
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
