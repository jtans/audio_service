package com.ryanheise.audioserviceexample;

import android.content.Intent;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.ryanheise.audioservice.AudioServicePlugin;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

import static com.ryanheise.audioservice.AudioServicePlugin.NOTIFICATION_CLICK_ACTION;

public class MainActivity extends FlutterActivity {

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
//        setContentView(R.layout.activity_main_container);
        Log.d("xiong", "MainActivity onCreate");

//        handleIntentExtra();
    }

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        Log.d("xiong", "MainActivity onNewIntent");
        handleIntentExtra();
    }

    private void handleIntentExtra() {
        Intent intent = getIntent();
        String action = intent.getAction();
        if (action != null && action.equals(NOTIFICATION_CLICK_ACTION)) {
            Log.d("xiong", "MainActivity 收到音频通知栏点击事件");
            AudioServicePlugin.handleNotificationClick(this);
//            jumpFlutterAudioPage();
//            finish();
        }
    }

    // See: https://stackoverflow.com/questions/13135545/android-activity-is-using-old-intent-if-launching-app-from-recent-task
    protected boolean wasLaunchedFromRecents() {
        return (getIntent().getFlags() & Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) == Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY;
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        Log.d("xiong", "MainActivity configureFlutterEngine");
    }

    //说明：跳转 Flutter音频页（会启动两次main）
    private void jumpFlutterAudioPage() {
        startActivity(FlutterActivity.withNewEngine().initialRoute("/page_audio").build(MainActivity.this));
    }

}
