package com.lasrecomp.android;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.provider.DocumentsContract;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.Spinner;
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
    private static final String[] LANGUAGE_CODES = {"auto", "ja", "en-US", "es", "fr", "de", "it", "nl", "ru",
            "ko", "zh-Hans", "zh-Hant"};
    private static final String[] LANGUAGE_NAMES = {"", "日本語", "English", "Español", "Français", "Deutsch",
            "Italiano", "Nederlands", "Русский", "한국어", "简体中文", "繁體中文"};

    private static final int T_SUBTITLE = 0, T_LANGUAGE = 1, T_RESOURCE = 2, T_GAME_DIRECTORY = 3,
            T_READY = 4, T_CHOOSE = 5, T_PLAY = 6, T_PLAY_COUNTDOWN = 7, T_HINT = 8,
            T_STORAGE_ONLY = 9, T_INCOMPLETE = 10, T_AUTO_PHONE = 11;
    // Rows follow LANGUAGE_CODES without "auto"; Auto renders using the phone's effective language.
    private static final String[][] TEXT = {
            {"Android リソース設定", "言語", "リソースフォルダー", "ゲームフォルダー：", "✓ リソースが揃っています",
                    "リソースを選択", "ゲーム開始", "ゲーム開始（%d秒）",
                    "extracted を含むフォルダー、または extracted 自体を選択してください。\n必要: exefs/main、exefs/sdk、exefs/main.npdm、romfs.bin。",
                    "現在は内部ストレージのフォルダーのみ直接読み込めます。", "リソース不足：", "自動（スマートフォンに従う）"},
            {"Android Resource Setup", "Language", "Resource folder", "Game folder: ", "✓ Resources are ready",
                    "Choose Resource Folder", "Play", "Play (%d s)",
                    "Choose a folder containing extracted, or extracted itself.\nRequired: exefs/main, exefs/sdk, exefs/main.npdm and romfs.bin.",
                    "This build can directly load folders in internal storage only.", "Resources incomplete; missing:", "Auto (follow phone)"},
            {"Configuración de recursos Android", "Idioma", "Carpeta de recursos", "Carpeta del juego: ", "✓ Recursos listos",
                    "Elegir carpeta", "Jugar", "Jugar (%d s)",
                    "Elige la carpeta que contiene extracted o la propia carpeta extracted.\nSe requiere: exefs/main, exefs/sdk, exefs/main.npdm y romfs.bin.",
                    "Esta versión solo puede cargar carpetas del almacenamiento interno.", "Faltan recursos:", "Automático (idioma del teléfono)"},
            {"Configuration des ressources Android", "Langue", "Dossier des ressources", "Dossier du jeu : ", "✓ Ressources prêtes",
                    "Choisir le dossier", "Jouer", "Jouer (%d s)",
                    "Choisissez le dossier contenant extracted, ou extracted lui-même.\nRequis : exefs/main, exefs/sdk, exefs/main.npdm et romfs.bin.",
                    "Cette version ne peut charger que les dossiers du stockage interne.", "Ressources manquantes :", "Auto (langue du téléphone)"},
            {"Android-Ressourcen einrichten", "Sprache", "Ressourcenordner", "Spielordner: ", "✓ Ressourcen vollständig",
                    "Ressourcenordner wählen", "Spielen", "Spielen (%d s)",
                    "Wähle den Ordner mit extracted oder extracted selbst.\nBenötigt: exefs/main, exefs/sdk, exefs/main.npdm und romfs.bin.",
                    "Diese Version kann nur Ordner im internen Speicher direkt laden.", "Fehlende Ressourcen:", "Automatisch (Gerätesprache)"},
            {"Configurazione risorse Android", "Lingua", "Cartella risorse", "Cartella del gioco: ", "✓ Risorse pronte",
                    "Scegli cartella", "Gioca", "Gioca (%d s)",
                    "Scegli la cartella che contiene extracted o extracted stessa.\nRichiesti: exefs/main, exefs/sdk, exefs/main.npdm e romfs.bin.",
                    "Questa versione può caricare direttamente solo cartelle nella memoria interna.", "Risorse mancanti:", "Auto (lingua del telefono)"},
            {"Android-bronnen instellen", "Taal", "Bronnenmap", "Spelmap: ", "✓ Bronnen gereed",
                    "Bronnenmap kiezen", "Spelen", "Spelen (%d s)",
                    "Kies de map met extracted of extracted zelf.\nVereist: exefs/main, exefs/sdk, exefs/main.npdm en romfs.bin.",
                    "Deze versie kan alleen mappen in de interne opslag direct laden.", "Ontbrekende bronnen:", "Auto (telefoontaal)"},
            {"Настройка ресурсов Android", "Язык", "Папка ресурсов", "Папка игры: ", "✓ Ресурсы готовы",
                    "Выбрать папку", "Играть", "Играть (%d с)",
                    "Выберите папку с extracted или саму extracted.\nНужны: exefs/main, exefs/sdk, exefs/main.npdm и romfs.bin.",
                    "Эта версия загружает папки только из внутренней памяти.", "Не хватает ресурсов:", "Авто (язык телефона)"},
            {"Android 리소스 설정", "언어", "리소스 폴더", "게임 폴더: ", "✓ 리소스 준비 완료",
                    "리소스 폴더 선택", "게임 시작", "게임 시작 (%d초)",
                    "extracted가 들어 있는 폴더 또는 extracted 폴더를 선택하세요.\n필요: exefs/main, exefs/sdk, exefs/main.npdm, romfs.bin.",
                    "현재 버전은 내부 저장소의 폴더만 직접 불러올 수 있습니다.", "누락된 리소스:", "자동 (휴대전화 언어)"},
            {"Android 资源设置", "语言", "资源目录", "游戏目录：", "✓ 资源完整，可以进入游戏",
                    "选择资源目录", "进入游戏", "进入游戏（%d 秒）",
                    "请选择包含 extracted 的目录；也可以直接选择 extracted 目录。\n需要 exefs/main、exefs/sdk、exefs/main.npdm 和 romfs.bin。",
                    "当前版本只能直接加载手机内部存储中的目录。", "资源不完整，缺少：", "自动（跟随手机语言）"},
            {"Android 資源設定", "語言", "資源目錄", "遊戲目錄：", "✓ 資源完整，可以進入遊戲",
                    "選擇資源目錄", "進入遊戲", "進入遊戲（%d 秒）",
                    "請選擇包含 extracted 的目錄；也可以直接選擇 extracted 目錄。\n需要 exefs/main、exefs/sdk、exefs/main.npdm 和 romfs.bin。",
                    "目前版本只能直接載入手機內部儲存空間中的目錄。", "資源不完整，缺少：", "自動（跟隨手機語言）"}
    };

    private TextView subtitleText;
    private TextView resourceLabel;
    private TextView directoryText;
    private TextView statusText;
    private TextView hintText;
    private Button chooseButton;
    private Button playButton;
    private Spinner languageSpinner;
    private Handler countdownHandler;
    private int countdownSeconds;
    private boolean countdownCancelledByUser;
    private boolean updatingLanguage;
    private boolean returningFromGame;
    private String selectedDirectory;
    private String selectedLanguage;

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
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (statusText != null) {
            boolean autoStart = !returningFromGame;
            returningFromGame = false;
            refreshStatus(autoStart);
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
        if (countdownSeconds > 0 && (action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_MOVE)) {
            countdownCancelledByUser = true;
            cancelCountdown();
            if (playButton != null) playButton.setText(tr(T_PLAY));
        }
        return super.dispatchTouchEvent(event);
    }

    private void buildUi() {
        int padding = dp(28);
        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(padding, padding, padding, padding);
        content.setBackgroundColor(Color.rgb(8, 18, 42));

        TextView title = text("LAS Recomp", 30, Color.rgb(255, 199, 82));
        title.setGravity(Gravity.CENTER_HORIZONTAL);
        content.addView(title, matchWrap());

        subtitleText = text("", 20, Color.WHITE);
        subtitleText.setGravity(Gravity.CENTER_HORIZONTAL);
        LinearLayout.LayoutParams subtitleParams = matchWrap();
        subtitleParams.setMargins(0, dp(8), 0, dp(12));
        content.addView(subtitleText, subtitleParams);

        LinearLayout languageRow = new LinearLayout(this);
        languageRow.setOrientation(LinearLayout.HORIZONTAL);
        languageRow.setGravity(Gravity.CENTER_VERTICAL);
        TextView languageLabel = text("", 16, Color.rgb(168, 205, 255));
        languageLabel.setTag("language_label");
        languageRow.addView(languageLabel, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 0.28f));
        languageSpinner = new Spinner(this);
        languageRow.addView(languageSpinner, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 0.72f));
        content.addView(languageRow, matchWrap());

        LinearLayout actions = new LinearLayout(this);
        actions.setOrientation(LinearLayout.HORIZONTAL);
        chooseButton = button("");
        chooseButton.setOnClickListener(view -> chooseDirectory());
        LinearLayout.LayoutParams actionParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
        actionParams.setMargins(0, dp(8), dp(5), dp(14));
        actions.addView(chooseButton, actionParams);
        playButton = button("");
        playButton.setOnClickListener(view -> startGame());
        LinearLayout.LayoutParams playParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
        playParams.setMargins(dp(5), dp(8), 0, dp(14));
        actions.addView(playButton, playParams);
        content.addView(actions, matchWrap());

        resourceLabel = text("", 17, Color.rgb(168, 205, 255));
        content.addView(resourceLabel, matchWrap());
        directoryText = text("", 15, Color.LTGRAY);
        LinearLayout.LayoutParams directoryParams = matchWrap();
        directoryParams.setMargins(0, dp(5), 0, dp(10));
        content.addView(directoryText, directoryParams);

        statusText = text("", 16, Color.WHITE);
        statusText.setPadding(dp(18), dp(16), dp(18), dp(16));
        statusText.setBackgroundColor(Color.rgb(20, 38, 66));
        content.addView(statusText, matchWrap());

        hintText = text("", 14, Color.GRAY);
        LinearLayout.LayoutParams hintParams = matchWrap();
        hintParams.setMargins(0, dp(12), 0, 0);
        content.addView(hintText, hintParams);

        ScrollView scroll = new ScrollView(this);
        scroll.addView(content);
        setContentView(scroll);

        updateLocalizedText();
        languageSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                if (updatingLanguage || position < 0 || position >= LANGUAGE_CODES.length) return;
                if (LANGUAGE_CODES[position].equals(selectedLanguage)) return;
                selectedLanguage = LANGUAGE_CODES[position];
                getSharedPreferences(PREFS, MODE_PRIVATE).edit().putString(KEY_LANGUAGE, selectedLanguage).apply();
                updateLocalizedText();
                refreshStatus(true);
            }

            @Override public void onNothingSelected(AdapterView<?> parent) {}
        });
    }

    private void chooseDirectory() {
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
            directoryText.setText(uri.toString());
            statusText.setText(tr(T_STORAGE_ONLY));
            statusText.setTextColor(Color.rgb(255, 170, 120));
            playButton.setEnabled(false);
            playButton.setText(tr(T_PLAY));
            return;
        }
        selectedDirectory = path;
        getSharedPreferences(PREFS, MODE_PRIVATE).edit().putString(KEY_DIRECTORY, path).apply();
        installBundledKoreanFont();
        updateLocalizedText();
        refreshStatus(true);
    }

    private void installBundledKoreanFont() {
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
        List<String> missing = missingFiles(gameDirectory);
        directoryText.setText(selectedDirectory + "\n" + tr(T_GAME_DIRECTORY) + gameDirectory.getAbsolutePath());
        if (missing.isEmpty()) {
            long imageSize = new File(gameDirectory, "romfs.bin").length();
            statusText.setText(tr(T_READY) + "\nromfs.bin: " + humanSize(imageSize));
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
        subtitleText.setText(tr(T_SUBTITLE));
        View languageLabel = ((View) languageSpinner.getParent()).findViewWithTag("language_label");
        if (languageLabel instanceof TextView) ((TextView) languageLabel).setText(tr(T_LANGUAGE));
        resourceLabel.setText(tr(T_RESOURCE));
        chooseButton.setText(tr(T_CHOOSE));
        playButton.setText(tr(T_PLAY));
        hintText.setText(tr(T_HINT));

        String[] names = LANGUAGE_NAMES.clone();
        names[0] = tr(T_AUTO_PHONE);
        updatingLanguage = true;
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, names);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        languageSpinner.setAdapter(adapter);
        languageSpinner.setSelection(Math.max(0, languageIndex(selectedLanguage)), false);
        updatingLanguage = false;
    }

    private String tr(int key) {
        int language = effectiveLanguageIndex();
        return TEXT[language - 1][key];
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

    private LinearLayout.LayoutParams matchWrap() {
        return new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT);
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private String humanSize(long bytes) {
        return String.format(java.util.Locale.US, "%.2f GB", bytes / 1000000000.0);
    }
}
