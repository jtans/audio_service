package com.ryanheise.audioserviceexample;

import android.content.Intent;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.ryanheise.audioservice.AudioServicePlugin;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;

import static com.ryanheise.audioservice.AudioServicePlugin.NOTIFICATION_CLICK_ACTION;

public class MainActivity extends FlutterActivity {

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Intent intent = getIntent();
        String action = intent.getAction();
        Log.d("xiong", "MainActivity onCreate");

        if (action != null && action.equals(NOTIFICATION_CLICK_ACTION)) {
            Log.d("xiong", "音频通知栏点击跳转");
            AudioServicePlugin.handleNotificationClick(this);
        }
    }

}
