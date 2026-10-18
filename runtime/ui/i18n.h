#pragma once

#include "imgui.h"

// ImGui strings use the English source text as their stable key. Missing translations deliberately fall back to it.
const char *ui_tr(const char *english);
bool ui_language_is_cjk(void);
bool ui_language_uses_localized_font(void);
const char *ui_localized_font_path(void);
const char *ui_korean_font_path(void);
void ui_add_translation_glyphs(ImFontGlyphRangesBuilder &builder);
void ui_add_korean_glyphs(ImFontGlyphRangesBuilder &builder);
