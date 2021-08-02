import 'dart:async';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:ui';

import 'package:audio_service/audio/media/audio_media_resource.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_isolate/flutter_isolate.dart';

import '../controller/audio_service_controller.dart';
import 'task_audio_background_base.dart';

/// Background API to be used by your background audio audio.task.
///
/// The entry point of your background audio.task that you passed to
/// [AudioServiceController.start] is executed in an isolate that will run independently
/// of the view. Aside from its primary job of playing audio, your background
/// audio.task should also use methods of this class to initialise the isolate,
/// broadcast state changes to any UI that may be connected, and to also handle
/// playback actions initiated by the UI.
///
/// 音频后台服务
/// 主要响应播放界面的各播放功能按钮（如播放、上一节、下一节等），服务端接收到相应回调，进行播放相关功能处理
/// 具体的播放相关功能交由 BackgroundAudioTask 进行处理
const String MEDIA_ROOT_ID = "media_root_id";
class AudioServiceBackground {

  AudioServiceBackground._privateConstructor();
  static final AudioServiceBackground _instance = AudioServiceBackground._privateConstructor();
  // static AudioServiceBackground get instance { return _instance;}
  factory AudioServiceBackground() => _instance;


  static final PlaybackState noneState = PlaybackState(
    processingState: AudioProcessingState.none,
    playing: false,
    actions: Set(),
    position: Duration.zero,
    bufferedPosition: Duration.zero,
    speed: 1.0,
    updateTime: DateTime.fromMillisecondsSinceEpoch(0),
    repeatMode: AudioServiceRepeatMode.none,
    shuffleMode: AudioServiceShuffleMode.none,
    // extras: null,
  );
  static late MethodChannel _backgroundChannel;
  static PlaybackState _state = noneState;
  List<MediaControl> _controls = [];
  List<MediaAction> _systemActions = [];
  // T? _mediaItem;
  // List<T>? _queue;
  static BaseCacheManager? _cacheManager;
  static late BackgroundAudioTask _task;
  static bool _running = false;

  /// Completes when the audio.task is shut down.
  static late Completer<dynamic> _taskCompleter;

  /// Completes when the last method call (other than onStop) in progress has
  /// completed.
  static late Completer<dynamic> _inProgressCompleter;

  static int _inProgressMethodCount = 0;

  /// The current audio.media playback state.
  ///
  /// This is the value most recently set via [setState].
  static PlaybackState get state => _state;

  /// The current audio.media item.
  ///
  /// This is the value most recently set via [setMediaItem].
  // T? get mediaItem => _mediaItem;

  /// The current queue.
  ///
  /// This is the value most recently set via [setQueue].
  // List<T>? get queue => _queue;

  /// Runs the background audio audio.task within the background isolate.
  ///
  /// This must be the first method called by the entrypoint of your background
  /// audio.task that you passed into [AudioServiceController.start]. The [BackgroundAudioTask]
  /// returned by the [taskBuilder] parameter defines callbacks to handle the
  /// initialization and distruction of the background audio audio.task, as well as
  /// any requests by the client to play, pause and otherwise control audio
  /// playback.
  Future<void> run(BackgroundAudioTask taskBuilder()) async {
    _running = true;
    _taskCompleter = Completer();
    _inProgressCompleter = Completer();
    _backgroundChannel =
        const MethodChannel('ryanheise.com/audioServiceBackground');
    WidgetsFlutterBinding.ensureInitialized();
    _task = taskBuilder();
    _cacheManager = _task.cacheManager;
    final handler = (MethodCall call) async {
      if (!_running) return;
      try {
        if (call.method == 'onStop') {
          return await _task.onStop();
        } else {
          _inProgressMethodCount++;
          try {
            final result = await Future.any<dynamic>([
              _taskCompleter.future,
              _handleNonStopMethod(call),
            ]);
            return result;
          } finally {
            _inProgressMethodCount--;
            // Note: Since we check !_running here, it is important that the
            // listener of _inProgressCompleter set _running to false before
            // listening. See _shutdown.
            if (!_running && _inProgressMethodCount <= 0) {
              _inProgressCompleter.complete();
            }
          }
        }
      } catch (e, stacktrace) {
        throw PlatformException(code: '$e', stacktrace: stacktrace.toString());
      }
    };
    // Mock method call handlers only work in one direction so we need to set up
    // a separate channel for each direction when testing.
    if (testMode) {
      MethodChannel('ryanheise.com/audioServiceBackgroundInverse')
          .setMockMethodCallHandler(handler);
    } else {
      _backgroundChannel.setMethodCallHandler(handler);
    }
    Map startParams = (await (_backgroundChannel.invokeMethod<Map>('ready')))!;
    Duration fastForwardInterval =
        Duration(milliseconds: startParams['fastForwardInterval']);
    Duration rewindInterval =
        Duration(milliseconds: startParams['rewindInterval']);
    Map<String, dynamic>? params =
        startParams['params']?.cast<String, dynamic>();
    _task.setParams(
      fastForwardInterval: fastForwardInterval,
      rewindInterval: rewindInterval,
    );
    try {
      await _task.onStart(params);
    } catch (e) {} finally {
      // For now, we return successfully from AudioServiceController.start regardless of
      // whether an exception occurred in onStart.
      await _backgroundChannel.invokeMethod('started');
      if (!AudioServiceController.usesIsolate) {
        AudioServiceController.startedNonIsolate();
      }
    }
  }

  /// Handle methods other than onStop.
  Future<dynamic> _handleNonStopMethod(MethodCall call) async {
    switch (call.method) {
      case 'onLoadChildren':
        final List args = call.arguments;
        String parentMediaId = args[0];
        List<dynamic> list = await _task.onLoadChildren(parentMediaId);
        List rawMediaItems = _task.convertMediaItemListToRawList(list);
        print("xiong -- AudioService onLoadChildren parentMediaId = $parentMediaId, mediaItems = $rawMediaItems");
        return rawMediaItems as dynamic;
      case 'onClick':
        final List args = call.arguments;
        MediaButton button = MediaButton.values[args[0]];
        return await _task.onClick(button);
      case 'onPause':
        return await _task.onPause();
      case 'onPrepare':
        return await _task.onPrepare();
      case 'onPrepareFromMediaId':
        final List args = call.arguments;
        String mediaId = args[0];
        return await _task.onPrepareFromMediaId(mediaId);
      case 'onPlay':
        return await _task.onPlay();
      case 'onPlayFromMediaId':
        final List args = call.arguments;
        String mediaId = args[0];
        return await _task.onPlayFromMediaId(mediaId);
      case 'onPlayMediaItem':
        return await _task.onPlayMediaItem(_task.convertRawMapToMediaItem(call.arguments[0]));
      case 'onAddQueueItem':
        return await _task.onAddQueueItem(_task.convertRawMapToMediaItem(call.arguments[0]));
      case 'onAddQueueItemAt':
        final List args = call.arguments;
        int index = args[1];
        return await _task.onAddQueueItemAt(_task.convertRawMapToMediaItem(args[0]), index);
      case 'onUpdateQueue':
        final List args = call.arguments;
        final List queue = args[0];
        return await _task.onUpdateQueue(_task.convertRawListToMediaItemList(queue));
      case 'onUpdateMediaItem':
        return await _task.onUpdateMediaItem(_task.convertRawMapToMediaItem(call.arguments[0]));
      case 'onRemoveQueueItem':
        return await _task.onRemoveQueueItem(_task.convertRawMapToMediaItem(call.arguments[0]));
      case 'onSkipToNext':
        return await _task.onSkipToNext();
      case 'onSkipToPrevious':
        return await _task.onSkipToPrevious();
      case 'onFastForward':
        return await _task.onFastForward();
      case 'onRewind':
        return await _task.onRewind();
      case 'onSkipToQueueItem':
        final List args = call.arguments;
        String mediaId = args[0];
        return await _task.onSkipToQueueItem(mediaId);
      case 'onSeekTo':
        final List args = call.arguments;
        int positionMs = args[0];
        Duration position = Duration(milliseconds: positionMs);
        return await _task.onSeekTo(position);
      case 'onSetRepeatMode':
        final List args = call.arguments;
        return await _task
            .onSetRepeatMode(AudioServiceRepeatMode.values[args[0]]);
      case 'onSetShuffleMode':
        final List args = call.arguments;
        return await _task
            .onSetShuffleMode(AudioServiceShuffleMode.values[args[0]]);
      case 'onSetRating':
        return await _task.onSetRating(
            Rating.fromRaw(call.arguments[0]), call.arguments[1]);
      case 'onSeekBackward':
        final List args = call.arguments;
        return await _task.onSeekBackward(args[0]);
      case 'onSeekForward':
        final List args = call.arguments;
        return await _task.onSeekForward(args[0]);
      case 'onSetSpeed':
        final List args = call.arguments;
        double speed = args[0];
        return await _task.onSetSpeed(speed);
      case 'onTaskRemoved':
        return await _task.onTaskRemoved();
      case 'onClose':
        return await _task.onClose();
      default:
        if (call.method.startsWith(CUSTOM_PREFIX)) {
          final result = await _task.onCustomAction(
              call.method.substring(CUSTOM_PREFIX.length), call.arguments);
          return result;
        }
        return null;
    }
  }

  /// Wait for methods (other than onStop) in progress.
  Future<void> _waitForMethodsInProgress() async {
    if (_inProgressMethodCount > 0) {
      await _inProgressCompleter.future;
    }
  }

  /// Shuts down the background audio audio.task within the background isolate.
  Future<void> shutdown() async {
    if (!_running) return;
    // Set this to false immediately so that if duplicate shutdown requests come
    // through, they are ignored.
    _running = false;
    // Interrupt any client method calls in progress.
    _taskCompleter.complete();
    final audioSession = await AudioSession.instance;
    try {
      await audioSession.setActive(false);
    } catch (e) {
      print("While deactivating audio session: $e");
    }
    _state = noneState;
    _controls = [];
    _systemActions = [];
    // _queue = [];
    // Before shutting down the engine, ensure that any methods in progress are
    // interrupted and return results to the client.
    await _waitForMethodsInProgress();
    // Shut down the engine
    await _backgroundChannel.invokeMethod('stopped');
    if (kIsWeb) {
    } else if (Platform.isIOS) {
      FlutterIsolate.current.kill();
    }
    _backgroundChannel.setMethodCallHandler(null);
  }

  /// Broadcasts to all clients the current state, including:
  ///
  /// * Whether audio.media is playing or paused
  /// * Whether audio.media is buffering or skipping
  /// * The current position, buffered position and speed
  /// * The current set of audio.media actions that should be enabled
  ///
  /// Connected clients will use this information to update their UI.
  ///
  /// You should use [controls] to specify the set of clickable buttons that
  /// should currently be visible in the notification in the current state,
  /// where each button is a [MediaControl] that triggers a different
  /// [MediaAction]. Only the following actions can be enabled as
  /// [MediaControl]s:
  ///
  /// * [MediaAction.stop]
  /// * [MediaAction.pause]
  /// * [MediaAction.play]
  /// * [MediaAction.rewind]
  /// * [MediaAction.skipToPrevious]
  /// * [MediaAction.skipToNext]
  /// * [MediaAction.fastForward]
  /// * [MediaAction.playPause]
  ///
  /// Any other action you would like to enable for clients that is not a clickable
  /// notification button should be specified in the [systemActions] parameter. For
  /// example:
  ///
  /// * [MediaAction.seekTo] (enable a seek bar)
  /// * [MediaAction.seekForward] (enable press-and-hold fast-forward control)
  /// * [MediaAction.seekBackward] (enable press-and-hold rewind control)
  ///
  /// In practice, iOS will treat all entries in [controls] and [systemActions]
  /// in the same way since you cannot customise the icons of controls in the
  /// Control Center. However, on Android, the distinction is important as clickable
  /// buttons in the notification require you to specify your own icon.
  ///
  /// Note that specifying [MediaAction.seekTo] in [systemActions] will enable
  /// a seek bar in both the Android notification and the iOS control center.
  /// [MediaAction.seekForward] and [MediaAction.seekBackward] have a special
  /// behaviour on iOS in which if you have already enabled the
  /// [MediaAction.skipToNext] and [MediaAction.skipToPrevious] buttons, these
  /// additional actions will allow the user to press and hold the buttons to
  /// activate the continuous seeking behaviour.
  ///
  /// On Android, a audio.media notification has a compact and expanded form. In the
  /// compact view, you can optionally specify the indices of up to 3 of your
  /// [controls] that you would like to be shown via [androidCompactActions].
  ///
  /// The playback [position] should NOT be updated continuously in real time.
  /// Instead, it should be updated only when the normal continuity of time is
  /// disrupted, such as during a seek, buffering and seeking. When
  /// broadcasting such a position change, the [updateTime] specifies the time
  /// of that change, allowing clients to project the realtime value of the
  /// position as `position + (DateTime.now() - updateTime)`. As a convenience,
  /// this calculation is provided by [PlaybackState.currentPosition].
  ///
  /// The playback [speed] is given as a double where 1.0 means normal speed.
  ///
  /// [controls] -- 通知栏支持的相关控制按钮
  /// [systemActions] -- 通知栏支持的非按钮类Actions
  /// [processingState] -- 音频播放状态
  /// [playing] -- 当前播放状态
  /// [position] -- 当前播放位置
  /// [bufferedPosition] -- 当前播放缓冲位置
  /// [speed] -- 当前播放速度
  /// [repeatMode] -- 播放模式
  /// [shuffleMode] -- 播放模式
  /// [extras] -- 额外的数据（目前仅支持传输基本数据类型）
  /// [needUpdateNotification] -- 是否同步更新通知栏状态
  Future<void> setPlaybackState(
      {List<MediaControl>? controls,
      List<MediaAction>? systemActions,
      List<int>? androidCompactActions,
      AudioProcessingState? processingState,
      bool? playing,
      Duration? position,
      Duration? bufferedPosition,
      double? speed,
      DateTime? updateTime,
      AudioServiceRepeatMode? repeatMode,
      AudioServiceShuffleMode? shuffleMode,
      Map<String, dynamic>? extras,
      required bool needUpdateNotification}) async {
    controls ??= _controls;
    systemActions ??= _systemActions;
    processingState ??= _state.processingState;
    playing ??= _state.playing;
    position ??= _state.position;
    updateTime ??= DateTime.now();
    bufferedPosition ??= _state.bufferedPosition;
    speed ??= _state.speed;
    repeatMode ??= _state.repeatMode;
    shuffleMode ??= _state.shuffleMode;

    _controls = controls;
    _systemActions = systemActions;
    _state = PlaybackState(
      processingState: processingState,
      playing: playing,
      actions: controls.map((control) => control.action).toSet(),
      position: position,
      bufferedPosition: bufferedPosition,
      speed: speed,
      updateTime: updateTime,
      repeatMode: repeatMode,
      shuffleMode: shuffleMode,
      extras: extras,
    );
    List<Map> rawControls = controls
        .map((control) => {
              'androidIcon': control.androidIcon,
              'label': control.label,
              'action': control.action.index,
            })
        .toList();
    final rawSystemActions =
        systemActions.map((action) => action.index).toList();

    await _backgroundChannel.invokeMethod('setState', [
      rawControls,
      rawSystemActions,
      androidCompactActions,
      processingState.index,
      playing,
      position.inMilliseconds,
      bufferedPosition.inMilliseconds,
      speed,
      updateTime.millisecondsSinceEpoch,
      repeatMode.index,
      shuffleMode.index,
      extras,
      needUpdateNotification,
    ]);
  }

  /// Sets the current queue and notifies all clients.
  Future<void> setQueue<T>(List<T> queue,
      {bool preloadArtwork = false}) async {
    // _queue = queue;
    // if (preloadArtwork) {
    //   _loadAllArtwork(queue);
    // }
    await _backgroundChannel.invokeMethod(
        'setQueue', queue.map((item) => (item as dynamic).toJson()).toList());
  }

  /// Sets the currently playing audio.media item and notifies all clients.
  Future<void> setMediaItem<T>(T mediaItem) async {
    // _mediaItem = mediaItem;
    // final artUri = mediaItem.artUri;
    // if (artUri != null) {
    //   // We potentially need to fetch the art.
    //   String? filePath;
    //   if (artUri.scheme == 'file') {
    //     filePath = artUri.toFilePath();
    //   } else {
    //     final FileInfo? fileInfo = await _cacheManager!
    //         .getFileFromMemory(mediaItem.artUri!.toString());
    //     filePath = fileInfo?.file.path;
    //     if (filePath == null) {
    //       // We haven't fetched the art yet, so show the metadata now, and again
    //       // after we load the art.
    //       await _backgroundChannel.invokeMethod(
    //           'setMediaItem', mediaItem.toJson());
    //       // Load the art
    //       filePath = await _loadArtwork(mediaItem);
    //       // If we failed to download the art, abort.
    //       if (filePath == null) return;
    //       // If we've already set a new audio.media item, cancel this request.
    //       if (mediaItem != _mediaItem) return;
    //     }
    //   }
    //   final extras = Map.of(mediaItem.extras ?? <String, dynamic>{});
    //   extras['artCacheFile'] = filePath;
    //   final platformMediaItem = mediaItem.copyWith(extras: extras);
    //   // Show the audio.media item after the art is loaded.
    //   await _backgroundChannel.invokeMethod(
    //       'setMediaItem', platformMediaItem.toJson());
    // } else {
      await _backgroundChannel.invokeMethod('setMediaItem', (mediaItem as dynamic).toJson());
    // }
  }

  // Future<void> _loadAllArtwork(List<T> queue) async {
  //   for (var mediaItem in queue) {
  //     await _loadArtwork(mediaItem);
  //   }
  // }
  //
  // Future<String?> _loadArtwork(MediaItem mediaItem) async {
  //   try {
  //     final artUri = mediaItem.artUri;
  //     if (artUri != null) {
  //       if (artUri.scheme == 'file') {
  //         return artUri.toFilePath();
  //       } else {
  //         final file =
  //             await _cacheManager!.getSingleFile(mediaItem.artUri!.toString());
  //         return file.path;
  //       }
  //     }
  //   } catch (e) {}
  //   return null;
  // }

  /// Notifies clients that the child audio.media items of [parentMediaId] have
  /// changed.
  ///
  /// If [parentMediaId] is unspecified, the root parent will be used.
  static Future<void> notifyChildrenChanged(
      [String parentMediaId = MEDIA_ROOT_ID]) async {
    await _backgroundChannel.invokeMethod(
        'notifyChildrenChanged', parentMediaId);
  }

  /// In Android, forces audio.media button events to be routed to your active audio.media
  /// session.
  ///
  /// This is necessary if you want to play TextToSpeech in the background and
  /// still respond to audio.media button events. You should call it just before
  /// playing TextToSpeech.
  ///
  /// This is not necessary if you are playing normal audio in the background
  /// such as music because this kind of "normal" audio playback will
  /// automatically qualify your app to receive audio.media button events.
  static Future<void> androidForceEnableMediaButtons() async {
    await _backgroundChannel.invokeMethod('androidForceEnableMediaButtons');
  }

  /// Sends a custom event to the Flutter UI.
  ///
  /// The event parameter can contain any data permitted by Dart's
  /// SendPort/ReceivePort API. Please consult the relevant documentation for
  /// further information.
  static void sendCustomEvent(dynamic event) {
    if (!AudioServiceController.usesIsolate) {
      AudioServiceController.addCustomEvent(event);
    } else {
      SendPort? sendPort =
          IsolateNameServer.lookupPortByName(CUSTOM_EVENT_PORT_NAME);
      sendPort?.send(event);
    }
  }
}
