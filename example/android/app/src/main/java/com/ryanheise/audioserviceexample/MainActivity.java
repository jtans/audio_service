package com.ryanheise.audioserviceexample;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.ryanheise.audioservice.AudioServicePlugin;

import io.flutter.FlutterInjector;
import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterNativeView;

import static com.ryanheise.audioservice.AudioServicePlugin.NOTIFICATION_CLICK_ACTION;

public class MainActivity extends FlutterActivity {

    private FrameLayout fl_container;
    private Button btn_jump_audio;
    private FlutterEngine flutterEngine;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
//        setContentView(R.layout.activity_main_container);

        Intent intent = getIntent();
        String action = intent.getAction();
        Log.d("xiong", "MainActivity onCreate");

        if (action != null && action.equals(NOTIFICATION_CLICK_ACTION)) {
            setContentView(R.layout.activity_main_container);
            Log.d("xiong", "音频通知栏点击跳转");
            showFlutterAudioPage();
//            AudioServicePlugin.handleNotificationClick(this);
//        }
        } else {
            Log.d("xiong", "非音频通知栏点击跳转");
            showFlutterMainPage();
        }
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        if (AudioServicePlugin.backgroundFlutterEngine != null) {
            this.flutterEngine = AudioServicePlugin.backgroundFlutterEngine;
            this.flutterEngine.getNavigationChannel().setInitialRoute("/page_audio");

        }
        super.configureFlutterEngine(flutterEngine);
        Log.d("xiong", "MainActivity configureFlutterEngine");
    }


    private void showFlutterMainPage() {
        if (AudioServicePlugin.backgroundFlutterEngine != null) {
            AudioServicePlugin.backgroundFlutterEngine.getDartExecutor().executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault());
        }
        Log.d("xiong", "MainActivity showFlutterMainPage");
    }

    private void showFlutterAudioPage() {
//        AudioServicePlugin.loadAudioPlayPage();

        //TODO xiong -- 加载 Flutter 音频页
        if (fl_container == null) {
            fl_container = findViewById(R.id.fl_container);
            btn_jump_audio = findViewById(R.id.btn_go_audio_page);
//            btn_jump_audio.setOnClickListener(new View.OnClickListener() {
//                @Override
//                public void onClick(View v) {
//                    startActivity(MainActivity.withNewEngine().initialRoute("/page_audio").build(MainActivity.this));
//                }
//            });
        }

        if (AudioServicePlugin.backgroundFlutterEngine != null) {
//            AudioServicePlugin.backgroundFlutterEngine.getNavigationChannel().setInitialRoute("/page_audio");
            FlutterView flutterView = new FlutterView(this);
            FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT);
            fl_container.addView(flutterView, lp);
            AudioServicePlugin.backgroundFlutterEngine.getDartExecutor().executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
            );
            flutterView.attachToFlutterEngine(AudioServicePlugin.backgroundFlutterEngine);
        }
        Log.d("xiong", "MainActivity showFlutterAudioPage");
    }

}
