// Software keyboard (naming Link on a new file, ...). On the Switch nn::swkbd::ShowKeyboard launches the keyboard
// library applet; our am service has no applets, so the game crashed. ShowKeyboard is replaced here: the overlay
// (runtime/ui/menu.mm menu_keyboard_run) asks for the text - typed directly with a keyboard, an on-screen keyboard
// with a controller - while this (game) thread keeps re-presenting the last frame.
#include <stdio.h>
#include <string.h>

#include "../hle.h"

int menu_keyboard_run(const char *initial, int max_len, char *out, int cap);  // runtime/ui/menu.mm

static void append_utf8(char *out, size_t cap, size_t *at, uint32_t c) {
    int n = c < 0x80 ? 1 : c < 0x800 ? 2 : c < 0x10000 ? 3 : 4;
    if (*at + (size_t)n >= cap) return;
    if (n == 1) out[(*at)++] = (char)c;
    else if (n == 2) {
        out[(*at)++] = (char)(0xC0 | (c >> 6));
        out[(*at)++] = (char)(0x80 | (c & 0x3F));
    } else if (n == 3) {
        out[(*at)++] = (char)(0xE0 | (c >> 12));
        out[(*at)++] = (char)(0x80 | ((c >> 6) & 0x3F));
        out[(*at)++] = (char)(0x80 | (c & 0x3F));
    } else {
        out[(*at)++] = (char)(0xF0 | (c >> 18));
        out[(*at)++] = (char)(0x80 | ((c >> 12) & 0x3F));
        out[(*at)++] = (char)(0x80 | ((c >> 6) & 0x3F));
        out[(*at)++] = (char)(0x80 | (c & 0x3F));
    }
    out[*at] = 0;
}

// nn::swkbd::ShowKeyboard(nn::swkbd::String *out, const nn::swkbd::ShowKeyboardArg &arg) -> nn::Result
// String = {void *ptr; size_t bufSize}
// ShowKeyboardArg (probed 2026-10-08, naming Link): +0x3ac text max length, +0x3b0 min length, +0x3c0 / +0x3c4
// initial text offset / length (UTF-16) in the work buffer at +0x4d0. The game reads the answer as UTF-8.
HLE_FUNC("_ZN2nn5swkbd12ShowKeyboardEPNS0_6StringERKNS0_15ShowKeyboardArgE", swkbd_show) {
    uint64_t out = c->x[0], arg = c->x[1];
    uint64_t ptr = LD64(out), size = LD64(out + 8);
    int max_len = (int)*(const int32_t *)(uintptr_t)(arg + 0x3ac);
    uint32_t off = *(const uint32_t *)(uintptr_t)(arg + 0x3c0), n = *(const uint32_t *)(uintptr_t)(arg + 0x3c4);
    uint64_t wb = LD64(arg + 0x4d0);
    char initial[96] = "";
    size_t initial_at = 0;
    for (uint32_t i = 0; wb && i < n; i++) {
        uint32_t ch = *(const uint16_t *)(uintptr_t)(wb + off + 2 * i);
        if (ch >= 0xD800 && ch <= 0xDBFF && i + 1 < n) {
            uint32_t lo = *(const uint16_t *)(uintptr_t)(wb + off + 2 * (i + 1));
            if (lo >= 0xDC00 && lo <= 0xDFFF) ch = 0x10000 + ((ch - 0xD800) << 10) + (lo - 0xDC00), i++;
        }
        append_utf8(initial, sizeof initial, &initial_at, ch);
    }
    char text[96];
    int ok = menu_keyboard_run(initial, max_len, text, sizeof text);
    if (!ok) snprintf(text, sizeof text, "%s", initial);  // cancelled: keep what was there
    LOG("[swkbd] name entry (max %d, initial \"%s\"): %s \"%s\"\n", max_len, initial, ok ? "entered" : "cancelled", text);
    if (ptr && size) {
        memset((void *)(uintptr_t)ptr, 0, size);
        snprintf((char *)(uintptr_t)ptr, size, "%s", text);
    }
    c->x[0] = 0;
}
