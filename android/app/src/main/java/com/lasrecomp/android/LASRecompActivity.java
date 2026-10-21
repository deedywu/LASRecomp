package com.lasrecomp.android;

import android.os.Bundle;
import android.system.ErrnoException;
import android.system.Os;
import android.util.Log;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;

import org.libsdl.app.SDLActivity;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

public class LASRecompActivity extends SDLActivity {
    private static final String TAG = "LASRecomp";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        configureVulkanDriver();
        super.onCreate(savedInstanceState);
        enableImmersiveMode();
    }

    private void configureVulkanDriver() {
        try {
            Os.setenv("LARECOMP_NATIVE_LIB_DIR", getApplicationInfo().nativeLibraryDir, true);
            File directory = new File(getFilesDir(), "drivers/current");
            File marker = new File(directory, "selected.txt");
            String selected = marker.isFile() ? readText(marker).trim() : "";
            File library = selected.isEmpty() ? null : new File(directory, selected);
            String path = library != null && library.isFile() ? library.getAbsolutePath() : "";
            Os.setenv("LARECOMP_VK_DRIVER", path, true);
            Log.i(TAG, path.isEmpty() ? "Vulkan driver: system" : "Vulkan driver: " + path);
        } catch (ErrnoException | IOException error) {
            Log.e(TAG, "Vulkan driver setup failed; using system driver", error);
            try { Os.setenv("LARECOMP_VK_DRIVER", "", true); } catch (ErrnoException ignored) {}
        }
    }

    private static String readText(File file) throws IOException {
        try (InputStream input = new FileInputStream(file)) {
            return new String(input.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        enableImmersiveMode();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) enableImmersiveMode();
    }

    private void enableImmersiveMode() {
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().setDecorFitsSystemWindows(false);
        WindowManager.LayoutParams attributes = getWindow().getAttributes();
        attributes.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        getWindow().setAttributes(attributes);
        WindowInsetsController controller = getWindow().getInsetsController();
        if (controller != null) {
            controller.hide(WindowInsets.Type.statusBars() | WindowInsets.Type.navigationBars());
            controller.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
        }
        // MuMu and a few vendor Android builds still consult the legacy flags after the IME closes.
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_FULLSCREEN |
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY |
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN |
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION |
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
    }

    @Override
    protected String[] getArguments() {
        String gameDirectory = getIntent().getStringExtra("game_directory");
        String language = getIntent().getStringExtra("language");
        if (language == null || language.isEmpty()) language = "auto";
        return new String[] {gameDirectory == null ? "/sdcard/LASRecomp/extracted" : gameDirectory,
                "--play", "--language=" + language};
    }
}
