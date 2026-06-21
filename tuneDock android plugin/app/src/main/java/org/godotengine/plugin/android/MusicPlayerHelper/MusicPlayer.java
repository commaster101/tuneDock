package org.godotengine.plugin.android.MusicPlayerHelper;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;
import org.godotengine.godot.plugin.SignalInfo;

import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.database.Cursor;
import android.provider.MediaStore;
import java.io.File;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import android.os.Environment;

public class MusicPlayer extends GodotPlugin {
    private static final String TAG = "GODOT";
    public static MusicPlayer instance;

    public MusicPlayer(Godot godot) {
        super(godot);
        instance = this;
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "MusicPlayer";
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("song_finished"));
        return signals;
    }

    public void onSongFinished() {
        emitSignal("song_finished");
    }

    @UsedByGodot
    public void play(String path) {
        Activity activity = getActivity();
        if (activity == null) return;
        
        Intent intent = new Intent();
        intent.setClassName(activity.getPackageName(), "org.godotengine.plugin.android.MusicPlayerHelper.MusicService");
        intent.setAction(MusicService.ACTION_PLAY);
        intent.putExtra("path", path);

        try {
            ContextCompat.startForegroundService(activity, intent);
        } catch (Exception e) {
            Log.e(TAG, "Play failed: ", e);
        }
    }

    @UsedByGodot
    public void pause() {
        Activity activity = getActivity();
        if (activity == null) return;

        Intent intent = new Intent();
        intent.setClassName(activity.getPackageName(), "org.godotengine.plugin.android.MusicPlayerHelper.MusicService");
        intent.setAction(MusicService.ACTION_PAUSE);
        activity.startService(intent);
    }

    @UsedByGodot
    public void resume() {
        Activity activity = getActivity();
        if (activity == null) return;

        Intent intent = new Intent();
        intent.setClassName(activity.getPackageName(), "org.godotengine.plugin.android.MusicPlayerHelper.MusicService");
        intent.setAction(MusicService.ACTION_RESUME);
        activity.startService(intent);
    }

    @UsedByGodot
    public void stop() {
        Activity activity = getActivity();
        if (activity == null) return;

        Intent intent = new Intent();
        intent.setClassName(activity.getPackageName(), "org.godotengine.plugin.android.MusicPlayerHelper.MusicService");
        intent.setAction(MusicService.ACTION_STOP);
        activity.startService(intent);
    }

    @UsedByGodot
    public void seek(float pos_s) {
        long pos_ms = (long)(pos_s * 1000);
        Activity activity = getActivity();
        if (activity == null) return;

        Intent intent = new Intent();
        intent.setClassName(activity.getPackageName(), "org.godotengine.plugin.android.MusicPlayerHelper.MusicService");
        intent.setAction(MusicService.ACTION_SEEK);
        intent.putExtra("pos", pos_ms);
        activity.startService(intent);
    }

    @UsedByGodot
    public float get_position() {
        if (MusicService.instance == null) return 0;

        final long[] result = {0};
        final CountDownLatch latch = new CountDownLatch(1);
        Activity activity = getActivity();
        if (activity == null) return 0;

        activity.runOnUiThread(() -> {
            if (MusicService.instance != null) {
                result[0] = MusicService.instance.getCurrentPosition();
            }
            latch.countDown();
        });

        try {
            latch.await(200, TimeUnit.MILLISECONDS);
        } catch (InterruptedException e) {
            Log.e(TAG, "get_position interrupted", e);
        }
        return (float)result[0] / 1000f;
    }

    @UsedByGodot
    public float get_duration() {
        if (MusicService.instance == null) return 0;

        final long[] result = {0};
        final CountDownLatch latch = new CountDownLatch(1);
        Activity activity = getActivity();
        if (activity == null) return 0;

        activity.runOnUiThread(() -> {
            if (MusicService.instance != null) {
                result[0] = MusicService.instance.getDuration();
            }
            latch.countDown();
        });

        try {
            latch.await(200, TimeUnit.MILLISECONDS);
        } catch (InterruptedException e) {
            Log.e(TAG, "get_duration interrupted", e);
        }
        return (float)result[0] / 1000f;
    }

    @UsedByGodot
    public boolean is_paused() {
        if (MusicService.instance == null) return true;

        final boolean[] result = {true};
        final CountDownLatch latch = new CountDownLatch(1);
        Activity activity = getActivity();
        if (activity == null) return true;

        activity.runOnUiThread(() -> {
            if (MusicService.instance != null) {
                result[0] = !MusicService.instance.isPlaying();
            }
            latch.countDown();
        });

        try {
            latch.await(200, TimeUnit.MILLISECONDS);
        } catch (InterruptedException e) {
            Log.e(TAG, "is_paused interrupted", e);
        }
        return result[0];
    }

    @UsedByGodot
    public void helloWorld() {
        Activity activity = getActivity();
        if (activity != null) {
            activity.runOnUiThread(() -> Toast.makeText(activity, "plugin loaded!", Toast.LENGTH_SHORT).show());
        }
    }

    @UsedByGodot
    public String get_music_dir() {
        File musicDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC);
        return musicDir.getAbsolutePath();
    }

    @UsedByGodot
    public String resolve_content_uri(String uriString) {
        if (uriString == null || !uriString.startsWith("content://")) return uriString;

        Activity activity = getActivity();
        if (activity == null) return uriString;

        try {
            Uri uri = Uri.parse(uriString);

            // 1. Handle Storage Access Framework (SAF) URIs (Document/Tree pickers)
            if (uriString.contains("com.android.externalstorage.documents")) {
                String docId = "";
                // If it's a tree URI (directory)
                if (uriString.contains("/tree/")) {
                    String[] parts = uriString.split("/tree/");
                    if (parts.length > 1) {
                        docId = Uri.decode(parts[1]);
                    }
                }
                // If it's a document URI (file)
                else if (android.provider.DocumentsContract.isDocumentUri(activity, uri)) {
                    docId = android.provider.DocumentsContract.getDocumentId(uri);
                }

                if (docId.startsWith("primary:")) {
                    return Environment.getExternalStorageDirectory().getAbsolutePath() + "/" + docId.substring(8);
                }
            }

            // 2. Fallback to standard MediaStore query for other content:// URIs
            String[] projection = {MediaStore.MediaColumns.DATA};
            try (Cursor cursor = activity.getContentResolver().query(uri, projection, null, null, null)) {
                if (cursor != null && cursor.moveToFirst()) {
                    int index = cursor.getColumnIndex(MediaStore.MediaColumns.DATA);
                    if (index != -1) {
                        return cursor.getString(index);
                    }
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error resolving content URI: " + uriString, e);
        }
        return uriString;
    }

    @UsedByGodot
    public byte[] get_embedded_artwork(String path) {
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            retriever.setDataSource(path);
            byte[] art = retriever.getEmbeddedPicture();
            retriever.release();
            return (art != null) ? art : new byte[0];
        } catch (Exception e) {
            Log.e(TAG, "Error getting embedded art: " + path, e);
            try { retriever.release(); } catch (Exception ignored) {}
            return new byte[0];
        }
    }
}
