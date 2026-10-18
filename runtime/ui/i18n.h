#pragma once

#include "imgui.h"

// ImGui strings use the English source text as their stable key. Missing translations deliberately fall back to it.
const char *ui_tr(const char *english);
bool ui_language_is_cjk(void);
const char *ui_cjk_font_path(void);
void ui_add_translation_glyphs(ImFontGlyphRangesBuilder &builder);
