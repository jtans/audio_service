import 'dart:async';
import 'package:audio_service/audio/converter/audio_media_type_converter.dart';
import 'package:audio_service/audio/player/audio_player_ijkplayer.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_ijkplayer/flutter_ijkplayer.dart';

import 'audio_service_background.dart';
import 'task_audio_background_base.dart';
import 'package:audio_service/audio/media/audio_media_resource.dart';
import 'package:audio_service/audio/player/audio_player_interface.dart';

const CUSTOM_CMD_ADD_MP3_RES = "CUSTOM_CMD_ADD_MP3";
const EXTRA_PLAYER_DURATION = 'extra_player_duration';

/// This task defines logic for playing a list of podcast episodes.
///
/// 音频后台任务播放处理器
/// 根据音频后台服务的播放控制回调，使用播放器实现具体的播放功能
class AudioPlayerBackgroundTask extends BackgroundAudioTask<MediaItem> {

  AudioPlayerBackgroundTask() {
    mMediaTypeConverter = AudioMediaTypeConverter();
  }

  IjkAudioPlayer _player = IjkAudioPlayer(IjkMediaController());

  AudioProcessingState? _currentState = AudioProcessingState.none;
  Seeker? _seeker;
  Timer? _positionTimer;
  late StreamSubscription<VideoInfo>? _audioInfoSubscription;
  late StreamSubscription<IjkStatus>? _audioStatusSubscription;

  int index = 0;
  // late List<MediaItem>? queue;
  // late MediaItem mMediaItem;


  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    // We configure the audio session for speech since we're playing a podcast.
    // You can also put this in your app's initialisation if your app doesn't
    // switch between two types of audio as this example does.
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());

    //音频播放信息
    _audioInfoSubscription = _player.videoInfoStream?.listen((event) {
      _player.getDuration().then((value) {
        _broadcastPlayerState(info: event, extra: {EXTRA_PLAYER_DURATION : value.inSeconds});
      });
    });
    //音频播放状态
    _audioStatusSubscription = _player.statusStream?.listen((event) {
      switch (event) {
        case IjkStatus.preparing:
          _currentState = AudioProcessingState.buffering;
          break;
        case IjkStatus.prepared:
          _currentState = AudioProcessingState.ready;
          // 每500ms更新一次播放状态
          startQueryPosition(Duration(milliseconds: 800));

          //TODO xiong -- test: 测试播放总长度是否会被 extras = null 覆盖
          // _player.getDuration().then((value) =>
          //     _broadcastPlayerState(extra: {EXTRA_PLAYER_DURATION : value.inSeconds})
          // );
          break;
        case IjkStatus.playing:
          _currentState = AudioProcessingState.playing;
          break;
        case IjkStatus.pause:
          _currentState = AudioProcessingState.pause;
          break;
        case IjkStatus.complete:
          _currentState = AudioProcessingState.completed;
          break;
        case IjkStatus.disposed:
          _currentState = AudioProcessingState.stopped;
          break;
        case IjkStatus.error:
          _currentState = AudioProcessingState.error;
          break;
        default:
          _currentState = AudioProcessingState.none;
          break;
      }
    });
  }

  @override
  Future<void> onPlay() => _player.play();

  @override
  Future<void> onPause() => _player.pause();

  @override
  Future<void> onSeekTo(Duration position) => _player.seekTo(position);

  @override
  Future<void> onFastForward() => _seekRelative(fastForwardInterval);

  @override
  Future<void> onRewind() => _seekRelative(-rewindInterval);

  @override
  Future<void> onSeekForward(bool begin) async => _seekContinuously(begin, 1);

  @override
  Future<void> onSeekBackward(bool begin) async => _seekContinuously(begin, -1);

  @override
  Future<void> skip(int offset) async {
    if (mMediaItem == null) return;
    int i = mMediaQueue.indexOf(mMediaItem);
    if (i == -1) return;
    int newIndex = i + offset;
    if (newIndex >= 0 && newIndex < mMediaQueue.length)
      await onSkipToQueueItem(getMediaId(mMediaQueue[newIndex]));
  }

  @override
  Future<dynamic> onCustomAction(String name, dynamic arguments) async {
    switch(name) {
      case CUSTOM_CMD_ADD_MP3_RES:
        String mp3_1 = arguments[0];
        String mp3_2 = arguments[1];
        print("xiong -- onCustomAction: CUSTOM_CMD_ADD_MP3_RES args = $arguments, param1 = $mp3_1, param2 = $mp3_2");
       // List<String> ids = arguments as List<String>;
        await _player.setNetworkDataSource(mp3_1);

        onPlay();

//        queue = arguments as List<MediaItem>;
//        if (queue == null || index >= queue!.length) {
//          return;
//        }
//        mMediaItem = queue![index];
//        // Load and broadcast the queue
//        await AudioServiceBackground.setQueue(queue!);
//        await AudioServiceBackground.setMediaItem(mMediaItem);
//        try {
//          _player.setNetworkDataSource(mMediaItem.id);
//          onPlay();
//        } catch (e) {
//          print("Error: $e");
//          onStop();
//        }

//        // Load and broadcast the queue
//        AudioServiceBackground.setQueue(queue);
//        try {
//          await _player.setAudioSource(ConcatenatingAudioSource(
//            children:
//            queue.map((item) => AudioSource.uri(Uri.parse(item.id))).toList(),
//          ));
//          // In this example, we automatically start playing on start.
//          onPlay();
//        } catch (e) {
//          print("Error: $e");
//          onStop();
//        }
        break;
    }
  }

  @override
  Future<void> onStop() async {
    await _player.stop();
    _audioInfoSubscription?.cancel();
    _audioStatusSubscription?.cancel();
    _positionTimer?.cancel();
    await _broadcastPlayerState();
    // Shut down this audio.task
    await super.onStop();
  }

  void startQueryPosition(Duration step) {
    _positionTimer = Timer.periodic(step, (timer) {
      print("xiong -- timer call _broadcastPlayerState");
      _player.mediaController.refreshVideoInfo();
      // _player.getDuration().then((value) {
        // print("xiong -- timer call _broadcastPlayerState duration = $value");
        // _broadcastPlayerState(info: _player.mediaController.videoInfo,
        //     extra: {EXTRA_PLAYER_DURATION : value.inSeconds},
        //     needUpdateNotification: false);
      // });
    });
  }

  /// Jumps away from the current position by [offset].
  Future<void> _seekRelative(Duration offset) async {
    var currPos = await _player.getCurrentPosition();
    var newPosition = currPos + offset;
    // Make sure we don't jump out of bounds.
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    if (newPosition > mMediaItem.duration!) newPosition = mMediaItem.duration!;
    // Perform the jump via a seek.
    await _player.seekTo(newPosition);
  }

  /// Begins or stops a continuous seek in [direction]. After it begins it will
  /// continue seeking forward or backward by 10 seconds within the audio, at
  /// intervals of 1 second in app time.
  void _seekContinuously(bool begin, int direction) {
    _seeker?.stop();
    if (begin) {
      _seeker = Seeker(_player, Duration(seconds: 10 * direction),
          Duration(seconds: 1), mMediaItem)
        ..start();
    }
  }

  /// Broadcasts the current state to all clients.
  /// [extra] -- 需额外传输的数据（TODO xiong -- fix: extra为空的话接收端会接收失败）
  Future<void> _broadcastPlayerState({VideoInfo? info, Map<String, dynamic>? extra, bool? needUpdateNotification}) async {
    await AudioServiceBackground.instance.setPlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.isPlaying()) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      // systemActions: [
      //   MediaAction.seekTo,
      //   MediaAction.seekForward,
      //   MediaAction.seekBackward,
      // ],
      androidCompactActions: [0, 1, 2],
      processingState: _currentState,
      playing: info?.isPlaying ?? _player.isPlaying(),
      position: info == null ? await _player.getCurrentPosition()
          : Duration(seconds: (info.currentPosition ?? 0).toInt()),
//      bufferedPosition: _player.bufferedPosition,
      speed: _player.getSpeed(),
      extras: extra,
      needUpdateNotification: needUpdateNotification ?? true,
    );
  }

  @override
  String getMediaId(MediaItem mediaItem) {
    return mediaItem.id;
  }

}

class Seeker {
  final IAudioPlayer player;
  final Duration positionInterval;
  final Duration stepInterval;
  final MediaItem mediaItem;
  bool _running = false;

  Seeker(this.player,
      this.positionInterval,
      this.stepInterval,
      this.mediaItem,);

  start() async {
    _running = true;
    while (_running) {
      Duration newPosition = await player.getCurrentPosition() +
          positionInterval;
      if (newPosition < Duration.zero) newPosition = Duration.zero;
      if (newPosition > mediaItem.duration!) newPosition = mediaItem.duration!;
      player.seekTo(newPosition);
      await Future.delayed(stepInterval);
    }
  }

  stop() {
    _running = false;
  }
}