#include "i18n.h"

#include <stdio.h>
#include <string.h>

extern "C" {
#include "../settings.h"
}

struct Translation { const char *en, *zh; };

// Keep source text as the key so call sites remain readable and an untranslated string is never blank.
static const Translation kZh[] = {
    {"Auto", "自动"}, {"Auto (follow game)", "自动（游戏）"}, {"English", "英语"},
    {"Japanese", "日语"}, {"Spanish", "西班牙语"}, {"French", "法语"}, {"German", "德语"},
    {"Italian", "意大利语"}, {"Dutch", "荷兰语"}, {"Russian", "俄语"}, {"Korean", "韩语"},
    {"Chinese (Simplified)", "简体中文"}, {"Chinese (Traditional)", "繁体中文"},
    {"Simplified Chinese", "简体中文"},
    {"Prelaunch", "启动"}, {"Video", "视频"}, {"Audio", "音频"}, {"Save Editor", "存档编辑"},
    {"Randomizer", "随机化"}, {"Warp", "传送"}, {"Cheats", "作弊"}, {"Gameplay", "游戏玩法"},
    {"Cosmetics", "外观"}, {"Controls", "控制"}, {"Quit", "退出"}, {"Settings", "设置"},
    {"Off", "关闭"}, {"On", "开启"}, {"Default", "默认"}, {"Cancel", "取消"}, {"OK", "确定"},
    {"Display", "显示"}, {"Aspect ratio", "画面比例"}, {"Unlocked", "自由比例"},
    {"Original 16:9", "原始 16:9"}, {"Fullscreen", "全屏"}, {"Show FPS", "显示帧率"},
    {"Rendering", "渲染"}, {"Internal resolution", "内部分辨率"}, {"Match display", "匹配屏幕"},
    {"Dynamic", "动态"}, {"Upscaler", "放大算法"}, {"Bilinear", "双线性"},
    {"Anti-aliasing", "抗锯齿"}, {"Game", "游戏"}, {"Remove blur", "移除模糊"},
    {"Hide Hero Mode icon", "隐藏英雄模式图标"}, {"Colors", "颜色"}, {"Tunic color", "服装颜色"},
    {"Heart color", "心形颜色"}, {"Random colors", "随机颜色"}, {"Sound", "声音"},
    {"Volume", "音量"}, {"Room reverb", "房间混响"}, {"Movie audio", "影片声音"},
    {"Movement", "移动"}, {"D-pad moves Link", "方向键移动林克"}, {"360-degree movement", "360 度移动"},
    {"Button prompts", "按键提示"}, {"Button icons", "按键图标"}, {"System language", "语言"},
    {"Game language", "游戏语言"}, {"Interface language", "界面语言"}, {"Menu", "菜单"},
    {"Nintendo", "任天堂"}, {"PlayStation", "PlayStation"}, {"Xbox", "Xbox"},
    {"Quit to Start Screen", "返回启动画面"}, {"Quit to Desktop", "退出程序"},
    {"Yes, quit to Start Screen", "是，返回启动画面"}, {"Yes, quit to Desktop", "是，退出程序"},
    {"Quick", "快捷操作"}, {"Player", "玩家"}, {"Equipment", "装备"}, {"Ammo", "弹药"},
    {"Ocarina songs", "陶笛曲目"}, {"Bottles", "瓶子"}, {"Dungeon keys", "迷宫钥匙"},
    {"Trading quest", "交换任务"}, {"Companions", "伙伴"}, {"Give any item", "给予任意物品"},
    {"Always on", "持续生效"}, {"One time", "单次操作"}, {"Infinite hearts", "无限生命"},
    {"Infinite ammo", "无限弹药"}, {"Infinite rupees", "无限卢比"}, {"Max hearts", "最大生命"},
    {"Refill hearts", "回满生命"}, {"Companion", "伙伴"}, {"General", "常规"},
    {"Difficulty", "难度"}, {"Mirror mode", "镜像模式"}, {"Damage taken", "受到的伤害"},
    {"One-hit KO", "一击致命"}, {"Seeds", "种子"}, {"New seed", "新种子"}, {"Items", "物品"},
    {"Extra checks", "额外检查点"}, {"World", "世界"}, {"Enemies & bosses", "敌人与首领"},
    {"Other", "其他"}, {"Generate seed", "生成种子"}, {"Seed name", "种子名称"},
    {"Seed ID", "种子 ID"}, {"Copy seed ID", "复制种子 ID"}, {"New seed ID", "新种子 ID"},
    {"Start with Sword", "初始持有剑"}, {"Start with Shield", "初始持有盾"},
    {"No seeds yet", "暂无种子"}, {"Switch to vanilla", "切换到原版"},
    {"Name", "名称"}, {"Heart Containers", "完整心之容器"}, {"Pieces of Heart", "心之碎片"},
    {"Health", "生命"}, {"Rupees", "卢比"}, {"Secret Seashells", "秘密贝壳"},
    {"Golden Leaves", "黄金叶"}, {"Tunics", "服装"}, {"Trade item", "交换物品"},
    {"Item", "物品"}, {"Count", "数量"}, {"Index", "索引"}, {"Give", "给予"},
    {"Reset controller to defaults", "恢复手柄默认设置"},
    {"Reset keyboard to defaults", "恢复键盘默认设置"},
    {"Switch", "Switch"}, {"Controller", "手柄"}, {"Keyboard", "键盘"},
    {"Left stick", "左摇杆"}, {"Right stick", "右摇杆"},
    {"Select a binding, then press the new button or key. Esc (or 5 seconds) cancels. A button that's already in use swaps with the old one.",
     "选择一个绑定，然后按下新按键。按 Esc 或等待 5 秒取消；已被使用的按键会与原绑定交换。"},
    {"Bindings apply to the game only. Menus keep the fixed layout (right face button / Enter select, bottom face button / Esc back), and the in-game menu always opens with F1 or Esc, or the controller's Back + Start held together, or its Home / Guide button - so this page can't be locked out. The game's button icons follow the controller bindings.",
     "绑定仅对游戏生效。菜单始终使用固定按键布局（右侧功能键/Enter 选择，底部功能键/Esc 返回）。游戏内菜单始终可用 F1、Esc、Back + Start 或 Home/Guide 键打开，因此不会因修改绑定而无法进入。游戏按键图标会跟随手柄绑定。"},
    {"Space", "空格"}, {"Delete", "删除"}, {"Close", "关闭"}, {"Play", "开始游戏"},
    {"Play Now", "立即开始"}, {"Spoiler log", "剧透日志"}, {"Rename", "重命名"},
    {"No matches.", "没有匹配项。"}, {"Load a save and get into the game to warp.", "请先载入存档并进入游戏后再传送。"},
    {"Load a save file and get into the game to use cheats.", "请先载入存档并进入游戏后再使用作弊功能。"},
    {"Load a save file and get into the game to edit it.", "请先载入存档并进入游戏后再编辑。"},
    {"The interface changes immediately. Auto follows the effective game language; languages without a UI translation use English.",
     "界面语言会立即切换。自动模式跟随当前游戏语言；尚无界面翻译的语言会使用英语。"},
    {"The game's text language, as its own system setting. Applies when the game restarts: Quit -> Title screen, then Play.",
     "游戏内文字使用的系统语言。重新启动游戏后生效：退出 → 启动画面，然后开始游戏。"},
    {"Link walks in the exact direction of the stick instead of snapping to 8 directions.",
     "林克会严格按照摇杆方向移动，而不是吸附到八个方向。"},
    {"Open / close this menu:  F1, Esc, the controller's Home / Xbox / PlayStation button, or Back + Start",
     "打开/关闭菜单：F1、Esc、手柄 Home / Xbox / PlayStation 键，或 Back + Start"},
    {"Switch tabs:  L / R  (Q / E)        Back:  B  (Esc)", "切换标签：L / R（Q / E）        返回：B（Esc）"},
    {"Fullscreen:  F11 / Alt+Enter", "全屏：F11 / Alt+Enter"},
};

static bool chinese(void) {
    bool selected = g_settings.ui_language == UI_LANG_ZH_HANS ||
                    (g_settings.ui_language == UI_LANG_AUTO && !strncmp(settings_language(), "zh", 2));
    return selected && ui_cjk_font_path();
}

bool ui_language_is_cjk(void) { return chinese(); }

const char *ui_tr(const char *english) {
    if (!english || !chinese()) return english;
    for (const Translation &t : kZh) if (!strcmp(english, t.en)) return t.zh;
    return english;
}

const char *ui_cjk_font_path(void) {
    static bool checked;
    static const char *found;
    if (checked) return found;
    checked = true;
    static const char *const paths[] = {
        "fonts/android-cjk.ttf", "fonts/android-cjk.ttc",
        "C:/Windows/Fonts/msyh.ttc", "C:/Windows/Fonts/simhei.ttf",
        "/System/Library/Fonts/PingFang.ttc", "/System/Library/Fonts/Hiragino Sans GB.ttc",
        "/system/fonts/DroidSansFallbackBBK.ttf", "/system/fonts/DroidSansFallback.ttf",
        "/system/fonts/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc", NULL
    };
    for (int i = 0; paths[i]; i++) {
        FILE *f = fopen(paths[i], "rb");
        if (f) { fclose(f); found = paths[i]; break; }
    }
    return found;
}

void ui_add_translation_glyphs(ImFontGlyphRangesBuilder &builder) {
    builder.AddRanges(ImGui::GetIO().Fonts->GetGlyphRangesDefault());
    for (const Translation &t : kZh) builder.AddText(t.zh);
}
