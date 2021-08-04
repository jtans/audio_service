package com.ryanheise.audioservice;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.fragment.app.FragmentActivity;
import androidx.fragment.app.FragmentManager;

import com.ryanheise.audioservice.R;

import io.flutter.embedding.android.FlutterFragment;

/**
 * @author xiong
 * @description 音频播放Fragment（包装Flutter的音频）
 * @since   2021/8/4
 * TODO xiong -- fix：这种方式调起的音频页不会同步播放状态
 **/
public class AudioFragmentActivity extends FragmentActivity {

    private static final String TAG_FLUTTER_FRAGMENT = "flutter_fragment";

    private FlutterFragment flutterFragment;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Log.d("xiong", "AudioFragmentActivity onCreate");
        // Inflate a layout that has a container for your FlutterFragment.
        // For this example, assume that a FrameLayout exists with an ID of
        // R.id.fragment_container.
        setContentView(R.layout.activity_audio_player);

        // Get a reference to the Activity's FragmentManager to add a new
        // FlutterFragment, or find an existing one.
        FragmentManager fragmentManager = getSupportFragmentManager();

        // Attempt to find an existing FlutterFragment,
        // in case this is not the first time that onCreate() was run.
        flutterFragment = (FlutterFragment) fragmentManager
                .findFragmentByTag(TAG_FLUTTER_FRAGMENT);
        Log.d("xiong", "AudioFragmentActivity show flutterFragment = " + (flutterFragment == null));

        // Create and attach a FlutterFragment if one does not exist.
        if (flutterFragment == null) {
            flutterFragment = FlutterFragment.withNewEngine().initialRoute("/page_audio").build();

            fragmentManager
                    .beginTransaction()
                    .add(
                            R.id.fl_container,
                            flutterFragment,
                            TAG_FLUTTER_FRAGMENT
                    )
                    .commit();
        }
    }

    @Override
    public void onPostResume() {
        super.onPostResume();
        flutterFragment.onPostResume();
    }

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        flutterFragment.onNewIntent(intent);
    }

    @Override
    public void onBackPressed() {
        flutterFragment.onBackPressed();
    }

    @Override
    public void onRequestPermissionsResult(
            int requestCode,
            @NonNull String[] permissions,
            @NonNull int[] grantResults
    ) {
        flutterFragment.onRequestPermissionsResult(
                requestCode,
                permissions,
                grantResults
        );
    }

    @Override
    public void onUserLeaveHint() {
        flutterFragment.onUserLeaveHint();
    }

    @Override
    public void onTrimMemory(int level) {
        super.onTrimMemory(level);
        flutterFragment.onTrimMemory(level);
    }
}
