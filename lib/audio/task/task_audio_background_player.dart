import 'dart:async';
import 'package:audio_service/audio/player/audio_player_ijkplayer.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_ijkplayer/flutter_ijkplayer.dart';
import 'package:just_audio/just_audio.dart';

import 'task_audio_background_base.dart';
import 'package:audio_service/audio/media/audio_media_resource.dart';
import 'package:audio_service/audio/service/audio_service_background.dart';
import 'package:audio_service/audio/player/audio_player_interface.dart';

const CUSTOM_CMD_ADD_MP3_RES = "CUSTOM_CMD_ADD_MP3";

/// This task defines logic for playing a list of podcast episodes.
///
/// 音频后台任务播放处理器
/// 根据音频后台服务的播放控制回调，使用播放器实现具体的播放功能
class AudioPlayerBackgroundTask extends BackgroundAudioTask {

//  final _mediaLibrary = MediaLibrary();

  IjkAudioPlayer _player = IjkAudioPlayer(IjkMediaController());

  AudioProcessingState? _skipState;
  AudioProcessingState? _currentState = AudioProcessingState.none;
  Seeker? _seeker;
  late StreamSubscription<PlaybackEvent> _eventSubscription;
  late StreamSubscription<VideoInfo>? _audioInfoSubscription;
  late StreamSubscription<IjkStatus>? _audioStatusSubscription;

//  List<MediaItem> get queue => _mediaLibrary.items;

//  int? get index => _player.currentIndex;
//  int get index => 0;

  int index = 0;
  late List<MediaItem>? queue;
  late MediaItem _mMediaItem;


  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    // We configure the audio session for speech since we're playing a podcast.
    // You can also put this in your app's initialisation if your app doesn't
    // switch between two types of audio as this example does.
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
    // Broadcast audio.media item changes.
//    _player.currentIndexStream.listen((index) {
//      if (index != null) AudioServiceBackground.setMediaItem(queue[index]);
//    });
    // Propagate all events from the audio player to AudioService clients.
//    _eventSubscription = _player.playbackEventStream.listen((event) {
//      _broadcastState();
//    });
    // Special processing for state transitions.
//    _player.processingStateStream.listen((state) {
//      switch (state) {
//        case ProcessingState.completed:
//        // In this example, the service stops when reaching the end.
//          onStop();
//          break;
//        case ProcessingState.ready:
//        // If we just came from skipping between tracks, clear the skip
//        // state now that we're ready to play.
//          _skipState = null;
//          break;
//        default:
//          break;
//      }
//    });
    //音频播放信息
    _audioInfoSubscription = _player.videoInfoStream?.listen((event) {
      _broadcastPlayerState(info: event);
    });
    //音频播放状态
    _audioStatusSubscription = _player.statusStream?.listen((event) {
      switch (event) {
        case IjkStatus.preparing:
          _currentState = AudioProcessingState.connecting;
          break;
        case IjkStatus.prepared:
          _currentState = AudioProcessingState.ready;
          break;
        case IjkStatus.playing:
          _currentState = AudioProcessingState.ready;
          break;
        case IjkStatus.pause:
          _currentState = AudioProcessingState.ready;
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

  /// Maps just_audio's processing state into into audio_service's playing
  /// state. If we are in the middle of a skip, we use [_skipState] instead.
//  AudioProcessingState _getProcessingState() {
//    if (_skipState != null) return _skipState!;
//    switch (_player.processingState) {
//      case ProcessingState.idle:
//        return AudioProcessingState.stopped;
//      case ProcessingState.loading:
//        return AudioProcessingState.connecting;
//      case ProcessingState.buffering:
//        return AudioProcessingState.buffering;
//      case ProcessingState.ready:
//        return AudioProcessingState.ready;
//      case ProcessingState.completed:
//        return AudioProcessingState.completed;
//      default:
//        throw Exception("Invalid state: ${_player.processingState}");
//    }
//  }

  @override
  Future<void> onSkipToQueueItem(String mediaId) async {
    // Then default implementations of onSkipToNext and onSkipToPrevious will
    // delegate to this method.
    final newIndex = queue!.indexWhere((item) => item.id == mediaId);
    if (newIndex == -1) return;
    // During a skip, the player may enter the buffering state. We could just
    // propagate that state directly to AudioService clients but AudioService
    // has some more specific states we could use for skipping to next and
    // previous. This variable holds the preferred state to send instead of
    // buffering during a skip, and it is cleared as soon as the player exits
    // buffering (see the listener in onStart).

//    _skipState = newIndex > index
//        ? AudioProcessingState.skippingToNext
//        : AudioProcessingState.skippingToPrevious;
//    // This jumps to the beginning of the queue item at newIndex.
//    // TODO xiong -- 补充：Player.onSkipToQueueItem
//    _player.seek(Duration.zero, index: newIndex);

    // Demonstrate custom events.
    AudioServiceBackground.sendCustomEvent('skip to $newIndex');
  }

  @override
  Future<void> onPlay() => _player.play();

  @override
  Future<void> onPause() => _player.pause();

//  @override
//  Future<void> onPrepare() async {
//    if (queue.isEmpty) {
//      return Future(() => null);
//    }
//    return
//  }

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
  Future<dynamic> onCustomAction(String name, dynamic arguments) async {
    switch(name) {
      case CUSTOM_CMD_ADD_MP3_RES:
        print("xiong -- onCustomAction: CUSTOM_CMD_ADD_MP3_RES args = $arguments");
        String mp3_1 = arguments[0];//.cast<String>();
        String mp3_2 = arguments[1];//.cast<String>();
        print("xiong -- onCustomAction: CUSTOM_CMD_ADD_MP3_RES args = $arguments, param1 = $mp3_1, param2 = $mp3_2");
//        List<String> ids = arguments as List<String>;
        _player.setNetworkDataSource(mp3_1);
        onPlay();

//        queue = arguments as List<MediaItem>;
//        if (queue == null || index >= queue!.length) {
//          return;
//        }
//        _mMediaItem = queue![index];
//        // Load and broadcast the queue
//        await AudioServiceBackground.setQueue(queue!);
//        await AudioServiceBackground.setMediaItem(_mMediaItem);
//        try {
//          _player.setNetworkDataSource(_mMediaItem.id);
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
//    _eventSubscription.cancel();
    _audioInfoSubscription?.cancel();
    _audioStatusSubscription?.cancel();
    // It is important to wait for this state to be broadcast before we shut
    // down the audio.task. If we don't, the background audio.task will be destroyed before
    // the message gets sent to the UI.
//    await _broadcastState();
    await _broadcastPlayerState();
    // Shut down this audio.task
    await super.onStop();
  }

  /// Jumps away from the current position by [offset].
  Future<void> _seekRelative(Duration offset) async {
    var currPos = await _player.getCurrentPosition();
    var newPosition = currPos + offset;
    // Make sure we don't jump out of bounds.
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    if (newPosition > _mMediaItem.duration!) newPosition = _mMediaItem.duration!;
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
          Duration(seconds: 1), _mMediaItem)
        ..start();
    }
  }

//  /// Broadcasts the current state to all clients.
//  Future<void> _broadcastState() async {
//    await AudioServiceBackground.setState(
//      controls: [
//        MediaControl.skipToPrevious,
//        if (_player.isPlaying()) MediaControl.pause else
//          MediaControl.play,
//        MediaControl.stop,
//        MediaControl.skipToNext,
//      ],
//      systemActions: [
//        MediaAction.seekTo,
//        MediaAction.seekForward,
//        MediaAction.seekBackward,
//      ],
//      androidCompactActions: [0, 1, 3],
//      processingState: _getProcessingState(),
//      playing: _player.isPlaying(),
//      position: await _player.getCurrentPosition(),
////      bufferedPosition: _player.bufferedPosition,
//      speed: _player.getSpeed(),
//    );
//  }

  /// Broadcasts the current state to all clients.
  Future<void> _broadcastPlayerState({VideoInfo? info}) async {
    await AudioServiceBackground.updateNotificationState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.isPlaying()) MediaControl.pause else
          MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: [
        MediaAction.seekTo,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      ],
      androidCompactActions: [0, 1, 3],
      processingState: _currentState,
      playing: info?.isPlaying ?? _player.isPlaying(),
      position: info == null ? await _player.getCurrentPosition()
          : Duration(milliseconds: (info.currentPosition ?? 0).toInt()),
//      bufferedPosition: _player.bufferedPosition,
      speed: _player.getSpeed(),
    );
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