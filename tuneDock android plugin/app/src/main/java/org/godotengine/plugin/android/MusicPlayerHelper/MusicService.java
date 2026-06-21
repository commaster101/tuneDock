package org.godotengine.plugin.android.MusicPlayerHelper;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.net.Uri;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;
import androidx.media3.common.AudioAttributes;
import androidx.media3.common.C;
import androidx.media3.common.MediaItem;
import androidx.media3.common.MediaMetadata;
import androidx.media3.common.Player;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.session.MediaSession;

import java.io.File;

public class MusicService extends Service {
    private static final String TAG = "GODOT";
    private static final String CHANNEL_ID = "MusicServiceChannel";
    private static final int NOTIFICATION_ID = 101;

    public static final String ACTION_PLAY = "org.godotengine.plugin.android.MusicPlayerHelper.ACTION_PLAY";
    public static final String ACTION_PAUSE = "org.godotengine.plugin.android.MusicPlayerHelper.ACTION_PAUSE";

    public static final String ACTION_RESUME = "org.godotengine.plugin.android.MusicPlayerHelper.ACTION_RESUME";
    public static final String ACTION_STOP = "org.godotengine.plugin.android.MusicPlayerHelper.ACTION_STOP";
    public static final String ACTION_SEEK = "org.godotengine.plugin.android.MusicPlayerHelper.ACTION_SEEK";

    // Static reference so the Plugin can query position synchronously
    public static volatile MusicService instance;

    private ExoPlayer player;
    private MediaSession mediaSession;

    @Override
    public void onCreate() {
        super.onCreate();
        instance = this;
        Log.v(TAG, "MusicService: onCreate reached!");
        
        try {
            createNotificationChannel();

            Notification notification = createNotification("Initializing...");
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK);
            } else {
                startForeground(NOTIFICATION_ID, notification);
            }

            player = new ExoPlayer.Builder(this).build();
            player.addListener(new Player.Listener() {
                @Override
                public void onPlaybackStateChanged(int playbackState) {
                    if (playbackState == Player.STATE_ENDED) {
                        if (MusicPlayer.instance != null) {
                            MusicPlayer.instance.onSongFinished();
                        }
                    }
                }
            });
            
            AudioAttributes audioAttributes = new AudioAttributes.Builder()
                    .setUsage(C.USAGE_MEDIA)
                    .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
                    .build();
            player.setAudioAttributes(audioAttributes, true);

            mediaSession = new MediaSession.Builder(this, player)
                    .setId("MusicServiceSession")
                    .build();
            
            Log.v(TAG, "MusicService: Initialization complete.");
        } catch (Exception e) {
            Log.e(TAG, "MusicService: Error in onCreate: " + e.getMessage());
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null) {
            String action = intent.getAction();
            Log.v(TAG, "MusicService: Action: " + action);

            if (ACTION_PAUSE.equals(action)) {
                pauseMusic();
            }
            else if (ACTION_RESUME.equals(action)) {
                resumeMusic();
            } else if (ACTION_STOP.equals(action)) {
                stopMusic();
            } else if (ACTION_SEEK.equals(action)) {
                long pos = intent.getLongExtra("pos", 0);
                seekTo(pos);
            } else {
                String path = intent.getStringExtra("path");
                if (path != null) {
                    playFile(path);
                } else if (player != null && !player.isPlaying()) {
                    player.play();
                }
            }
        }
        return START_STICKY;
    }

    public long getCurrentPosition() {
        if (player == null) return 0;
        return player.getCurrentPosition();
    }

    public long getDuration() {
        if (player == null) return 0;
        long duration = player.getDuration();
        return (duration == C.TIME_UNSET) ? 0 : duration;
    }

    public boolean isPlaying() {
        return (player != null) && player.isPlaying();
    }

    private void seekTo(long pos) {
        if (player != null) {
            player.seekTo(pos);
        }
    }

    private void playFile(String path) {
        File file = new File(path);
        if (!file.exists()) {
            Toast.makeText(this, "File not found!", Toast.LENGTH_SHORT).show();
            return;
        }

        MediaItem item = new MediaItem.Builder()
                .setUri(Uri.fromFile(file))
                .setMediaMetadata(new MediaMetadata.Builder().setTitle(file.getName()).build())
                .build();

        player.setMediaItem(item);
        player.prepare();

        player.play();
        
        updateNotification("Playing: " + file.getName());
    }

    private void pauseMusic() {
        if (player != null) {
            player.pause();
            updateNotification("Paused");
        }
    }

    private void resumeMusic() {
        if (player != null) {
            player.play();
            updateNotification("Playing");
        }
    }
    private void stopMusic() {
        if (player != null) player.stop();
        stopForeground(STOP_FOREGROUND_REMOVE);
        stopSelf();
    }

    private void updateNotification(String content) {
        NotificationManager manager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        if (manager != null) {
            manager.notify(NOTIFICATION_ID, createNotification(content));
        }
    }

    private Notification createNotification(String content) {
        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Music Player")
                .setContentText(content)
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .setOngoing(true);

        try {
            Intent launchIntent = getPackageManager().getLaunchIntentForPackage(getPackageName());
            if (launchIntent != null) {
                PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, launchIntent, PendingIntent.FLAG_IMMUTABLE);
                builder.setContentIntent(pendingIntent);
            }
        } catch (Exception ignored) {}

        return builder.build();
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID, "Music Service", NotificationManager.IMPORTANCE_LOW);
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) manager.createNotificationChannel(channel);
        }
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) { return null; }

    @Override
    public void onDestroy() {
        Log.v(TAG, "MusicService: onDestroy");
        instance = null;
        if (mediaSession != null) mediaSession.release();
        if (player != null) player.release();
        super.onDestroy();
    }
}
