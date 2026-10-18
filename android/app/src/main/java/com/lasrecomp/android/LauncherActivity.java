package com.lasrecomp.android;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.provider.DocumentsContract;
import android.view.Gravity;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

public class LauncherActivity extends Activity {
    private static final int PICK_DIRECTORY = 1001;
    private static final String PREFS = "lasrecomp_android";
    private static final String KEY_DIRECTORY = "resource_directory";

    private TextView directoryText;
    private TextView statusText;
    private Button playButton;
    private String selectedDirectory;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.rgb(8, 18, 42));
        getWindow().setNavigationBarColor(Color.rgb(8, 18, 42));
        selectedDirectory = getSharedPreferences(PREFS, MODE_PRIVATE)
                .getString(KEY_DIRECTORY, "/sdcard/LASRecomp");
        installBundledKoreanFont();
        buildUi();
        refreshStatus();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (statusText != null) refreshStatus();
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

        TextView subtitle = text("Android 资源设置", 20, Color.WHITE);
        subtitle.setGravity(Gravity.CENTER_HORIZONTAL);
        LinearLayout.LayoutParams subtitleParams = matchWrap();
        subtitleParams.setMargins(0, dp(8), 0, dp(28));
        content.addView(subtitle, subtitleParams);

        content.addView(text("资源目录", 17, Color.rgb(168, 205, 255)), matchWrap());
        directoryText = text("", 15, Color.LTGRAY);
        LinearLayout.LayoutParams directoryParams = matchWrap();
        directoryParams.setMargins(0, dp(8), 0, dp(18));
        content.addView(directoryText, directoryParams);

        statusText = text("", 16, Color.WHITE);
        statusText.setPadding(dp(18), dp(16), dp(18), dp(16));
        statusText.setBackgroundColor(Color.rgb(20, 38, 66));
        content.addView(statusText, matchWrap());

        Button chooseButton = button("选择资源目录");
        chooseButton.setOnClickListener(view -> chooseDirectory());
        LinearLayout.LayoutParams chooseParams = matchWrap();
        chooseParams.setMargins(0, dp(22), 0, dp(12));
        content.addView(chooseButton, chooseParams);

        playButton = button("进入游戏");
        playButton.setOnClickListener(view -> startGame());
        content.addView(playButton, matchWrap());

        TextView hint = text("请选择包含 extracted 文件夹的目录；也可以直接选择 extracted 文件夹。\n"
                + "需要 exefs/main、exefs/sdk、exefs/main.npdm 和 romfs.bin。", 14, Color.GRAY);
        LinearLayout.LayoutParams hintParams = matchWrap();
        hintParams.setMargins(0, dp(20), 0, 0);
        content.addView(hint, hintParams);

        ScrollView scroll = new ScrollView(this);
        scroll.addView(content);
        setContentView(scroll);
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
            directoryText.setText(uri.toString());
            statusText.setText("当前测试版只能直接加载手机内部存储中的目录。\n请在系统选择器中选择“内部存储”下的文件夹。");
            statusText.setTextColor(Color.rgb(255, 170, 120));
            playButton.setEnabled(false);
            return;
        }
        selectedDirectory = path;
        getSharedPreferences(PREFS, MODE_PRIVATE).edit().putString(KEY_DIRECTORY, path).apply();
        installBundledKoreanFont();
        refreshStatus();
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

    private void refreshStatus() {
        File gameDirectory = gameDirectory();
        List<String> missing = missingFiles(gameDirectory);
        directoryText.setText(selectedDirectory + "\n游戏目录：" + gameDirectory.getAbsolutePath());
        if (missing.isEmpty()) {
            long imageSize = new File(gameDirectory, "romfs.bin").length();
            statusText.setText("✓ 资源完整，可以进入游戏\nromfs.bin：" + humanSize(imageSize));
            statusText.setTextColor(Color.rgb(126, 235, 147));
            playButton.setEnabled(true);
        } else {
            StringBuilder message = new StringBuilder("资源不完整，缺少：\n");
            for (String file : missing) message.append("• ").append(file).append('\n');
            statusText.setText(message.toString().trim());
            statusText.setTextColor(Color.rgb(255, 170, 120));
            playButton.setEnabled(false);
        }
    }

    private void startGame() {
        File gameDirectory = gameDirectory();
        if (!missingFiles(gameDirectory).isEmpty()) {
            refreshStatus();
            return;
        }
        Intent intent = new Intent(this, LASRecompActivity.class);
        intent.putExtra("game_directory", gameDirectory.getAbsolutePath());
        startActivity(intent);
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
