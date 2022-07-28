package com.ryanheise.audioservice;

import static android.content.Intent.ACTION_MEDIA_BUTTON;
import static com.ryanheise.audioservice.MediaButtonReceiver.ACTION_NOTIFICATION_DELETE;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.support.v4.media.session.PlaybackStateCompat;
import android.view.KeyEvent;

/**
 * @author xiong
 * @since 2022/4/1
 * @description 通知栏PendingIntent管理器（适配Android 12）
 **/
class NotificationPendingManager {

    private static final int REQUEST_CONTENT_INTENT = 1000;
    public static final int KEYCODE_BYPASS_PLAY = KeyEvent.KEYCODE_MUTE;
    public static final int KEYCODE_BYPASS_PAUSE = KeyEvent.KEYCODE_MEDIA_RECORD;

    /**
     * 构建PendingIntent：发送事件Action触发跳转Activity
     * @param activity  需跳转的Activity
     * @param action    响应Action
     */
    static PendingIntent buildCustomActionJumpActivityPendingIntent(Activity activity, String action) {
        Context context = activity.getApplicationContext();
        Intent intent = new Intent(context, activity.getClass());
        intent.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
        intent.setAction(action);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return PendingIntent.getActivity(context, REQUEST_CONTENT_INTENT, intent, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
        } else {
            return PendingIntent.getActivity(context, REQUEST_CONTENT_INTENT, intent, PendingIntent.FLAG_UPDATE_CURRENT);
        }
    }

    /**
     * 构建PendingIntent：发送PlaybackStateCompat支持的MediaKeyAction事件到广播
     * @param action    响应Action（具体参考 PlaybackStateCompat.MediaKeyAction）
     */
    static PendingIntent buildMediaKeyActionToBroadcastPendingIntent(Context context, long action) {
        int keyCode = toKeyCode(action);
        if (keyCode == KeyEvent.KEYCODE_UNKNOWN)
            return null;
        Intent intent = new Intent(context, MediaButtonReceiver.class);
        intent.setAction(ACTION_MEDIA_BUTTON);
        intent.putExtra(Intent.EXTRA_KEY_EVENT, new KeyEvent(KeyEvent.ACTION_DOWN, keyCode));
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return PendingIntent.getBroadcast(context, keyCode, intent, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
        } else {
            return PendingIntent.getBroadcast(context, keyCode, intent, PendingIntent.FLAG_UPDATE_CURRENT);
        }
    }

    /**
     * 构建PendingIntent：发送自定义的Action到广播
     * @param action        响应Action（自定义Action，对应于 MediaButtonReceiver 中处理自定义Action）
     * @param pendingFlag   参考 PendingIntent.Flags（适配Android 12）
     */
    static PendingIntent buildCustomActionToBroadcastPendingIntent(Context context, String action, int pendingFlag) {
        Intent intent = new Intent(context, MediaButtonReceiver.class);
        intent.setAction(action);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_IMMUTABLE | pendingFlag);
        } else {
            return PendingIntent.getBroadcast(context, 0, intent, pendingFlag);
        }
    }

    /**
     * 创建MediaSession的 PendingIntent
     */
    static PendingIntent buildCreateMediaSessionPendingIntent(Context context) {
        return buildCustomActionToBroadcastPendingIntent(context, ACTION_MEDIA_BUTTON, 0);
    }

    /**
     * 删除通知栏的 PendingIntent
     */
    static PendingIntent buildDeleteNotificationPendingIntent(Context context) {
        return buildCustomActionToBroadcastPendingIntent(context, ACTION_NOTIFICATION_DELETE, PendingIntent.FLAG_ONE_SHOT);
    }

    private static int toKeyCode(long action) {
        if (action == PlaybackStateCompat.ACTION_PLAY) {
            return KEYCODE_BYPASS_PLAY;
        } else if (action == PlaybackStateCompat.ACTION_PAUSE) {
            return KEYCODE_BYPASS_PAUSE;
        } else {
            return PlaybackStateCompat.toKeyCode(action);
        }
    }
}
