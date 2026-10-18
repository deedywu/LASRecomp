// nn::pl shared system fonts. The Switch's system fonts are not part of the game, so every SharedFontType the game
// asks for is filled from, in order of preference:
//  1. LARECOMP_FONT=<file> (.ttf / .otf / .ttc face 0 / .bfttf)
//  2. a dump from the user's own console in fonts/, under the console's own names (plain .ttf versions work too):
//     nintendo_udsg-r_std_003 (Standard, Morisawa UD Shin Go), nintendo_udsg-r_org_zh-cn_003 (Chinese Simplified),
//     nintendo_udsg-r_ext_zh-cn_003 (its Ext), nintendo_udjxh-db_zh-tw_003 (Chinese Traditional),
//     nintendo_udsg-r_ko_003 (Korean), nintendo_ext_003 (NintendoExt button glyphs)
//  3. a substitute of that same language where the OS has one - a gothic like UD Shin Go is much closer to the
//     game's look than Arial. Without one (a Linux without a CJK font, say) the type serves Standard, which is
//     what a game asking for a language whose font is missing gets on the console too - but then that language's
//     characters are the substitute's, so Chinese / Korean text can show missing glyphs.
// .bfttf is the console's obfuscated TTF: 8-byte header (magic, size) then every u32 XORed with a fixed key.
// .ttc collections get face 0 copied out as a standalone font (the game's font engine wants one sfnt).
#include <stdlib.h>
#include <string.h>
#include <strings.h>

#include "../hle.h"

typedef struct { uint64_t addr, size; } Font;
// SharedFontType: 0 Standard, 1 ChineseSimple, 2 ChineseSimpleExt, 3 ChineseTraditional, 4 Korean, 5 NintendoExt
enum { F_STD, F_ZH_CN, F_ZH_CN_EXT, F_ZH_TW, F_KO, F_EXT, N_FONT_TYPES };
static Font fonts[N_FONT_TYPES];

static uint32_t be32(const uint8_t *p) { return (uint32_t)p[0] << 24 | p[1] << 16 | p[2] << 8 | p[3]; }
static void put32(uint8_t *p, uint32_t v) { p[0] = v >> 24; p[1] = v >> 16; p[2] = v >> 8; p[3] = v; }

static uint8_t *read_file(const char *path, size_t *len) {
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    *len = (size_t)ftell(f);
    fseek(f, 0, SEEK_SET);
    uint8_t *p = malloc(*len + 4);
    if (fread(p, 1, *len, f) != *len) { free(p); p = NULL; }
    fclose(f);
    return p;
}

// .bfttf -> TTF in place (returns the new length, 0 if it isn't one)
static size_t bfttf_decode(uint8_t *d, size_t len) {
    static const uint32_t KEY = 0x49621806;
    if (len < 12) return 0;
    for (int swap = 0; swap < 2; swap++) {  // the key's byte order differs between descriptions; accept both
        uint32_t k = swap ? __builtin_bswap32(KEY) : KEY;
        uint32_t w0, w1, w2;
        memcpy(&w0, d, 4); memcpy(&w1, d + 4, 4); memcpy(&w2, d + 8, 4);
        uint32_t size = w1 ^ k, ver = w2 ^ k;
        if (size == 0 || size > len - 8 || (ver != 0x00000100u && ver != 0x4F54544Fu)) continue;  // sfnt 1.0 / OTTO
        (void)w0;
        for (size_t i = 0; i + 4 <= size; i += 4) {
            uint32_t w;
            memcpy(&w, d + 8 + i, 4);
            w ^= k;
            memcpy(d + i, &w, 4);
        }
        return size;
    }
    return 0;
}

// .ttc -> face 0 as its own sfnt (table data copied, offsets rewritten)
static uint8_t *ttc_face0(const uint8_t *f, size_t len, size_t *out_len) {
    if (len < 16 || memcmp(f, "ttcf", 4)) return NULL;
    uint32_t o = be32(f + 12);
    if (o + 12 > len) return NULL;
    uint32_t nt = (uint32_t)f[o + 4] << 8 | f[o + 5];
    size_t total = 12 + 16 * nt;
    for (uint32_t i = 0; i < nt; i++) total += (be32(f + o + 12 + 16 * i + 12) + 3) & ~3u;
    uint8_t *out = calloc(1, total);
    memcpy(out, f + o, 12);
    size_t pos = 12 + 16 * nt;
    for (uint32_t i = 0; i < nt; i++) {
        const uint8_t *e = f + o + 12 + 16 * i;
        uint32_t off = be32(e + 8), n = be32(e + 12);
        if ((size_t)off + n > len) { free(out); return NULL; }
        memcpy(out + 12 + 16 * i, e, 8);  // tag, checksum
        put32(out + 12 + 16 * i + 8, (uint32_t)pos);
        put32(out + 12 + 16 * i + 12, n);
        memcpy(out + pos, f + off, n);
        pos += (n + 3) & ~3u;
    }
    *out_len = total;
    return out;
}

static int load_one(const char *path, Font *ft) {
    size_t len;
    uint8_t *d = read_file(path, &len);
    if (!d) return 0;
    size_t n = strlen(path);
    if (n > 6 && !strcasecmp(path + n - 6, ".bfttf")) {
        len = bfttf_decode(d, len);
        if (!len) { LOG("[pl] %s: not a valid .bfttf\n", path); free(d); return 0; }
    } else if (len >= 4 && !memcmp(d, "ttcf", 4)) {
        size_t l2;
        uint8_t *f0 = ttc_face0(d, len, &l2);
        free(d);
        if (!f0) { LOG("[pl] %s: bad font collection\n", path); return 0; }
        d = f0;
        len = l2;
    }
    void *p = hle_alloc(len + 16);
    memcpy(p, d, len);
    free(d);
    ft->addr = (uint64_t)p;
    ft->size = len;
    LOG("[pl] system font %s (%zu bytes)\n", path, len);
    return 1;
}

static int g_fonts_loaded;
RT_ON_RESET(pl_reset) { g_fonts_loaded = 0; memset(fonts, 0, sizeof fonts); }  // (they were in the HLE heap)

static void load_fonts(void) {
    if (g_fonts_loaded) return;
    g_fonts_loaded = 1;
    const char *env = getenv("LARECOMP_FONT");
    // Per type: prefer the console's own file(s), then a substitute of that same
    // language.  Do not use the CJK fallback as the standard face when a native
    // Latin face is available: trimmed CJK fonts commonly omit symbols such as ©.
    static const char *const std[] = {"fonts/nintendo_udsg-r_std_003.bfttf", "fonts/nintendo_udsg-r_std_003.ttf",
                                     "fonts/nintendo_udsgr_std_003.ttf", "fonts/nintendo_udsgr_std_003.bfttf",
                                     "/System/Library/Fonts/ヒラギノ角ゴシック W4.ttc", "C:/Windows/Fonts/YuGothR.ttc",
                                     "C:/Windows/Fonts/YuGothM.ttc",
                                     "/System/Library/Fonts/Supplemental/Arial.ttf", "C:/Windows/Fonts/arial.ttf",
                                     "/system/fonts/Roboto-Regular.ttf", "/system/fonts/NotoSans-Regular.ttf",
                                     "fonts/android-cjk.ttf", "fonts/android-cjk.ttc",
                                     "/system/fonts/DroidSansFallbackBBK.ttf", "/system/fonts/DroidSansFallback.ttf",
                                     "/system/fonts/NotoSansCJK-Regular.ttc",
                                     // Linux: DejaVu Sans (Debian / Ubuntu, Arch, Fedora). Not Noto Sans CJK: CFF
                                     // outlines, which the game's font engine crashes on (it wants TrueType)
                                     "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                                     "/usr/share/fonts/TTF/DejaVuSans.ttf",
                                     "/usr/share/dejavu-sans-fonts/DejaVuSans.ttf", NULL};
    static const char *const zh_cn[] = {"fonts/nintendo_udsg-r_org_zh-cn_003.bfttf",
                                        "fonts/nintendo_udsg-r_org_zh-cn_003.ttf",
                                        "fonts/android-cjk.ttf", "fonts/android-cjk.ttc",
                                        "/System/Library/Fonts/Hiragino Sans GB.ttc",
                                        "/System/Library/Fonts/Supplemental/Hiragino Sans GB.ttc",
                                        "C:/Windows/Fonts/msyh.ttc", "C:/Windows/Fonts/simhei.ttf",
                                        "/system/fonts/DroidSansFallbackBBK.ttf", "/system/fonts/DroidSansFallback.ttf",
                                        "/system/fonts/NotoSansCJK-Regular.ttc",
                                        "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc",
                                        "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc", NULL};
    static const char *const zh_cn_ext[] = {"fonts/nintendo_udsg-r_ext_zh-cn_003.bfttf",
                                            "fonts/nintendo_udsg-r_ext_zh-cn_003.ttf", NULL};
    static const char *const zh_tw[] = {"fonts/nintendo_udjxh-db_zh-tw_003.bfttf",
                                        "fonts/nintendo_udjxh-db_zh-tw_003.ttf", "C:/Windows/Fonts/msjh.ttc",
                                        // (PingFang carries both, but a collection copies only face 0 out: Simplified)
                                        "/System/Library/Fonts/PingFang.ttc",
                                        "/System/Library/Fonts/Supplemental/Songti.ttc",
                                        "/usr/share/fonts/truetype/arphic/uming.ttc", NULL};
    static const char *const ko[] = {"fonts/nintendo_udsg-r_ko_003.bfttf", "fonts/nintendo_udsg-r_ko_003.ttf",
                                     "/System/Library/Fonts/AppleSDGothicNeo.ttc", "C:/Windows/Fonts/malgun.ttf",
                                     "/usr/share/fonts/truetype/nanum/NanumGothic.ttf",
                                     "/usr/share/fonts/nanum/NanumGothic.ttf", NULL};
    static const char *const ext[] = {"fonts/nintendo_ext_003.bfttf", "fonts/nintendo_ext_003.ttf", NULL};
    static const char *const *const chains[N_FONT_TYPES] = {std, zh_cn, zh_cn_ext, zh_tw, ko, ext};
    for (int type = 0; type < N_FONT_TYPES; type++) {
        if (env) load_one(env, &fonts[type]);
        for (size_t i = 0; !fonts[type].addr && chains[type][i]; i++) load_one(chains[type][i], &fonts[type]);
    }
    if (!fonts[F_STD].addr) FATAL("no usable system font substitute\n");
}

// SharedFontType: 0 Standard, 1 ChineseSimple, 2 ChineseSimpleExt, 3 ChineseTraditional, 4 Korean, 5 NintendoExt
static const Font *font_for(uint64_t type) {
    load_fonts();
    if (type >= N_FONT_TYPES || !fonts[type].addr) return &fonts[F_STD];
    return &fonts[type];
}

HLE_FUNC("_ZN2nn2pl22GetSharedFontLoadStateENS0_14SharedFontTypeE", pl_get_load_state) { c->x[0] = 1; }
HLE_FUNC("_ZN2nn2pl20GetSharedFontAddressENS0_14SharedFontTypeE", pl_get_address) { c->x[0] = font_for(c->x[0])->addr; }
HLE_FUNC("_ZN2nn2pl17GetSharedFontSizeENS0_14SharedFontTypeE", pl_get_size) { c->x[0] = font_for(c->x[0])->size; }
