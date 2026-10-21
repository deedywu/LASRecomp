package com.lasrecomp.android;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Rect;
import android.graphics.drawable.GradientDrawable;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.provider.DocumentsContract;
import android.provider.Settings;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.Space;
import android.widget.TextView;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class LauncherActivity extends Activity {
    private static final int PICK_DIRECTORY = 1001;
    private static final String PREFS = "lasrecomp_android";
    private static final String KEY_DIRECTORY = "resource_directory";
    private static final String KEY_LANGUAGE = "language";
    private static final String KEY_PERMISSION_PROMPTED = "storage_permission_prompted";
    private static final String[] LANGUAGE_CODES = {"auto", "ja", "en-US", "es", "fr", "de", "it", "nl", "ru",
            "ko", "zh-Hans", "zh-Hant"};
    private static final String[] LANGUAGE_NAMES = {"", "日本語", "English", "Español", "Français", "Deutsch",
            "Italiano", "Nederlands", "Русский", "한국어", "简体中文", "繁體中文"};

    private static final int T_SUBTITLE = 0, T_LANGUAGE = 1, T_RESOURCE = 2, T_GAME_DIRECTORY = 3,
            T_READY = 4, T_CHOOSE = 5, T_PLAY = 6, T_PLAY_COUNTDOWN = 7, T_HINT = 8,
            T_STORAGE_ONLY = 9, T_INCOMPLETE = 10, T_AUTO_PHONE = 11, T_SETTINGS = 12, T_CLOSE = 13,
            T_LANGUAGE_SETTINGS = 14;
    // Rows follow LANGUAGE_CODES without "auto"; Auto renders using the phone's effective language.
    private static final String[][] TEXT = {
            {"Android リソース設定", "言語", "リソースフォルダー", "ゲームフォルダー：", "✓ リソースが揃っています",
                    "リソースを選択", "ゲーム開始", "ゲーム開始（%d秒）",
                    "extracted を含むフォルダー、または extracted 自体を選択してください。\n必要: exefs/main、exefs/sdk、exefs/main.npdm、romfs.bin。",
                    "現在は内部ストレージのフォルダーのみ直接読み込めます。", "リソース不足：", "自動（スマートフォンに従う）", "設定", "閉じる", "言語設定"},
            {"Android Resource Setup", "Language", "Resource folder", "Game folder: ", "✓ Resources are ready",
                    "Choose Resource Folder", "Play", "Play (%d s)",
                    "Choose a folder containing extracted, or extracted itself.\nRequired: exefs/main, exefs/sdk, exefs/main.npdm and romfs.bin.",
                    "This build can directly load folders in internal storage only.", "Resources incomplete; missing:", "Auto (follow phone)", "Settings", "Close", "Language settings"},
            {"Configuración de recursos Android", "Idioma", "Carpeta de recursos", "Carpeta del juego: ", "✓ Recursos listos",
                    "Elegir carpeta", "Jugar", "Jugar (%d s)",
                    "Elige la carpeta que contiene extracted o la propia carpeta extracted.\nSe requiere: exefs/main, exefs/sdk, exefs/main.npdm y romfs.bin.",
                    "Esta versión solo puede cargar carpetas del almacenamiento interno.", "Faltan recursos:", "Automático (idioma del teléfono)", "Ajustes", "Cerrar", "Configuración de idioma"},
            {"Configuration des ressources Android", "Langue", "Dossier des ressources", "Dossier du jeu : ", "✓ Ressources prêtes",
                    "Choisir le dossier", "Jouer", "Jouer (%d s)",
                    "Choisissez le dossier contenant extracted, ou extracted lui-même.\nRequis : exefs/main, exefs/sdk, exefs/main.npdm et romfs.bin.",
                    "Cette version ne peut charger que les dossiers du stockage interne.", "Ressources manquantes :", "Auto (langue du téléphone)", "Paramètres", "Fermer", "Paramètres de langue"},
            {"Android-Ressourcen einrichten", "Sprache", "Ressourcenordner", "Spielordner: ", "✓ Ressourcen vollständig",
                    "Ressourcenordner wählen", "Spielen", "Spielen (%d s)",
                    "Wähle den Ordner mit extracted oder extracted selbst.\nBenötigt: exefs/main, exefs/sdk, exefs/main.npdm und romfs.bin.",
                    "Diese Version kann nur Ordner im internen Speicher direkt laden.", "Fehlende Ressourcen:", "Automatisch (Gerätesprache)", "Einstellungen", "Schließen", "Spracheinstellungen"},
            {"Configurazione risorse Android", "Lingua", "Cartella risorse", "Cartella del gioco: ", "✓ Risorse pronte",
                    "Scegli cartella", "Gioca", "Gioca (%d s)",
                    "Scegli la cartella che contiene extracted o extracted stessa.\nRichiesti: exefs/main, exefs/sdk, exefs/main.npdm e romfs.bin.",
                    "Questa versione può caricare direttamente solo cartelle nella memoria interna.", "Risorse mancanti:", "Auto (lingua del telefono)", "Impostazioni", "Chiudi", "Impostazioni lingua"},
            {"Android-bronnen instellen", "Taal", "Bronnenmap", "Spelmap: ", "✓ Bronnen gereed",
                    "Bronnenmap kiezen", "Spelen", "Spelen (%d s)",
                    "Kies de map met extracted of extracted zelf.\nVereist: exefs/main, exefs/sdk, exefs/main.npdm en romfs.bin.",
                    "Deze versie kan alleen mappen in de interne opslag direct laden.", "Ontbrekende bronnen:", "Auto (telefoontaal)", "Instellingen", "Sluiten", "Taalinstellingen"},
            {"Настройка ресурсов Android", "Язык", "Папка ресурсов", "Папка игры: ", "✓ Ресурсы готовы",
                    "Выбрать папку", "Играть", "Играть (%d с)",
                    "Выберите папку с extracted или саму extracted.\nНужны: exefs/main, exefs/sdk, exefs/main.npdm и romfs.bin.",
                    "Эта версия загружает папки только из внутренней памяти.", "Не хватает ресурсов:", "Авто (язык телефона)", "Настройки", "Закрыть", "Настройки языка"},
            {"Android 리소스 설정", "언어", "리소스 폴더", "게임 폴더: ", "✓ 리소스 준비 완료",
                    "리소스 폴더 선택", "게임 시작", "게임 시작 (%d초)",
                    "extracted가 들어 있는 폴더 또는 extracted 폴더를 선택하세요.\n필요: exefs/main, exefs/sdk, exefs/main.npdm, romfs.bin.",
                    "현재 버전은 내부 저장소의 폴더만 직접 불러올 수 있습니다.", "누락된 리소스:", "자동 (휴대전화 언어)", "설정", "닫기", "언어 설정"},
            {"Android 资源设置", "语言", "资源目录", "游戏目录：", "✓ 资源完整，可以进入游戏",
                    "选择资源目录", "进入游戏", "进入游戏（%d 秒）",
                    "请选择包含 extracted 的目录；也可以直接选择 extracted 目录。\n需要 exefs/main、exefs/sdk、exefs/main.npdm 和 romfs.bin。",
                    "当前版本只能直接加载手机内部存储中的目录。", "资源不完整，缺少：", "自动（跟随手机语言）", "设置", "关闭", "语言设置"},
            {"Android 資源設定", "語言", "資源目錄", "遊戲目錄：", "✓ 資源完整，可以進入遊戲",
                    "選擇資源目錄", "進入遊戲", "進入遊戲（%d 秒）",
                    "請選擇包含 extracted 的目錄；也可以直接選擇 extracted 目錄。\n需要 exefs/main、exefs/sdk、exefs/main.npdm 和 romfs.bin。",
                    "目前版本只能直接載入手機內部儲存空間中的目錄。", "資源不完整，缺少：", "自動（跟隨手機語言）", "設定", "關閉", "語言設定"}
    };

    private static final int P_LABEL = 0, P_GRANTED = 1, P_REQUIRED = 2, P_GRANT = 3,
            P_EXPLANATION = 4, P_LATER = 5;
    // Rows follow LANGUAGE_CODES without "auto", matching TEXT.
    private static final String[][] PERMISSION_TEXT = {
            {"ストレージ権限", "✓ ファイルアクセスを許可済み",
                    "/sdcard/LASRecomp のリソースと設定を読み書きするには、すべてのファイルへのアクセスが必要です。",
                    "ファイルアクセスを許可", "LAS Recomp が /sdcard/LASRecomp のリソースを読み込み、設定やセーブデータを書き込むために、すべてのファイルへのアクセスを許可してください。", "後で"},
            {"Storage permission", "✓ File access granted",
                    "Access to all files is required to read and update /sdcard/LASRecomp.",
                    "Grant File Access", "Allow access to all files so LAS Recomp can read resources and write settings and save data in /sdcard/LASRecomp.", "Not now"},
            {"Permiso de almacenamiento", "✓ Acceso a archivos concedido",
                    "Se necesita acceso a todos los archivos para leer y actualizar /sdcard/LASRecomp.",
                    "Conceder acceso", "Permite el acceso a todos los archivos para que LAS Recomp pueda leer recursos y guardar ajustes y partidas en /sdcard/LASRecomp.", "Ahora no"},
            {"Autorisation de stockage", "✓ Accès aux fichiers accordé",
                    "L’accès à tous les fichiers est requis pour lire et modifier /sdcard/LASRecomp.",
                    "Autoriser l’accès", "Autorisez l’accès à tous les fichiers afin que LAS Recomp puisse lire les ressources et écrire les réglages et sauvegardes dans /sdcard/LASRecomp.", "Plus tard"},
            {"Speicherberechtigung", "✓ Dateizugriff gewährt",
                    "Für /sdcard/LASRecomp wird der Zugriff auf alle Dateien benötigt.",
                    "Dateizugriff erlauben", "Erlaube den Zugriff auf alle Dateien, damit LAS Recomp Ressourcen lesen und Einstellungen sowie Spielstände in /sdcard/LASRecomp speichern kann.", "Später"},
            {"Autorizzazione di archiviazione", "✓ Accesso ai file consentito",
                    "È necessario l’accesso a tutti i file per leggere e aggiornare /sdcard/LASRecomp.",
                    "Consenti accesso", "Consenti l’accesso a tutti i file affinché LAS Recomp possa leggere le risorse e salvare impostazioni e partite in /sdcard/LASRecomp.", "Non ora"},
            {"Opslagtoestemming", "✓ Bestandstoegang toegestaan",
                    "Toegang tot alle bestanden is nodig om /sdcard/LASRecomp te lezen en bij te werken.",
                    "Bestandstoegang toestaan", "Sta toegang tot alle bestanden toe zodat LAS Recomp bronnen kan lezen en instellingen en opgeslagen spellen in /sdcard/LASRecomp kan schrijven.", "Later"},
            {"Доступ к хранилищу", "✓ Доступ к файлам разрешён",
                    "Для чтения и обновления /sdcard/LASRecomp нужен доступ ко всем файлам.",
                    "Разрешить доступ", "Разрешите доступ ко всем файлам, чтобы LAS Recomp мог читать ресурсы и сохранять настройки и прогресс в /sdcard/LASRecomp.", "Позже"},
            {"저장소 권한", "✓ 파일 접근 허용됨",
                    "/sdcard/LASRecomp를 읽고 업데이트하려면 모든 파일 접근 권한이 필요합니다.",
                    "파일 접근 허용", "LAS Recomp가 /sdcard/LASRecomp의 리소스를 읽고 설정과 저장 데이터를 기록할 수 있도록 모든 파일 접근을 허용하세요.", "나중에"},
            {"文件权限", "✓ 已获得文件访问权限",
                    "需要“所有文件访问权限”才能读取和更新 /sdcard/LASRecomp。",
                    "授予文件权限", "请允许 LAS Recomp 访问所有文件，以便读取 /sdcard/LASRecomp 中的资源，并写入设置和存档。", "稍后"},
            {"檔案權限", "✓ 已取得檔案存取權限",
                    "需要「所有檔案存取權限」才能讀取和更新 /sdcard/LASRecomp。",
                    "授予檔案權限", "請允許 LAS Recomp 存取所有檔案，以便讀取 /sdcard/LASRecomp 中的資源，並寫入設定和存檔。", "稍後"}
    };

    private TextView statusText;
    private TextView permissionStatusText;
    private TextView languageTitle;
    private Button permissionButton;
    private Button chooseButton;
    private Button playButton;
    private Button settingsButton;
    private Button closeLanguageButton;
    private ImageView backgroundView;
    private LinearLayout languagePanel;
    private LinearLayout languageChoices;
    private View languageBackdrop;
    private Handler countdownHandler;
    private int countdownSeconds;
    private boolean countdownCancelledByUser;
    private boolean returningFromGame;
    private String selectedDirectory;
    private String selectedLanguage;
    private String loadedBackgroundPath;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.rgb(8, 18, 42));
        getWindow().setNavigationBarColor(Color.rgb(8, 18, 42));
        selectedDirectory = getSharedPreferences(PREFS, MODE_PRIVATE)
                .getString(KEY_DIRECTORY, "/sdcard/LASRecomp");
        if (getSharedPreferences(PREFS, MODE_PRIVATE).contains(KEY_LANGUAGE))
            selectedLanguage = getSharedPreferences(PREFS, MODE_PRIVATE).getString(KEY_LANGUAGE, "auto");
        else selectedLanguage = readNativeLanguage();
        if (selectedLanguage == null) selectedLanguage = "auto";
        if (languageIndex(selectedLanguage) < 0) selectedLanguage = "auto";
        countdownHandler = new Handler(Looper.getMainLooper());
        installBundledKoreanFont();
        buildUi();
        setLanguageVisible(false);
        maybeShowFirstPermissionPrompt();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (statusText != null) {
            boolean returnedFromGame = returningFromGame;
            boolean autoStart = !returnedFromGame;
            returningFromGame = false;
            if (returnedFromGame) setLanguageVisible(false);
            refreshPermissionUi();
            refreshStatus(autoStart);
            loadLauncherBackground();
        }
    }

    @Override
    protected void onPause() {
        cancelCountdown();
        super.onPause();
    }

    @Override
    public boolean dispatchTouchEvent(MotionEvent event) {
        int action = event.getActionMasked();
        if (action == MotionEvent.ACTION_DOWN && languagePanel != null &&
                languagePanel.getVisibility() == View.VISIBLE) {
            Rect panelBounds = new Rect();
            languagePanel.getGlobalVisibleRect(panelBounds);
            if (!panelBounds.contains((int) event.getRawX(), (int) event.getRawY())) {
                setLanguageVisible(false);
                return true;
            }
        }
        if (countdownSeconds > 0 && (action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_MOVE)) {
            countdownCancelledByUser = true;
            cancelCountdown();
            if (playButton != null) playButton.setText(tr(T_PLAY));
        }
        return super.dispatchTouchEvent(event);
    }

    private void buildUi() {
        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(Color.rgb(6, 13, 30));

        backgroundView = new ImageView(this);
        backgroundView.setScaleType(ImageView.ScaleType.CENTER_CROP);
        root.addView(backgroundView, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        View shade = new View(this);
        GradientDrawable shadeDrawable = new GradientDrawable(GradientDrawable.Orientation.LEFT_RIGHT,
                new int[] {Color.argb(250, 5, 15, 38), Color.argb(218, 7, 18, 43),
                        Color.argb(70, 7, 18, 43), Color.TRANSPARENT});
        shade.setBackground(shadeDrawable);
        root.addView(shade, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        LinearLayout home = new LinearLayout(this);
        home.setOrientation(LinearLayout.VERTICAL);
        home.setPadding(dp(42), dp(30), dp(28), dp(24));
        FrameLayout.LayoutParams homeParams = new FrameLayout.LayoutParams(dp(480),
                FrameLayout.LayoutParams.MATCH_PARENT, Gravity.START);
        root.addView(home, homeParams);

        TextView title = text("LAS Recompiled", 28, Color.rgb(255, 196, 76));
        home.addView(title, matchWrap());

        Space menuGap = new Space(this);
        home.addView(menuGap, new LinearLayout.LayoutParams(1, 0, 0.34f));

        playButton = menuButton("");
        playButton.setOnClickListener(view -> startGame());
        home.addView(playButton, matchWrap());

        settingsButton = menuButton("");
        settingsButton.setOnClickListener(view -> {
            countdownCancelledByUser = true;
            cancelCountdown();
            playButton.setText(tr(T_PLAY));
            setLanguageVisible(languagePanel.getVisibility() != View.VISIBLE);
        });
        home.addView(settingsButton, matchWrap());

        chooseButton = menuButton("");
        chooseButton.setOnClickListener(view -> chooseDirectory());
        home.addView(chooseButton, matchWrap());

        permissionButton = menuButton("");
        permissionButton.setOnClickListener(view -> requestStoragePermission());
        home.addView(permissionButton, matchWrap());

        Space statusGap = new Space(this);
        home.addView(statusGap, new LinearLayout.LayoutParams(1, 0, 1));

        permissionStatusText = text("", 14, Color.WHITE);
        permissionStatusText.setPadding(dp(4), dp(4), dp(4), dp(4));
        LinearLayout.LayoutParams permissionStatusParams = matchWrap();
        permissionStatusParams.setMargins(0, 0, 0, dp(8));
        home.addView(permissionStatusText, permissionStatusParams);

        statusText = text("", 14, Color.WHITE);
        statusText.setPadding(dp(4), dp(4), dp(4), dp(4));
        home.addView(statusText, matchWrap());

        TextView version = text("Android  ·  Beta 4", 12, Color.rgb(182, 197, 224));
        LinearLayout.LayoutParams versionParams = matchWrap();
        versionParams.setMargins(0, dp(7), 0, 0);
        home.addView(version, versionParams);

        languageBackdrop = new View(this);
        languageBackdrop.setBackgroundColor(Color.argb(110, 0, 0, 0));
        languageBackdrop.setOnClickListener(view -> setLanguageVisible(false));
        languageBackdrop.setVisibility(View.GONE);
        root.addView(languageBackdrop, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        languagePanel = new LinearLayout(this);
        languagePanel.setOrientation(LinearLayout.VERTICAL);
        languagePanel.setPadding(dp(24), dp(18), dp(24), dp(22));
        languagePanel.setBackground(panelBackground(Color.argb(252, 10, 24, 38), dp(14)));
        languagePanel.setClickable(true);
        languagePanel.setVisibility(View.GONE);
        FrameLayout.LayoutParams panelParams = new FrameLayout.LayoutParams(dp(660),
                FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.CENTER);
        panelParams.setMargins(dp(24), dp(18), dp(24), dp(18));
        root.addView(languagePanel, panelParams);

        LinearLayout panelHeader = new LinearLayout(this);
        panelHeader.setOrientation(LinearLayout.HORIZONTAL);
        panelHeader.setGravity(Gravity.CENTER_VERTICAL);
        languageTitle = text("", 24, Color.rgb(255, 196, 76));
        panelHeader.addView(languageTitle, new LinearLayout.LayoutParams(0,
                LinearLayout.LayoutParams.WRAP_CONTENT, 1));
        closeLanguageButton = button("×");
        closeLanguageButton.setTextColor(Color.rgb(230, 232, 234));
        closeLanguageButton.setTextSize(25);
        closeLanguageButton.setPadding(0, 0, 0, 0);
        closeLanguageButton.setMinWidth(dp(46));
        closeLanguageButton.setMinHeight(dp(42));
        closeLanguageButton.setBackgroundColor(Color.TRANSPARENT);
        closeLanguageButton.setStateListAnimator(null);
        closeLanguageButton.setOnClickListener(view -> setLanguageVisible(false));
        panelHeader.addView(closeLanguageButton, new LinearLayout.LayoutParams(dp(48), dp(44)));
        languagePanel.addView(panelHeader, matchWrap());

        languageChoices = new LinearLayout(this);
        languageChoices.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams choicesParams = matchWrap();
        choicesParams.setMargins(0, dp(8), 0, 0);
        languagePanel.addView(languageChoices, choicesParams);

        setContentView(root);

        updateLocalizedText();
    }

    private void chooseDirectory() {
        if (!hasStorageAccess()) {
            requestStoragePermission();
            return;
        }
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION
                | Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                | Intent.FLAG_GRANT_PREFIX_URI_PERMISSION);
        startActivityForResult(intent, PICK_DIRECTORY);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != PICK_DIRECTORY || resultCode != RESULT_OK || data == null || data.getData() == null) return;
        Uri uri = data.getData();
        try {
            getContentResolver().takePersistableUriPermission(uri,
                    data.getFlags() & (Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION));
        } catch (SecurityException ignored) {
        }
        String path = externalStoragePath(uri);
        if (path == null) {
            cancelCountdown();
            statusText.setText(tr(T_STORAGE_ONLY));
            statusText.setTextColor(Color.rgb(255, 170, 120));
            playButton.setEnabled(false);
            playButton.setText(tr(T_PLAY));
            return;
        }
        selectedDirectory = path;
        getSharedPreferences(PREFS, MODE_PRIVATE).edit().putString(KEY_DIRECTORY, path).apply();
        loadedBackgroundPath = null;
        installBundledKoreanFont();
        updateLocalizedText();
        refreshStatus(true);
        loadLauncherBackground();
    }

    private void installBundledKoreanFont() {
        if (!hasStorageAccess()) return;
        File directory = new File(selectedDirectory, "fonts");
        File target = new File(directory, "android-korean.ttf");
        if (target.isFile() && target.length() == 2054744) return;
        if (!directory.isDirectory() && !directory.mkdirs()) return;
        File temporary = new File(directory, ".android-korean.ttf.tmp");
        try (InputStream input = getAssets().open("NanumGothic-Regular.ttf");
             FileOutputStream output = new FileOutputStream(temporary)) {
            byte[] buffer = new byte[65536];
            for (int count; (count = input.read(buffer)) >= 0;) output.write(buffer, 0, count);
            if (!temporary.renameTo(target)) {
                target.delete();
                temporary.renameTo(target);
            }
        } catch (Exception ignored) {
            temporary.delete();
        }
    }

    private String externalStoragePath(Uri uri) {
        if (!"com.android.externalstorage.documents".equals(uri.getAuthority())) return null;
        String documentId = DocumentsContract.getTreeDocumentId(uri);
        int separator = documentId.indexOf(':');
        if (separator < 0) return null;
        String volume = documentId.substring(0, separator);
        String relative = documentId.substring(separator + 1);
        if (!"primary".equalsIgnoreCase(volume)) return null;
        File root = Environment.getExternalStorageDirectory();
        return relative.isEmpty() ? root.getAbsolutePath() : new File(root, relative).getAbsolutePath();
    }

    private File gameDirectory() {
        File selected = new File(selectedDirectory);
        File nested = new File(selected, "extracted");
        return nested.isDirectory() ? nested : selected;
    }

    private List<String> missingFiles(File gameDirectory) {
        String[] required = {"exefs/main", "exefs/sdk", "exefs/main.npdm", "romfs.bin"};
        List<String> missing = new ArrayList<>();
        for (String relative : required)
            if (!new File(gameDirectory, relative).isFile()) missing.add(relative);
        return missing;
    }

    private void refreshStatus(boolean autoStart) {
        cancelCountdown();
        File gameDirectory = gameDirectory();
        if (!hasStorageAccess()) {
            statusText.setText(ptr(P_REQUIRED));
            statusText.setTextColor(Color.rgb(255, 170, 120));
            playButton.setEnabled(false);
            playButton.setText(tr(T_PLAY));
            return;
        }
        List<String> missing = missingFiles(gameDirectory);
        if (missing.isEmpty()) {
            statusText.setText(tr(T_READY) + "\n" + tr(T_RESOURCE) + ": " + selectedDirectory);
            statusText.setTextColor(Color.rgb(126, 235, 147));
            playButton.setEnabled(true);
            if (autoStart && !countdownCancelledByUser) startCountdown();
            else playButton.setText(tr(T_PLAY));
        } else {
            StringBuilder message = new StringBuilder(tr(T_INCOMPLETE)).append('\n');
            for (String file : missing) message.append("• ").append(file).append('\n');
            statusText.setText(message.toString().trim());
            statusText.setTextColor(Color.rgb(255, 170, 120));
            playButton.setEnabled(false);
            playButton.setText(tr(T_PLAY));
        }
    }

    private void startGame() {
        cancelCountdown();
        if (!hasStorageAccess()) {
            requestStoragePermission();
            return;
        }
        File gameDirectory = gameDirectory();
        if (!missingFiles(gameDirectory).isEmpty()) {
            refreshStatus(false);
            return;
        }
        getSharedPreferences(PREFS, MODE_PRIVATE).edit().putString(KEY_LANGUAGE, selectedLanguage).apply();
        Intent intent = new Intent(this, LASRecompActivity.class);
        intent.putExtra("game_directory", gameDirectory.getAbsolutePath());
        intent.putExtra("language", selectedLanguage);
        returningFromGame = true;
        startActivity(intent);
    }

    private final Runnable countdownTick = new Runnable() {
        @Override public void run() {
            if (!playButton.isEnabled()) return;
            countdownSeconds--;
            if (countdownSeconds <= 0) {
                startGame();
                return;
            }
            updateCountdownLabel();
            countdownHandler.postDelayed(this, 1000);
        }
    };

    private void startCountdown() {
        countdownSeconds = 5;
        updateCountdownLabel();
        countdownHandler.postDelayed(countdownTick, 1000);
    }

    private void cancelCountdown() {
        if (countdownHandler != null) countdownHandler.removeCallbacks(countdownTick);
        countdownSeconds = 0;
    }

    private void updateCountdownLabel() {
        playButton.setText(String.format(Locale.getDefault(), tr(T_PLAY_COUNTDOWN), countdownSeconds));
    }

    private void updateLocalizedText() {
        chooseButton.setText(tr(T_CHOOSE));
        playButton.setText(tr(T_PLAY));
        permissionButton.setText(ptr(P_GRANT));
        settingsButton.setText(languageButtonLabel());
        languageTitle.setText(languageButtonLabel());
        closeLanguageButton.setContentDescription(tr(T_CLOSE));
        refreshPermissionUi();
        rebuildLanguageChoices();
    }

    private void rebuildLanguageChoices() {
        if (languageChoices == null) return;
        languageChoices.removeAllViews();
        languageChoices.setOrientation(LinearLayout.VERTICAL);

        Button automatic = languageChoiceButton(0, tr(T_AUTO_PHONE));
        LinearLayout.LayoutParams automaticParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, dp(44));
        automaticParams.setMargins(0, dp(2), 0, dp(5));
        languageChoices.addView(automatic, automaticParams);

        LinearLayout columns = new LinearLayout(this);
        columns.setOrientation(LinearLayout.HORIZONTAL);
        languageChoices.addView(columns, matchWrap());
        LinearLayout[] column = new LinearLayout[3];
        for (int i = 0; i < column.length; i++) {
            column[i] = new LinearLayout(this);
            column[i].setOrientation(LinearLayout.VERTICAL);
            LinearLayout.LayoutParams columnParams = new LinearLayout.LayoutParams(0,
                    LinearLayout.LayoutParams.WRAP_CONTENT, 1);
            if (i > 0) columnParams.setMargins(dp(8), 0, 0, 0);
            columns.addView(column[i], columnParams);
        }

        for (int i = 1; i < LANGUAGE_CODES.length; i++) {
            Button choice = languageChoiceButton(i, LANGUAGE_NAMES[i]);
            LinearLayout.LayoutParams choiceParams = new LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, dp(42));
            choiceParams.setMargins(0, dp(2), 0, dp(2));
            column[(i - 1) / 4].addView(choice, choiceParams);
        }
    }

    private Button languageChoiceButton(int position, String label) {
        boolean selected = LANGUAGE_CODES[position].equals(selectedLanguage);
        Button choice = button((selected ? "✓  " : "    ") + label);
        choice.setTextSize(14);
        choice.setTextColor(selected ? Color.rgb(255, 211, 111) : Color.rgb(232, 237, 244));
        choice.setGravity(Gravity.START | Gravity.CENTER_VERTICAL);
        choice.setPadding(dp(13), 0, dp(10), 0);
        choice.setMinHeight(dp(40));
        choice.setBackground(languageChoiceBackground(selected));
        choice.setStateListAnimator(null);
        choice.setSingleLine(true);
        choice.setOnClickListener(view -> selectLanguage(position));
        return choice;
    }

    private void selectLanguage(int position) {
        if (position < 0 || position >= LANGUAGE_CODES.length) return;
        if (!LANGUAGE_CODES[position].equals(selectedLanguage)) {
            selectedLanguage = LANGUAGE_CODES[position];
            getSharedPreferences(PREFS, MODE_PRIVATE).edit()
                    .putString(KEY_LANGUAGE, selectedLanguage).apply();
            updateLocalizedText();
            refreshStatus(false);
        }
        setLanguageVisible(false);
    }

    private String tr(int key) {
        int language = effectiveLanguageIndex();
        return TEXT[language - 1][key];
    }

    private String ptr(int key) {
        return PERMISSION_TEXT[effectiveLanguageIndex() - 1][key];
    }

    private String languageButtonLabel() {
        return effectiveLanguageIndex() == 2 ? "LANGUAGE" : tr(T_LANGUAGE_SETTINGS) + "/LANGUAGE";
    }

    private boolean hasStorageAccess() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) return Environment.isExternalStorageManager();
        return checkSelfPermission(android.Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED;
    }

    private void refreshPermissionUi() {
        if (permissionStatusText == null || permissionButton == null) return;
        boolean granted = hasStorageAccess();
        permissionStatusText.setText(ptr(granted ? P_GRANTED : P_REQUIRED));
        permissionStatusText.setTextColor(granted ? Color.rgb(126, 235, 147) : Color.rgb(255, 170, 120));
        permissionButton.setVisibility(granted ? View.GONE : View.VISIBLE);
        if (granted) installBundledKoreanFont();
    }

    private void maybeShowFirstPermissionPrompt() {
        if (hasStorageAccess()) return;
        if (getSharedPreferences(PREFS, MODE_PRIVATE).getBoolean(KEY_PERMISSION_PROMPTED, false)) return;
        getSharedPreferences(PREFS, MODE_PRIVATE).edit().putBoolean(KEY_PERMISSION_PROMPTED, true).apply();
        new AlertDialog.Builder(this)
                .setTitle(ptr(P_LABEL))
                .setMessage(ptr(P_EXPLANATION))
                .setPositiveButton(ptr(P_GRANT), (dialog, which) -> requestStoragePermission())
                .setNegativeButton(ptr(P_LATER), null)
                .show();
    }

    private void requestStoragePermission() {
        cancelCountdown();
        try {
            Intent intent = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                    Uri.parse("package:" + getPackageName()));
            startActivity(intent);
        } catch (Exception unavailable) {
            startActivity(new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION));
        }
    }

    private int effectiveLanguageIndex() {
        int selected = languageIndex(selectedLanguage);
        if (selected > 0) return selected;
        int phone = languageIndex(phoneLanguage());
        return phone > 0 ? phone : 2; // English is available in every game region.
    }

    private int languageIndex(String code) {
        if (code == null) return -1;
        for (int i = 0; i < LANGUAGE_CODES.length; i++)
            if (LANGUAGE_CODES[i].equals(code)) return i;
        return -1;
    }

    private String phoneLanguage() {
        Locale locale = getResources().getConfiguration().getLocales().get(0);
        String language = locale.getLanguage();
        if ("zh".equals(language)) {
            String script = locale.getScript(), country = locale.getCountry();
            return "Hant".equals(script) || "TW".equals(country) || "HK".equals(country) || "MO".equals(country)
                    ? "zh-Hant" : "zh-Hans";
        }
        if ("en".equals(language)) return "en-US";
        for (int i = 1; i < LANGUAGE_CODES.length; i++)
            if (LANGUAGE_CODES[i].equals(language)) return LANGUAGE_CODES[i];
        return "en-US";
    }

    private File dataDirectory() {
        File game = gameDirectory();
        return "extracted".equals(game.getName()) && game.getParentFile() != null ? game.getParentFile() : game;
    }

    private String readNativeLanguage() {
        File settings = new File(dataDirectory(), "larecomp.ini");
        if (!settings.isFile()) return null;
        try (BufferedReader reader = new BufferedReader(new FileReader(settings))) {
            for (String line; (line = reader.readLine()) != null;) {
                int equals = line.indexOf('=');
                if (equals < 0 || !"language".equals(line.substring(0, equals).trim())) continue;
                String code = line.substring(equals + 1).trim();
                if ("zh-CN".equals(code)) code = "zh-Hans";
                else if ("zh-TW".equals(code)) code = "zh-Hant";
                return languageIndex(code) >= 0 ? code : null;
            }
        } catch (Exception ignored) {
        }
        return null;
    }

    private TextView text(String value, int size, int color) {
        TextView view = new TextView(this);
        view.setText(value);
        view.setTextSize(size);
        view.setTextColor(color);
        view.setLineSpacing(0, 1.2f);
        return view;
    }

    private Button button(String label) {
        Button button = new Button(this);
        button.setText(label);
        button.setTextSize(17);
        button.setAllCaps(false);
        button.setMinHeight(dp(52));
        return button;
    }

    private Button menuButton(String label) {
        Button button = button(label);
        button.setTextColor(Color.rgb(238, 240, 245));
        button.setTextSize(17);
        button.setGravity(Gravity.START | Gravity.CENTER_VERTICAL);
        button.setPadding(dp(12), 0, dp(12), 0);
        button.setBackgroundColor(Color.TRANSPARENT);
        button.setStateListAnimator(null);
        return button;
    }

    private void setLanguageVisible(boolean visible) {
        if (visible) {
            countdownCancelledByUser = true;
            cancelCountdown();
            if (playButton != null) playButton.setText(tr(T_PLAY));
            rebuildLanguageChoices();
        }
        int visibility = visible ? View.VISIBLE : View.GONE;
        if (languageBackdrop != null) languageBackdrop.setVisibility(visibility);
        if (languagePanel != null) languagePanel.setVisibility(visibility);
    }

    private GradientDrawable languageChoiceBackground(boolean selected) {
        GradientDrawable background = new GradientDrawable();
        background.setColor(selected ? Color.rgb(35, 82, 68) : Color.rgb(20, 43, 55));
        background.setCornerRadius(dp(7));
        background.setStroke(dp(1), selected
                ? Color.rgb(224, 174, 70) : Color.argb(80, 139, 157, 172));
        return background;
    }

    private GradientDrawable panelBackground(int color, int radius) {
        GradientDrawable background = new GradientDrawable();
        background.setColor(color);
        background.setCornerRadius(radius);
        background.setStroke(dp(1), Color.argb(95, 255, 202, 92));
        return background;
    }

    private void loadLauncherBackground() {
        if (backgroundView == null || !hasStorageAccess()) return;
        File movie = new File(gameDirectory(), "romfs/region_common/movie/title.webm");
        if (!movie.isFile()) return;
        String path = movie.getAbsolutePath();
        if (path.equals(loadedBackgroundPath)) return;
        loadedBackgroundPath = path;
        new Thread(() -> {
            MediaMetadataRetriever retriever = new MediaMetadataRetriever();
            Bitmap frame = null;
            try {
                retriever.setDataSource(path);
                frame = retriever.getFrameAtTime(6_000_000,
                        MediaMetadataRetriever.OPTION_CLOSEST);
            } catch (Exception ignored) {
            } finally {
                try { retriever.release(); } catch (Exception ignored) {}
            }
            Bitmap result = frame;
            if (result != null) runOnUiThread(() -> {
                if (path.equals(loadedBackgroundPath)) backgroundView.setImageBitmap(result);
                else result.recycle();
            });
        }, "launcher-background").start();
    }

    private LinearLayout.LayoutParams matchWrap() {
        return new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT);
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

}
