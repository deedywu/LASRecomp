#include "i18n.h"

#include <stdio.h>
#include <string.h>

extern "C" {
#include "../settings.h"
}

struct Translation { const char *en, *zh; };

struct MultiTranslation {
    const char *en, *ja, *es, *fr, *de, *it, *nl, *ru, *ko, *zh_hans, *zh_hant;
};

// The common shell and settings vocabulary is available in every language the game supports. More specialized
// tools deliberately fall back to their readable English source text when no translation is present.
static const MultiTranslation kMulti[] = {
    {"Auto", "自動", "Automático", "Automatique", "Automatisch", "Automatico", "Automatisch", "Авто", "자동", "自动", "自動"},
    {"Auto (follow game)", "自動（ゲームに合わせる）", "Automático (según el juego)", "Automatique (selon le jeu)", "Automatisch (wie Spiel)", "Automatico (come il gioco)", "Automatisch (volg spel)", "Авто (как в игре)", "자동 (게임 언어)", "自动（跟随游戏）", "自動（跟隨遊戲）"},
    {"Japanese", "日本語", "Japonés", "Japonais", "Japanisch", "Giapponese", "Japans", "Японский", "일본어", "日语", "日文"},
    {"English", "英語", "Inglés", "Anglais", "Englisch", "Inglese", "Engels", "Английский", "영어", "英语", "英文"},
    {"Spanish", "スペイン語", "Español", "Espagnol", "Spanisch", "Spagnolo", "Spaans", "Испанский", "스페인어", "西班牙语", "西班牙文"},
    {"French", "フランス語", "Francés", "Français", "Französisch", "Francese", "Frans", "Французский", "프랑스어", "法语", "法文"},
    {"German", "ドイツ語", "Alemán", "Allemand", "Deutsch", "Tedesco", "Duits", "Немецкий", "독일어", "德语", "德文"},
    {"Italian", "イタリア語", "Italiano", "Italien", "Italienisch", "Italiano", "Italiaans", "Итальянский", "이탈리아어", "意大利语", "義大利文"},
    {"Dutch", "オランダ語", "Neerlandés", "Néerlandais", "Niederländisch", "Olandese", "Nederlands", "Нидерландский", "네덜란드어", "荷兰语", "荷蘭文"},
    {"Russian", "ロシア語", "Ruso", "Russe", "Russisch", "Russo", "Russisch", "Русский", "러시아어", "俄语", "俄文"},
    {"Korean", "韓国語", "Coreano", "Coréen", "Koreanisch", "Coreano", "Koreaans", "Корейский", "한국어", "韩语", "韓文"},
    {"Chinese (Simplified)", "中国語（簡体字）", "Chino simplificado", "Chinois simplifié", "Chinesisch (vereinfacht)", "Cinese semplificato", "Chinees (vereenvoudigd)", "Китайский (упрощённый)", "중국어 (간체)", "简体中文", "簡體中文"},
    {"Chinese (Traditional)", "中国語（繁体字）", "Chino tradicional", "Chinois traditionnel", "Chinesisch (traditionell)", "Cinese tradizionale", "Chinees (traditioneel)", "Китайский (традиционный)", "중국어 (번체)", "繁体中文", "繁體中文"},
    {"Prelaunch", "起動", "Inicio", "Démarrage", "Start", "Avvio", "Start", "Запуск", "시작", "启动", "啟動"},
    {"Video", "映像", "Vídeo", "Vidéo", "Video", "Video", "Video", "Видео", "비디오", "视频", "影像"},
    {"Audio", "音声", "Audio", "Audio", "Audio", "Audio", "Audio", "Аудио", "오디오", "音频", "音訊"},
    {"Save Editor", "セーブ編集", "Guardado", "Sauvegarde", "Spielstand", "Salvataggi", "Opslag", "Сохранения", "저장 편집", "存档编辑", "存檔編輯"},
    {"Randomizer", "ランダマイザー", "Aleatorio", "Aléatoire", "Zufall", "Casuale", "Randomizer", "Рандомайзер", "랜더마이저", "随机化", "隨機化"},
    {"Warp", "ワープ", "Viaje", "Voyage", "Teleport", "Teletrasp.", "Teleport", "Телепорт", "워프", "传送", "傳送"},
    {"Cheats", "チート", "Trucos", "Triche", "Cheats", "Trucchi", "Cheats", "Читы", "치트", "作弊", "作弊"},
    {"Gameplay", "ゲーム", "Juego", "Jeu", "Spiel", "Gioco", "Gameplay", "Игра", "게임", "游戏玩法", "遊戲玩法"},
    {"Cosmetics", "外観", "Aspecto", "Apparence", "Aussehen", "Aspetto", "Uiterlijk", "Вид", "꾸미기", "外观", "外觀"},
    {"Controls", "操作", "Controles", "Commandes", "Steuerung", "Comandi", "Besturing", "Управление", "조작", "控制", "控制"},
    {"Quit", "終了", "Salir", "Quitter", "Ende", "Esci", "Afsluiten", "Выход", "종료", "退出", "退出"},
    {"Settings", "設定", "Ajustes", "Paramètres", "Einstellungen", "Impostazioni", "Instellingen", "Настройки", "설정", "设置", "設定"},
    {"Off", "オフ", "Desactivado", "Désactivé", "Aus", "No", "Uit", "Выкл.", "끔", "关闭", "關閉"},
    {"On", "オン", "Activado", "Activé", "Ein", "Sì", "Aan", "Вкл.", "켬", "开启", "開啟"},
    {"Default", "既定", "Predeterminado", "Par défaut", "Standard", "Predefinito", "Standaard", "По умолчанию", "기본값", "默认", "預設"},
    {"Cancel", "キャンセル", "Cancelar", "Annuler", "Abbrechen", "Annulla", "Annuleren", "Отмена", "취소", "取消", "取消"},
    {"OK", "決定", "Aceptar", "OK", "OK", "OK", "OK", "ОК", "확인", "确定", "確定"},
    {"Display", "画面", "Pantalla", "Affichage", "Anzeige", "Schermo", "Beeld", "Экран", "화면", "显示", "顯示"},
    {"Aspect ratio", "アスペクト比", "Relación de aspecto", "Format d'image", "Seitenverhältnis", "Proporzioni", "Beeldverhouding", "Соотношение сторон", "화면 비율", "画面比例", "畫面比例"},
    {"Unlocked", "自由", "Libre", "Libre", "Frei", "Libero", "Vrij", "Свободное", "자유", "自由比例", "自由比例"},
    {"Original 16:9", "オリジナル 16:9", "Original 16:9", "Original 16:9", "Original 16:9", "Originale 16:9", "Origineel 16:9", "Оригинал 16:9", "원본 16:9", "原始 16:9", "原始 16:9"},
    {"Fullscreen", "フルスクリーン", "Pantalla completa", "Plein écran", "Vollbild", "Schermo intero", "Volledig scherm", "Полный экран", "전체 화면", "全屏", "全螢幕"},
    {"Show FPS", "FPS を表示", "Mostrar FPS", "Afficher les FPS", "FPS anzeigen", "Mostra FPS", "FPS tonen", "Показывать FPS", "FPS 표시", "显示帧率", "顯示 FPS"},
    {"Rendering", "レンダリング", "Renderizado", "Rendu", "Rendering", "Rendering", "Rendering", "Рендеринг", "렌더링", "渲染", "算圖"},
    {"Internal resolution", "内部解像度", "Resolución interna", "Résolution interne", "Interne Auflösung", "Risoluzione interna", "Interne resolutie", "Внутреннее разрешение", "내부 해상도", "内部分辨率", "內部解析度"},
    {"Match display", "画面に合わせる", "Igualar pantalla", "Adapter à l'écran", "An Anzeige anpassen", "Adatta allo schermo", "Beeld volgen", "Как на экране", "화면에 맞춤", "匹配屏幕", "符合螢幕"},
    {"Dynamic", "動的", "Dinámica", "Dynamique", "Dynamisch", "Dinamica", "Dynamisch", "Динамическое", "동적", "动态", "動態"},
    {"Upscaler", "アップスケーラー", "Escalado", "Mise à l'échelle", "Skalierung", "Upscaler", "Opschaling", "Масштабирование", "업스케일러", "放大算法", "放大演算法"},
    {"Bilinear", "バイリニア", "Bilineal", "Bilinéaire", "Bilinear", "Bilineare", "Bilineair", "Билинейный", "이중 선형", "双线性", "雙線性"},
    {"Anti-aliasing", "アンチエイリアス", "Antialiasing", "Anticrénelage", "Kantenglättung", "Antialiasing", "Anti-aliasing", "Сглаживание", "안티앨리어싱", "抗锯齿", "反鋸齒"},
    {"Game", "ゲーム", "Juego", "Jeu", "Spiel", "Gioco", "Spel", "Игра", "게임", "游戏", "遊戲"},
    {"Sound", "サウンド", "Sonido", "Son", "Ton", "Audio", "Geluid", "Звук", "사운드", "声音", "聲音"},
    {"Volume", "音量", "Volumen", "Volume", "Lautstärke", "Volume", "Volume", "Громкость", "음량", "音量", "音量"},
    {"Movement", "移動", "Movimiento", "Déplacement", "Bewegung", "Movimento", "Beweging", "Движение", "이동", "移动", "移動"},
    {"Button prompts", "ボタン表示", "Indicaciones", "Indications", "Tastenanzeigen", "Comandi a schermo", "Knopinfo", "Подсказки кнопок", "버튼 안내", "按键提示", "按鍵提示"},
    {"Button icons", "ボタンアイコン", "Iconos de botones", "Icônes des boutons", "Tastensymbole", "Icone pulsanti", "Knoppictogrammen", "Значки кнопок", "버튼 아이콘", "按键图标", "按鍵圖示"},
    {"System language", "システム言語", "Idioma del sistema", "Langue système", "Systemsprache", "Lingua di sistema", "Systeemtaal", "Язык системы", "시스템 언어", "语言", "系統語言"},
    {"Game language", "ゲーム言語", "Idioma del juego", "Langue du jeu", "Spielsprache", "Lingua del gioco", "Speltaal", "Язык игры", "게임 언어", "游戏语言", "遊戲語言"},
    {"Interface language", "インターフェイス言語", "Idioma de la interfaz", "Langue de l'interface", "Oberflächensprache", "Lingua interfaccia", "Interfacetaal", "Язык интерфейса", "인터페이스 언어", "界面语言", "介面語言"},
    {"Menu", "メニュー", "Menú", "Menu", "Menü", "Menu", "Menu", "Меню", "메뉴", "菜单", "選單"},
    {"Colors", "色", "Colores", "Couleurs", "Farben", "Colori", "Kleuren", "Цвета", "색상", "颜色", "顏色"},
    {"Tunic color", "服の色", "Color de la túnica", "Couleur de la tunique", "Tunika-Farbe", "Colore tunica", "Tuniekkleur", "Цвет туники", "튜닉 색상", "服装颜色", "服裝顏色"},
    {"Heart color", "ハートの色", "Color de corazones", "Couleur des cœurs", "Herzfarbe", "Colore cuori", "Hartkleur", "Цвет сердец", "하트 색상", "心形颜色", "愛心顏色"},
    {"Random colors", "ランダム色", "Colores aleatorios", "Couleurs aléatoires", "Zufällige Farben", "Colori casuali", "Willekeurige kleuren", "Случайные цвета", "무작위 색상", "随机颜色", "隨機顏色"},
    {"Quick", "クイック", "Rápido", "Rapide", "Schnell", "Rapido", "Snel", "Быстро", "빠른 작업", "快捷操作", "快速操作"},
    {"Player", "プレイヤー", "Jugador", "Joueur", "Spieler", "Giocatore", "Speler", "Игрок", "플레이어", "玩家", "玩家"},
    {"Equipment", "装備", "Equipo", "Équipement", "Ausrüstung", "Equipaggiamento", "Uitrusting", "Снаряжение", "장비", "装备", "裝備"},
    {"Ammo", "弾薬", "Munición", "Munitions", "Munition", "Munizioni", "Munitie", "Боеприпасы", "탄약", "弹药", "彈藥"},
    {"General", "一般", "General", "Général", "Allgemein", "Generale", "Algemeen", "Общие", "일반", "常规", "一般"},
    {"Difficulty", "難易度", "Dificultad", "Difficulté", "Schwierigkeit", "Difficoltà", "Moeilijkheid", "Сложность", "난이도", "难度", "難度"},
    {"Seeds", "シード", "Semillas", "Seeds", "Seeds", "Seed", "Seeds", "Сиды", "시드", "种子", "種子"},
    {"New seed", "新しいシード", "Nueva semilla", "Nouveau seed", "Neuer Seed", "Nuovo seed", "Nieuwe seed", "Новый сид", "새 시드", "新种子", "新種子"},
    {"Generate seed", "シードを生成", "Generar semilla", "Générer le seed", "Seed erstellen", "Genera seed", "Seed maken", "Создать сид", "시드 생성", "生成种子", "產生種子"},
    {"Close", "閉じる", "Cerrar", "Fermer", "Schließen", "Chiudi", "Sluiten", "Закрыть", "닫기", "关闭", "關閉"},
    {"Play", "プレイ", "Jugar", "Jouer", "Spielen", "Gioca", "Spelen", "Играть", "플레이", "开始游戏", "開始遊戲"},
    {"Play Now", "今すぐプレイ", "Jugar ahora", "Jouer maintenant", "Jetzt spielen", "Gioca ora", "Nu spelen", "Играть сейчас", "지금 플레이", "立即开始", "立即開始"},
    {"The interface changes immediately. Auto follows the effective game language; languages without a UI translation use English.",
     "表示言語はすぐに変わります。自動ではゲームの言語に従い、未翻訳の文は英語で表示されます。",
     "La interfaz cambia al instante. Automático sigue el idioma del juego; el texto sin traducir usa inglés.",
     "L'interface change immédiatement. Le mode automatique suit le jeu ; le texte non traduit reste en anglais.",
     "Die Oberfläche wechselt sofort. Automatisch folgt dem Spiel; nicht übersetzter Text bleibt Englisch.",
     "L'interfaccia cambia subito. Automatico segue il gioco; il testo non tradotto resta in inglese.",
     "De interface wijzigt direct. Automatisch volgt het spel; onvertaalde tekst blijft Engels.",
     "Интерфейс меняется сразу. Авто следует языку игры; непереведённый текст остаётся на английском.",
     "인터페이스는 즉시 바뀝니다. 자동은 게임 언어를 따르며 번역되지 않은 문구는 영어로 표시됩니다.",
     "界面语言会立即切换。自动模式跟随当前游戏语言；未翻译的文字使用英语。",
     "介面語言會立即切換。自動模式跟隨目前遊戲語言；未翻譯的文字使用英文。"},
    {"Open / close this menu:  Android Back, F1, Esc, controller Home / Guide, or Back + Start",
     "メニューを開く／閉じる：Android 戻る、F1、Esc、コントローラー Home / Guide、または Back + Start",
     "Abrir/cerrar menú: Atrás de Android, F1, Esc, Home/Guide del mando o Back + Start",
     "Ouvrir/fermer le menu : Retour Android, F1, Échap, Home/Guide ou Back + Start",
     "Menü öffnen/schließen: Android-Zurück, F1, Esc, Controller Home/Guide oder Back + Start",
     "Apri/chiudi menu: Indietro Android, F1, Esc, Home/Guide o Back + Start",
     "Menu openen/sluiten: Android Terug, F1, Esc, Home/Guide of Back + Start",
     "Открыть/закрыть меню: Назад Android, F1, Esc, Home/Guide или Back + Start",
     "메뉴 열기/닫기: Android 뒤로, F1, Esc, 컨트롤러 Home/Guide 또는 Back + Start",
     "打开/关闭菜单：Android 返回键、F1、Esc、手柄 Home / Guide，或 Back + Start",
     "開啟/關閉選單：Android 返回鍵、F1、Esc、控制器 Home / Guide，或 Back + Start"},
    {"Remove blur", "ぼかしを無効化", "Quitar desenfoque", "Supprimer le flou", "Unschärfe entfernen", "Rimuovi sfocatura", "Vervaging uit", "Убрать размытие", "흐림 제거", "移除模糊", "移除模糊"},
    {"Hide Hero Mode icon", "辛口モードのアイコンを隠す", "Ocultar icono del modo héroe", "Masquer l'icône du mode Héros", "Heldenmodus-Symbol ausblenden", "Nascondi icona Modalità Eroe", "Hero-moduspictogram verbergen", "Скрыть значок режима героя", "영웅 모드 아이콘 숨기기", "隐藏英雄模式图标", "隱藏英雄模式圖示"},
    {"Room reverb", "部屋の残響", "Reverberación de salas", "Réverbération des salles", "Raumhall", "Riverbero ambientale", "Ruimtegalm", "Реверберация помещений", "공간 잔향", "房间混响", "房間殘響"},
    {"Movie audio", "ムービー音声", "Audio de vídeos", "Son des cinématiques", "Filmton", "Audio filmati", "Filmaudio", "Звук роликов", "영상 음성", "影片声音", "影片聲音"},
    {"Enter your name", "名前を入力", "Introduce tu nombre", "Entrez votre nom", "Namen eingeben", "Inserisci il nome", "Voer je naam in", "Введите имя", "이름을 입력하세요", "输入名字", "輸入名字"},
    {"Unlocked: the view fills the window, so wider (or taller) windows show more of the island - up to ultrawide; houses and dungeons keep their framing. Original 16:9: the game's own framing, with bars.",
     "自由：画面をウィンドウ全体に広げ、横長（または縦長）ほど島が広く見えます（ウルトラワイドまで）。家やダンジョンの構図は維持されます。オリジナル 16:9：ゲーム本来の構図を帯付きで表示します。",
     "Libre: la vista llena la ventana; las ventanas más anchas (o altas) muestran más isla, hasta ultraancho. Casas y mazmorras conservan su encuadre. Original 16:9: encuadre original del juego, con bandas.",
     "Libre : la vue remplit la fenêtre ; une fenêtre plus large (ou haute) montre davantage de l'île, jusqu'à l'ultralarge. Maisons et donjons gardent leur cadrage. Original 16:9 : cadrage du jeu avec bandes.",
     "Frei: Die Ansicht füllt das Fenster; breitere (oder höhere) Fenster zeigen mehr von der Insel, bis Ultrawide. Häuser und Verliese behalten ihren Bildausschnitt. Original 16:9: Originalausschnitt mit Balken.",
     "Libero: la visuale riempie la finestra; finestre più larghe (o alte) mostrano più isola, fino all'ultrawide. Case e dungeon mantengono l'inquadratura. Originale 16:9: inquadratura originale con bande.",
     "Vrij: het beeld vult het venster; bredere (of hogere) vensters tonen meer van het eiland, tot ultrawide. Huizen en kerkers behouden hun kader. Origineel 16:9: het originele beeld met balken.",
     "Свободное: изображение заполняет окно; в более широком (или высоком) окне видно больше острова, вплоть до сверхширокого формата. Дома и подземелья сохраняют кадрирование. Оригинал 16:9: исходный кадр с полосами.",
     "자유: 화면이 창을 채우며, 더 넓거나 높은 창에서는 섬이 더 많이 보입니다(울트라와이드까지). 집과 던전의 구도는 유지됩니다. 원본 16:9: 게임의 원래 구도를 여백과 함께 표시합니다.",
     "自由比例：画面填满窗口；窗口越宽（或越高），能看到的岛屿范围越大，最高支持超宽屏。房屋和迷宫仍保持原有构图。原始 16:9：按游戏原始构图显示，并保留黑边。",
     "自由比例：畫面填滿視窗；視窗越寬（或越高），能看到的島嶼範圍越大，最高支援超寬螢幕。房屋和迷宮仍維持原有構圖。原始 16:9：依遊戲原始構圖顯示，並保留黑邊。"},
    {"Fills the screen. Also: F11, Alt+Enter or Cmd+Ctrl+F.",
     "画面全体に表示します。F11、Alt+Enter、Cmd+Ctrl+F でも切り替えられます。", "Llena la pantalla. También: F11, Alt+Enter o Cmd+Ctrl+F.",
     "Remplit l'écran. Raccourcis : F11, Alt+Entrée ou Cmd+Ctrl+F.", "Füllt den Bildschirm. Auch mit F11, Alt+Enter oder Cmd+Ctrl+F.",
     "Riempie lo schermo. Anche con F11, Alt+Invio o Cmd+Ctrl+F.", "Vult het scherm. Ook: F11, Alt+Enter of Cmd+Ctrl+F.",
     "Заполняет экран. Также: F11, Alt+Enter или Cmd+Ctrl+F.", "화면을 가득 채웁니다. F11, Alt+Enter 또는 Cmd+Ctrl+F로도 전환할 수 있습니다.",
     "填满整个屏幕。也可使用 F11、Alt+Enter 或 Cmd+Ctrl+F 切换。", "填滿整個螢幕。也可使用 F11、Alt+Enter 或 Cmd+Ctrl+F 切換。"},
    {"Shows the frame rate in the top right corner.", "フレームレートを右上に表示します。", "Muestra la tasa de fotogramas arriba a la derecha.",
     "Affiche la fréquence d'images en haut à droite.", "Zeigt die Bildrate oben rechts an.", "Mostra la frequenza dei fotogrammi in alto a destra.",
     "Toont de beeldsnelheid rechtsboven.", "Показывает частоту кадров в правом верхнем углу.", "오른쪽 위에 프레임 속도를 표시합니다.",
     "在右上角显示帧率。", "在右上角顯示影格率。"},
    {"How sharp the 3D image is. Match display: your screen's own resolution. Dynamic: as sharp as your GPU keeps at full speed. 1x-4x: the Switch's 1080p times that. 75% / 50% / 25%: a share of the display, for slower machines.",
     "3D 映像の鮮明さです。画面に合わせる：ディスプレイと同じ解像度。動的：GPU がフル速度を保てる範囲で高画質にします。1x～4x：Switch の 1080p の倍率。75% / 50% / 25%：低速な環境向けの画面解像度比です。",
     "Define la nitidez de la imagen 3D. Igualar pantalla: resolución de la pantalla. Dinámica: la máxima nitidez que la GPU mantenga a plena velocidad. 1x-4x: múltiplos de 1080p de Switch. 75% / 50% / 25%: fracción de la pantalla para equipos más lentos.",
     "Définit la netteté de l'image 3D. Adapter à l'écran : résolution de l'écran. Dynamique : la meilleure netteté que le GPU maintient à pleine vitesse. 1x-4x : multiples du 1080p de la Switch. 75 % / 50 % / 25 % : fraction de l'écran pour les machines plus lentes.",
     "Bestimmt die Schärfe des 3D-Bilds. An Anzeige anpassen: Bildschirmauflösung. Dynamisch: höchste Schärfe, die die GPU bei voller Geschwindigkeit hält. 1x–4x: Vielfache der Switch-Auflösung 1080p. 75 % / 50 % / 25 %: Anteil der Anzeige für langsamere Geräte.",
     "Regola la nitidezza dell'immagine 3D. Adatta allo schermo: risoluzione del display. Dinamica: massima nitidezza mantenuta dalla GPU a piena velocità. 1x-4x: multipli dei 1080p di Switch. 75% / 50% / 25%: una frazione del display per dispositivi più lenti.",
     "Bepaalt de scherpte van het 3D-beeld. Beeld volgen: de schermresolutie. Dynamisch: zo scherp als de GPU op volle snelheid aankan. 1x-4x: veelvouden van Switch 1080p. 75% / 50% / 25%: een deel van het scherm voor tragere apparaten.",
     "Определяет чёткость 3D-изображения. Как на экране: разрешение дисплея. Динамическое: максимальная чёткость, которую GPU поддерживает на полной скорости. 1x–4x: кратно 1080p Switch. 75% / 50% / 25%: доля разрешения экрана для слабых устройств.",
     "3D 화면의 선명도를 정합니다. 화면에 맞춤: 디스플레이 해상도. 동적: GPU가 최고 속도를 유지할 수 있는 만큼 선명하게 표시합니다. 1x~4x: Switch 1080p의 배율. 75% / 50% / 25%: 느린 기기를 위한 화면 해상도 비율입니다.",
     "设置 3D 画面的清晰度。匹配屏幕：使用屏幕自身分辨率。动态：在 GPU 保持全速的前提下尽量提高画质。1x–4x：Switch 1080p 的对应倍数。75% / 50% / 25%：按屏幕分辨率的一定比例渲染，适合较慢的设备。",
     "設定 3D 畫面的清晰度。符合螢幕：使用螢幕本身的解析度。動態：在 GPU 維持全速的前提下盡量提高畫質。1x–4x：Switch 1080p 的對應倍數。75% / 50% / 25%：依螢幕解析度的一定比例算圖，適合較慢的裝置。"},
    {"Rendering at", "現在の描画解像度：", "Resolución de renderizado:", "Résolution de rendu :", "Renderauflösung:", "Risoluzione di rendering:", "Renderresolutie:", "Разрешение рендеринга:", "현재 렌더링 해상도:", "当前渲染分辨率：", "目前算圖解析度："},
    {"Dynamic scale now:", "現在の動的スケール：", "Escala dinámica actual:", "Échelle dynamique actuelle :", "Aktuelle dynamische Skalierung:", "Scala dinamica attuale:", "Huidige dynamische schaal:", "Текущий динамический масштаб:", "현재 동적 배율:", "当前动态比例：", "目前動態比例："},
    {"How the image is scaled up to the window when it renders at a lower resolution. MetalFX: Apple's upscaler, sharper. Bilinear: plain and soft.",
     "低い解像度で描画した映像をウィンドウへ拡大する方法です。MetalFX：Apple の高精細なアップスケーラー。バイリニア：標準的で柔らかな表示。",
     "Cómo se amplía la imagen al renderizar a menor resolución. MetalFX: escalador de Apple, más nítido. Bilineal: sencillo y suave.",
     "Méthode d'agrandissement quand le rendu est en basse résolution. MetalFX : mise à l'échelle Apple, plus nette. Bilinéaire : simple et douce.",
     "Legt fest, wie ein Bild mit niedriger Renderauflösung vergrößert wird. MetalFX: Apples schärfere Skalierung. Bilinear: einfach und weich.",
     "Come viene ingrandita l'immagine renderizzata a risoluzione inferiore. MetalFX: upscaler Apple, più nitido. Bilineare: semplice e morbido.",
     "Hoe een beeld met lagere renderresolutie naar het venster wordt vergroot. MetalFX: Apples scherpere opschaling. Bilineair: eenvoudig en zacht.",
     "Как изображение низкого разрешения масштабируется до окна. MetalFX: более чёткое масштабирование Apple. Билинейное: простое и мягкое.",
     "낮은 해상도로 렌더링한 화면을 창 크기로 확대하는 방법입니다. MetalFX: 더 선명한 Apple 업스케일러. 이중 선형: 단순하고 부드럽습니다.",
     "以较低分辨率渲染时，将画面放大到窗口的方式。MetalFX：Apple 的放大算法，画面更锐利。双线性：简单且柔和。",
     "以較低解析度算圖時，將畫面放大到視窗的方式。MetalFX：Apple 的放大演算法，畫面更銳利。雙線性：簡單且柔和。"},
    {"How the image is scaled up to the window when it renders at a lower resolution. AMD FSR 1: edge-aware upscaling and sharpening, sharper. Bilinear: plain and soft.",
     "低い解像度で描画した映像をウィンドウへ拡大する方法です。AMD FSR 1：輪郭を考慮した拡大とシャープ化。バイリニア：標準的で柔らかな表示。",
     "Cómo se amplía la imagen al renderizar a menor resolución. AMD FSR 1: escalado y enfoque con detección de bordes, más nítido. Bilineal: sencillo y suave.",
     "Méthode d'agrandissement quand le rendu est en basse résolution. AMD FSR 1 : mise à l'échelle et netteté guidées par les contours. Bilinéaire : simple et douce.",
     "Legt fest, wie ein Bild mit niedriger Renderauflösung vergrößert wird. AMD FSR 1: kantengeführte Skalierung und Schärfung. Bilinear: einfach und weich.",
     "Come viene ingrandita l'immagine renderizzata a risoluzione inferiore. AMD FSR 1: ingrandimento e nitidezza sensibili ai bordi. Bilineare: semplice e morbido.",
     "Hoe een beeld met lagere renderresolutie wordt vergroot. AMD FSR 1: randbewuste opschaling en verscherping. Bilineair: eenvoudig en zacht.",
     "Как изображение низкого разрешения масштабируется до окна. AMD FSR 1: масштабирование и повышение резкости с учётом краёв. Билинейное: простое и мягкое.",
     "낮은 해상도로 렌더링한 화면을 창 크기로 확대하는 방법입니다. AMD FSR 1: 가장자리를 고려한 확대와 선명화. 이중 선형: 단순하고 부드럽습니다.",
     "以较低分辨率渲染时，将画面放大到窗口的方式。AMD FSR 1：识别边缘后放大并锐化，画面更锐利。双线性：简单且柔和。",
     "以較低解析度算圖時，將畫面放大到視窗的方式。AMD FSR 1：辨識邊緣後放大並銳化，畫面更銳利。雙線性：簡單且柔和。"},
    {"Not used at Match display: the game already renders at your display's resolution.",
     "「画面に合わせる」では使用しません。ゲームはすでにディスプレイの解像度で描画されます。", "No se usa con Igualar pantalla: el juego ya renderiza a la resolución de la pantalla.",
     "Inutilisé avec Adapter à l'écran : le jeu est déjà rendu à la résolution de l'écran.", "Bei „An Anzeige anpassen“ nicht verwendet: Das Spiel rendert bereits in Bildschirmauflösung.",
     "Non usato con Adatta allo schermo: il gioco usa già la risoluzione del display.", "Niet gebruikt bij Beeld volgen: het spel rendert al op de schermresolutie.",
     "Не используется в режиме «Как на экране»: игра уже рендерится в разрешении дисплея.", "화면에 맞춤에서는 사용하지 않습니다. 게임이 이미 디스플레이 해상도로 렌더링됩니다.",
     "匹配屏幕时不使用：游戏已经按屏幕分辨率渲染。", "符合螢幕時不使用：遊戲已經依螢幕解析度算圖。"},
    {"Smooths jagged edges of the game image before it is scaled to the window. SMAA: finds the edges and blends only along them, so textures stay sharp. Most useful at a lower internal resolution.",
     "ウィンドウへ拡大する前に映像のギザギザを滑らかにします。SMAA は輪郭を検出してその周辺だけをなじませるため、テクスチャの鮮明さを保ちます。低い内部解像度で特に有効です。",
     "Suaviza los bordes dentados antes de ampliar la imagen. SMAA detecta los bordes y mezcla solo a lo largo de ellos para mantener nítidas las texturas. Es más útil con una resolución interna baja.",
     "Lisse les bords crénelés avant l'agrandissement. SMAA détecte les contours et ne mélange qu'autour d'eux, préservant la netteté des textures. Surtout utile à basse résolution interne.",
     "Glättet gezackte Kanten vor der Skalierung. SMAA erkennt Kanten und mischt nur dort, sodass Texturen scharf bleiben. Besonders bei niedriger interner Auflösung nützlich.",
     "Smussa i bordi seghettati prima dell'ingrandimento. SMAA rileva i bordi e sfuma solo lungo di essi, mantenendo nitide le texture. Più utile a bassa risoluzione interna.",
     "Maakt kartelranden glad vóór het opschalen. SMAA zoekt randen en mengt alleen daar, zodat texturen scherp blijven. Vooral nuttig bij een lage interne resolutie.",
     "Сглаживает ступенчатые края до масштабирования. SMAA находит края и смешивает только вдоль них, сохраняя чёткость текстур. Наиболее полезно при низком внутреннем разрешении.",
     "창 크기로 확대하기 전에 게임 화면의 계단 현상을 줄입니다. SMAA는 가장자리를 찾아 그 부분만 혼합하므로 텍스처가 선명하게 유지됩니다. 낮은 내부 해상도에서 특히 유용합니다.",
     "在画面放大到窗口前平滑锯齿边缘。SMAA 会识别边缘并仅沿边缘混合，因此纹理仍保持清晰。在较低内部分辨率下最有用。",
     "在畫面放大到視窗前平滑鋸齒邊緣。SMAA 會辨識邊緣並僅沿邊緣混合，因此材質仍保持清晰。在較低內部解析度下最有用。"},
    {"Turns off the tilt-shift blur at the top and bottom of the screen.", "画面の上下にあるティルトシフトぼかしを無効にします。", "Desactiva el desenfoque de inclinación en la parte superior e inferior.",
     "Désactive le flou de bascule en haut et en bas de l'écran.", "Schaltet die Tilt-Shift-Unschärfe am oberen und unteren Bildschirmrand aus.", "Disattiva la sfocatura tilt-shift nella parte superiore e inferiore dello schermo.",
     "Schakelt de tilt-shiftvervaging boven- en onderaan uit.", "Отключает эффект размытия tilt-shift сверху и снизу экрана.", "화면 위아래의 틸트 시프트 흐림 효과를 끕니다.",
     "关闭屏幕顶部和底部的移轴模糊效果。", "關閉螢幕頂部和底部的移軸模糊效果。"},
    {"Hides the Hero Mode emblem in the corner of the screen while playing a Hero Mode file.",
     "辛口モードのセーブデータをプレイ中、画面隅のエンブレムを隠します。", "Oculta el emblema del modo héroe en la esquina al jugar una partida de ese modo.",
     "Masque l'emblème du mode Héros dans le coin pendant une partie de ce mode.", "Blendet beim Spielen eines Heldenmodus-Spielstands das Symbol in der Bildschirmecke aus.",
     "Nasconde l'emblema Modalità Eroe nell'angolo durante una partita in tale modalità.", "Verbergt tijdens een Hero-modusbestand het embleem in de hoek.",
     "Скрывает эмблему режима героя в углу экрана при игре в этом режиме.", "영웅 모드 파일을 플레이할 때 화면 모서리의 영웅 모드 문양을 숨깁니다.",
     "游玩英雄模式存档时，隐藏屏幕角落的英雄模式徽标。", "遊玩英雄模式存檔時，隱藏螢幕角落的英雄模式徽章。"},
    {"Link's tunic color. Default: the game's own (or the randomizer seed's).", "リンクの服の色です。既定：ゲーム本来の色（またはランダマイザーのシード設定）。", "Color de la túnica de Link. Predeterminado: el del juego (o el de la semilla aleatoria).",
     "Couleur de la tunique de Link. Par défaut : celle du jeu (ou du seed du randomizer).", "Links Tunika-Farbe. Standard: die des Spiels (oder des Randomizer-Seeds).", "Colore della tunica di Link. Predefinito: quello del gioco (o del seed randomizer).",
     "De kleur van Links tuniek. Standaard: die van het spel (of van de randomizer-seed).", "Цвет туники Линка. По умолчанию: игровой (или заданный сидом рандомайзера).", "링크의 튜닉 색상입니다. 기본값: 게임 고유 색상(또는 랜더마이저 시드의 색상).",
     "林克的服装颜色。默认：游戏原本的颜色（或随机种子的设置）。", "林克的服裝顏色。預設：遊戲原本的顏色（或隨機種子的設定）。"},
    {"The color of the hearts on the HUD.", "HUD に表示されるハートの色です。", "El color de los corazones del HUD.", "La couleur des cœurs de l'interface.", "Die Farbe der Herzen im HUD.", "Il colore dei cuori nell'interfaccia.", "De kleur van de hartjes in de HUD.", "Цвет сердец в интерфейсе.", "HUD에 표시되는 하트 색상입니다.", "HUD 上心形的颜色。", "HUD 上愛心的顏色。"},
    {"Picks a random tunic and heart color (any other color, Default included).", "服とハートの色をランダムに選びます（現在以外の色。既定を含む）。", "Elige al azar los colores de túnica y corazones (cualquier otro, incluido Predeterminado).",
     "Choisit au hasard les couleurs de la tunique et des cœurs (toute autre couleur, Par défaut comprise).", "Wählt zufällige Tunika- und Herzfarben (jede andere Farbe, einschließlich Standard).", "Sceglie colori casuali per tunica e cuori (qualsiasi altro colore, incluso Predefinito).",
     "Kiest willekeurige kleuren voor tuniek en hartjes (elke andere kleur, inclusief Standaard).", "Случайно выбирает цвет туники и сердец (любой другой, включая цвет по умолчанию).", "튜닉과 하트 색상을 무작위로 고릅니다(현재 색상 이외, 기본값 포함).",
     "随机选择服装和心形颜色（选择不同于当前的颜色，可包含默认值）。", "隨機選擇服裝和愛心顏色（選擇不同於目前的顏色，可包含預設值）。"},
    {"The game's volume. 100% is the game's own level; above it, louder.", "ゲームの音量です。100% が本来の音量で、それ以上はより大きくなります。", "Volumen del juego. 100% es el nivel original; por encima sonará más fuerte.",
     "Volume du jeu. 100 % correspond au niveau d'origine ; au-delà, le son est amplifié.", "Lautstärke des Spiels. 100 % ist die Originallautstärke; darüber wird es lauter.", "Volume del gioco. 100% è il livello originale; oltre è più alto.",
     "Het spelvolume. 100% is het oorspronkelijke niveau; daarboven wordt het luider.", "Громкость игры. 100% — исходный уровень; выше звук становится громче.", "게임 음량입니다. 100%가 게임의 원래 음량이며, 그보다 높이면 더 커집니다.",
     "游戏音量。100% 是游戏原本的音量；高于此值会更响。", "遊戲音量。100% 是遊戲原本的音量；高於此值會更響。"},
    {"The game's echo in caves, dungeons and big rooms.", "洞窟、ダンジョン、大きな部屋で聞こえるゲームの反響音です。", "El eco del juego en cuevas, mazmorras y salas grandes.",
     "L'écho du jeu dans les grottes, donjons et grandes salles.", "Der Spielehall in Höhlen, Verliesen und großen Räumen.", "L'eco del gioco in grotte, dungeon e stanze grandi.",
     "De echo van het spel in grotten, kerkers en grote kamers.", "Игровое эхо в пещерах, подземельях и больших помещениях.", "동굴, 던전, 큰 방에서 들리는 게임의 울림입니다.",
     "游戏在洞穴、迷宫和大型房间中的回声效果。", "遊戲在洞穴、迷宮和大型房間中的回音效果。"},
    {"Sound in the game's movies (the opening and the ending). Applies the next time a movie starts.",
     "ゲームのムービー（オープニングとエンディング）の音声です。次にムービーが始まるときから反映されます。", "Sonido de los vídeos del juego (inicio y final). Se aplica la próxima vez que empiece un vídeo.",
     "Son des cinématiques du jeu (ouverture et fin). S'applique au prochain démarrage d'une cinématique.", "Ton der Spielvideos (Intro und Abspann). Gilt ab dem nächsten gestarteten Video.",
     "Audio dei filmati di gioco (apertura e finale). Si applica all'avvio del prossimo filmato.", "Geluid in de spelvideo's (opening en einde). Wordt toegepast zodra de volgende video start.",
     "Звук в игровых роликах (вступление и финал). Применится при следующем запуске ролика.", "게임 영상(오프닝과 엔딩)의 음성입니다. 다음 영상이 시작될 때부터 적용됩니다.",
     "游戏影片（开场和结局）中的声音。下次影片开始播放时生效。", "遊戲影片（開場和結局）中的聲音。下次影片開始播放時生效。"},
};

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

static int effective_language(void) {
    if (g_settings.ui_language > UI_LANG_AUTO && g_settings.ui_language < N_UI_LANGUAGES)
        return g_settings.ui_language;
    const char *code = settings_language();
    if (!strcmp(code, "en-US")) return UI_LANG_ENGLISH;
    for (int i = 1; i < N_UI_LANGUAGES; i++)
        if (!strcmp(code, g_ui_language_codes[i])) return i;
    return UI_LANG_ENGLISH;
}

const char *ui_localized_font_path(void) {
    static bool checked;
    static const char *found;
    if (checked) return found;
    checked = true;
    static const char *const paths[] = {
        // Android's stock NotoSansCJK TTC uses CFF faces that this ImGui stb_truetype backend cannot parse.
        "fonts/android-cjk.ttf", "fonts/android-cjk.ttc", "fonts/NotoSansCJK-Regular.ttf",
        "/system/fonts/DroidSansFallbackBBK.ttf", "/system/fonts/DroidSansFallback.ttf",
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        "/System/Library/Fonts/PingFang.ttc", "/System/Library/Fonts/Hiragino Sans GB.ttc",
        "C:/Windows/Fonts/msgothic.ttc", "C:/Windows/Fonts/malgun.ttf",
        "C:/Windows/Fonts/msyh.ttc", "C:/Windows/Fonts/simhei.ttf",
        "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc", NULL
    };
    for (int i = 0; paths[i]; i++) {
        FILE *f = fopen(paths[i], "rb");
        if (f) { fclose(f); found = paths[i]; break; }
    }
    return found;
}

const char *ui_korean_font_path(void) {
    static bool checked;
    static const char *found;
    if (checked) return found;
    checked = true;
    static const char *const paths[] = {
        "fonts/android-korean.ttf", "C:/Windows/Fonts/malgun.ttf",
        "/System/Library/Fonts/AppleSDGothicNeo.ttc",
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc", NULL
    };
    for (int i = 0; paths[i]; i++) {
        FILE *f = fopen(paths[i], "rb");
        if (f) { fclose(f); found = paths[i]; break; }
    }
    return found;
}

bool ui_language_is_cjk(void) {
    int l = effective_language();
    return (l == UI_LANG_JAPANESE || l == UI_LANG_KOREAN || l == UI_LANG_ZH_HANS || l == UI_LANG_ZH_HANT) &&
           ui_localized_font_path();
}

bool ui_language_uses_localized_font(void) {
    int l = effective_language();
    return (l == UI_LANG_RUSSIAN || l == UI_LANG_JAPANESE || l == UI_LANG_KOREAN ||
            l == UI_LANG_ZH_HANS || l == UI_LANG_ZH_HANT) && ui_localized_font_path();
}

static const char *multi_value(const MultiTranslation &t, int language) {
    switch (language) {
    case UI_LANG_JAPANESE: return t.ja;
    case UI_LANG_SPANISH: return t.es;
    case UI_LANG_FRENCH: return t.fr;
    case UI_LANG_GERMAN: return t.de;
    case UI_LANG_ITALIAN: return t.it;
    case UI_LANG_DUTCH: return t.nl;
    case UI_LANG_RUSSIAN: return t.ru;
    case UI_LANG_KOREAN: return t.ko;
    case UI_LANG_ZH_HANS: return t.zh_hans;
    case UI_LANG_ZH_HANT: return t.zh_hant;
    default: return t.en;
    }
}

const char *ui_tr(const char *english) {
    if (!english) return english;
    int language = effective_language();
    if (language == UI_LANG_ENGLISH ||
        ((language == UI_LANG_RUSSIAN || language == UI_LANG_JAPANESE || language == UI_LANG_KOREAN ||
          language == UI_LANG_ZH_HANS || language == UI_LANG_ZH_HANT) && !ui_localized_font_path())) return english;
    for (const MultiTranslation &t : kMulti)
        if (!strcmp(english, t.en)) return multi_value(t, language);
    if (language == UI_LANG_ZH_HANS)
        for (const Translation &t : kZh) if (!strcmp(english, t.en)) return t.zh;
    return english;
}

void ui_add_translation_glyphs(ImFontGlyphRangesBuilder &builder) {
    builder.AddRanges(ImGui::GetIO().Fonts->GetGlyphRangesDefault());
    for (const MultiTranslation &t : kMulti) {
        builder.AddText(t.ja); builder.AddText(t.es); builder.AddText(t.fr); builder.AddText(t.de);
        builder.AddText(t.it); builder.AddText(t.nl); builder.AddText(t.ru); builder.AddText(t.ko);
        builder.AddText(t.zh_hans); builder.AddText(t.zh_hant);
    }
    for (const Translation &t : kZh) builder.AddText(t.zh);
}

void ui_add_korean_glyphs(ImFontGlyphRangesBuilder &builder) {
    for (const MultiTranslation &t : kMulti) builder.AddText(t.ko);
    // The base localized face supplies Latin and punctuation. Merge only Hangul so duplicate Latin sources cannot
    // replace or suppress the base face's glyphs in the atlas.
    for (unsigned int c = 0; c < 0xAC00; c++)
        builder.UsedChars[(int)(c >> 5)] &= ~(1u << (c & 31));
}
