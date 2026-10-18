package com.lasrecomp.android;

import org.libsdl.app.SDLActivity;

public class LASRecompActivity extends SDLActivity {
    @Override
    protected String[] getArguments() {
        String gameDirectory = getIntent().getStringExtra("game_directory");
        return new String[] {gameDirectory == null ? "/sdcard/LASRecomp/extracted" : gameDirectory, "--play"};
    }
}
