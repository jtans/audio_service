import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:rxdart/rxdart.dart';

import 'audio_service_background.dart';
import 'package:audio_service/audio/media/audio_media_resource.dart';

bool get testMode => !kIsWeb && Platform.environment['FLUTTER_TEST'] == 'true';

const CUSTOM_PREFIX = "custom_";
const CUSTOM_EVENT_PORT_NAME = 'customEventPort';
const MethodChannel _channel = const MethodChannel('ryanheise.com/audioService');



/// Client API to connect with and communciate with the background audio task.
///
/// You may use this API from your UI to send start/pause/play/stop/etc messages
/// to your background audio task, and to listen to state changes broadcast by
/// your background audio task. You may also use this API from other background
/// isolates (e.g. android_alarm_manager) to communicate with the background
/// audio task.
///
/// A client must [connect] to the service before it will be able to send
/// messages to the background audio task, and must [disconnect] when
/// communication is no longer required. In practice, a UI should maintain a
/// connection exactly while it is visible. It is strongly recommended that you
/// use [AudioServiceWidget] to manage this connection for you automatically.
///
/// 音频后台服务播放控制器
/// 主要用于与音频后台服务进行通信，传输音频前端页面发出的音频控制指令
/// TODO xiong -- 补充：回调接口设置
class AudioServiceController {
  /// True if the background task runs in its own isolate, false if it doesn't.
  static bool get usesIsolate => !(kIsWeb || Platform.isMacOS) && !testMode;

  /// The root media ID for browsing media provided by the background
  /// task.
  static const String MEDIA_ROOT_ID = "root";

  /// If a seek is in progress, this holds the position we are seeking to.
  static Duration? _seekPos;

  /// True after service stopped and !running.
  static bool _afterStop = false;

  /// Receives custom events from the background audio task.
  static ReceivePort? _customEventReceivePort;
  static StreamSubscription? _customEventSubscription;

  static Completer<void>? _startNonIsolateCompleter;

  /// ---------------------- browserChildren Notify ----------------------///
  static final _browseMediaChildrenSubject = BehaviorSubject<List<MediaItem>?>();

  /// A stream that broadcasts the children of the current browse
  /// media parent.
  static ValueStream<List<MediaItem>?> get browseMediaChildrenStream =>
      _browseMediaChildrenSubject.stream;

  /// The children of the current browse media parent.
  static List<MediaItem>? get browseMediaChildren =>
      _browseMediaChildrenSubject.nvalue;

  /// ----------------------- playbackState Notify -----------------------///
  static final _playbackStateSubject = BehaviorSubject<PlaybackState>();

  /// A stream that broadcasts the playback state.
  static ValueStream<PlaybackState> get playbackStateStream =>
      _playbackStateSubject.stream;

  /// The current playback state.
  static PlaybackState get playbackState =>
      _playbackStateSubject.nvalue ?? AudioServiceBackground.noneState;

  /// ------------------------- MediaItem Notify -------------------------///
  static final _currentMediaItemSubject = BehaviorSubject<MediaItem?>();

  /// A stream that broadcasts the current [MediaItem].
  static ValueStream<MediaItem?> get currentMediaItemStream =>
      _currentMediaItemSubject.stream;

  /// The current [MediaItem].
  static MediaItem? get currentMediaItem => _currentMediaItemSubject.nvalue;

  /// ------------------------- MediaQueue Notify -------------------------///
  static final _queueSubject = BehaviorSubject<List<MediaItem>?>();

  /// A stream that broadcasts the queue.
  static ValueStream<List<MediaItem>?> get queueStream => _queueSubject.stream;

  /// The current queue.
  static List<MediaItem>? get queue => _queueSubject.nvalue;

  /// ----------------------- notification Notify -----------------------///
  static final _notificationSubject = BehaviorSubject.seeded(false);

  /// A stream that broadcasts the status of the notificationClick event.
  static ValueStream<bool> get notificationClickEventStream =>
      _notificationSubject.stream;

  /// The status of the notificationClick event.
  static bool get notificationClickEvent => _notificationSubject.nvalue ?? false;

  /// ----------------------- customEvent Notify -----------------------///
  static final _customEventSubject = PublishSubject<dynamic>();

  /// A stream that broadcasts custom events sent from the background.
  static Stream<dynamic> get customEventStream => _customEventSubject.stream;


  static void startedNonIsolate() {
    _startNonIsolateCompleter?.complete();
  }

  static void addCustomEvent(dynamic event) {
    _customEventSubject.add(event);
  }

  /// A queue of tasks to be processed serially. Tasks that are processed on
  /// this queue:
  ///
  /// - [connect]
  /// - [disconnect]
  /// - [start]
  ///
  /// TODO: Queue other tasks? Note, only short-running tasks should be queued.
  static final _asyncTaskQueue = _AsyncTaskQueue();

  // ignore: close_sinks
  static BehaviorSubject<Duration>? _positionSubject;

  /// Connects to the service from your UI so that audio playback can be
  /// controlled.
  ///
  /// This method should be called when your UI becomes visible, and
  /// [disconnect] should be called when your UI is no longer visible. All
  /// other methods in this class will work only while connected.
  ///
  /// Use [AudioServiceWidget] to handle this automatically.
  static Future<void> connect({Function(bool)? onConnectCallback}) => _asyncTaskQueue.schedule(() async {
    if (_connected) return;
    final handler = (MethodCall call) async {
      switch (call.method) {
        case 'onChildrenLoaded':
          final List<Map> args = List<Map>.from(call.arguments[0]);
          _browseMediaChildrenSubject
              .add(args.map((raw) => MediaItem.fromJson(raw)).toList());
          break;
        case 'onPlaybackStateChanged':
        // If this event arrives too late, ignore it.
          if (_afterStop) return;
          final List args = call.arguments;
          int actionBits = args[2];
          _playbackStateSubject.add(PlaybackState(
            processingState: AudioProcessingState.values[args[0]],
            playing: args[1],
            actions: MediaAction.values
                .where((action) => (actionBits & (1 << action.index)) != 0)
                .toSet(),
            position: Duration(milliseconds: args[3]),
            bufferedPosition: Duration(milliseconds: args[4]),
            speed: args[5],
            updateTime: DateTime.fromMillisecondsSinceEpoch(args[6]),
            repeatMode: AudioServiceRepeatMode.values[args[7]],
            shuffleMode: AudioServiceShuffleMode.values[args[8]],
          ));
          break;
        case 'onMediaChanged':
          _currentMediaItemSubject.add(call.arguments[0] != null
              ? MediaItem.fromJson(call.arguments[0])
              : null);
          break;
        case 'onQueueChanged':
          final List<Map>? args = call.arguments[0] != null
              ? List<Map>.from(call.arguments[0])
              : null;
          _queueSubject
              .add(args?.map((raw) => MediaItem.fromJson(raw)).toList());
          break;
        case 'onStopped':
          _browseMediaChildrenSubject.add(null);
          _playbackStateSubject.add(AudioServiceBackground.noneState);
          _currentMediaItemSubject.add(null);
          _queueSubject.add(null);
          _notificationSubject.add(false);
          _runningSubject.add(false);
          _afterStop = true;
          break;
        case 'notificationClicked':
          _notificationSubject.add(call.arguments[0]);
          break;
      }
    };
    if (testMode) {
      MethodChannel('ryanheise.com/audioServiceInverse')
          .setMockMethodCallHandler(handler);
    } else {
      _channel.setMethodCallHandler(handler);
    }
    if (usesIsolate) {
      _customEventReceivePort = ReceivePort();
      _customEventSubscription = _customEventReceivePort!.listen((event) {
        _customEventSubject.add(event);
      });
      IsolateNameServer.removePortNameMapping(CUSTOM_EVENT_PORT_NAME);
      IsolateNameServer.registerPortWithName(
          _customEventReceivePort!.sendPort, CUSTOM_EVENT_PORT_NAME);
    }
    bool result = (await _channel.invokeMethod<bool>("connect"))!;
    if (onConnectCallback != null) {
      onConnectCallback(result);
    }

    final running = (await _channel.invokeMethod<bool>("isRunning"))!;
    if (running != _runningSubject.nvalue) {
      _runningSubject.add(running);
    }
    _connected = true;
  });

  /// Disconnects your UI from the service.
  ///
  /// This method should be called when the UI is no longer visible.
  ///
  /// Use [AudioServiceWidget] to handle this automatically.
  static Future<void> disconnect() => _asyncTaskQueue.schedule(() async {
    if (!_connected) return;
    _channel.setMethodCallHandler(null);
    _customEventSubscription?.cancel();
    _customEventSubscription = null;
    _customEventReceivePort = null;
    await _channel.invokeMethod("disconnect");
    _connected = false;
  });

  /// True if the UI is connected.
  static bool get connected => _connected;
  static bool _connected = false;

  static final _runningSubject = BehaviorSubject<bool>();

  /// A stream indicating when the [running] state changes.
  static ValueStream<bool> get runningStream => _runningSubject.stream;

  /// True if the background audio task is running.
  static bool get running => _runningSubject.nvalue ?? false;

  /// Starts a background audio task which will continue running even when the
  /// UI is not visible or the screen is turned off. Only one background audio task
  /// may be running at a time.
  ///
  /// While the background task is running, it will display a system
  /// notification showing information about the current media item being
  /// played (see [AudioServiceBackground.setMediaItem]) along with any media
  /// controls to perform any media actions that you want to support (see
  /// [AudioServiceBackground.setState]).
  ///
  /// The background task is specified by [backgroundTaskEntrypoint] which will
  /// be run within a background isolate. This function must be a top-level
  /// function, and it must initiate execution by calling
  /// [AudioServiceBackground.run]. Because the background task runs in an
  /// isolate, no memory is shared between the background isolate and your main
  /// UI isolate and so all communication between the background task and your
  /// UI is achieved through message passing.
  ///
  /// The [androidNotificationIcon] is specified like an XML resource reference
  /// and defaults to `"mipmap/ic_launcher"`.
  ///
  /// [androidShowNotificationBadge] enable notification badges (also known as notification dots)
  /// to appear on a launcher icon when the app has an active notification.
  ///
  /// If specified, [androidArtDownscaleSize] causes artwork to be downscaled
  /// to the given resolution in pixels before being displayed in the
  /// notification and lock screen. If not specified, no downscaling will be
  /// performed. If the resolution of your artwork is particularly high,
  /// downscaling can help to conserve memory.
  ///
  /// [params] provides a way to pass custom parameters through to the
  /// `onStart` method of your background audio task. If specified, this must
  /// be a map consisting of keys/values that can be encoded via Flutter's
  /// `StandardMessageCodec`.
  ///
  /// [fastForwardInterval] and [rewindInterval] are passed through to your
  /// background audio task as properties, and they represent the duration
  /// of audio that should be skipped in fast forward / rewind operations. On
  /// iOS, these values also configure the intervals for the skip forward and
  /// skip backward buttons. Note that both [fastForwardInterval] and
  /// [rewindInterval] must be positive durations.
  ///
  /// [androidEnableQueue] enables queue support on the media session on
  /// Android. If your app will run on Android and has a queue, you should set
  /// this to true.
  ///
  /// [androidStopForegroundOnPause] will switch the Android service to a lower
  /// priority state when playback is paused allowing the user to swipe away the
  /// notification. Note that while in this lower priority state, the operating
  /// system will also be able to kill your service at any time to reclaim
  /// resources.
  ///
  /// This method waits for [BackgroundAudioTask.onStart] to complete, and
  /// completes with true if the task was successfully started, or false
  /// otherwise.
  static Future<bool> start({
    required Function backgroundTask,
    Map<String, dynamic>? params,
    String androidNotificationChannelName = "Notifications",
    String? androidNotificationChannelDescription,
    int? androidNotificationColor,
    String androidNotificationIcon = 'mipmap/ic_launcher',
    bool androidShowNotificationBadge = false,
    bool androidNotificationClickStartsActivity = true,
    bool androidNotificationOngoing = false,
    bool androidResumeOnClick = true,
    bool androidStopForegroundOnPause = false,
    bool androidEnableQueue = false,
    Size? androidArtDownscaleSize,
    Duration fastForwardInterval = const Duration(seconds: 10),
    Duration rewindInterval = const Duration(seconds: 10),
  }) async {
    assert(fastForwardInterval > Duration.zero,
    "fastForwardDuration must be positive");
    assert(rewindInterval > Duration.zero, "rewindInterval must be positive");
    return await _asyncTaskQueue.schedule(() async {
      if (!_connected) throw Exception("Not connected");
      if (running) return false;
      _runningSubject.add(true);
      _afterStop = false;
      ui.CallbackHandle? handle;
      if (usesIsolate) {
        handle = ui.PluginUtilities.getCallbackHandle(backgroundTask);
        if (handle == null) {
          return false;
        }
      }

      var callbackHandle = handle?.toRawHandle();
      if (kIsWeb) {
        // Platform throws runtime exceptions on web
      } else if (Platform.isIOS) {
        // NOTE: to maintain compatibility between the Android and iOS
        // implementations, we ensure that the iOS background task also runs in
        // an isolate. Currently, the standard Isolate API does not allow
        // isolates to invoke methods on method channels. That may be fixed in
        // the future, but until then, we use the flutter_isolate plugin which
        // creates a FlutterNativeView for us, similar to what the Android
        // implementation does.
        // TODO: remove dependency on flutter_isolate by either using the
        // FlutterNativeView API directly or by waiting until Flutter allows
        // regular isolates to use method channels.
        await FlutterIsolate.spawn(_iosIsolateEntryPoint, callbackHandle!);
      }
      final success = (await _channel.invokeMethod<bool>('start', {
        'callbackHandle': callbackHandle,
        'params': params,
        'androidNotificationChannelName': androidNotificationChannelName,
        'androidNotificationChannelDescription':
        androidNotificationChannelDescription,
        'androidNotificationColor': androidNotificationColor,
        'androidNotificationIcon': androidNotificationIcon,
        'androidShowNotificationBadge': androidShowNotificationBadge,
        'androidNotificationClickStartsActivity':
        androidNotificationClickStartsActivity,
        'androidNotificationOngoing': androidNotificationOngoing,
        'androidResumeOnClick': androidResumeOnClick,
        'androidStopForegroundOnPause': androidStopForegroundOnPause,
        'androidEnableQueue': androidEnableQueue,
        'androidArtDownscaleSize': androidArtDownscaleSize != null
            ? {
          'width': androidArtDownscaleSize.width,
          'height': androidArtDownscaleSize.height
        }
            : null,
        'fastForwardInterval': fastForwardInterval.inMilliseconds,
        'rewindInterval': rewindInterval.inMilliseconds,
      }))!;
      if (!usesIsolate) {
        _startNonIsolateCompleter = Completer();
        backgroundTask();
        await _startNonIsolateCompleter?.future;
        _startNonIsolateCompleter = null;
      }
      if (!success) {
        _runningSubject.add(false);
      }
      return success;
    });
  }

  /// Sets the parent of the children that [browseMediaChildrenStream] broadcasts.
  /// If unspecified, the root parent will be used.
  static Future<void> setBrowseMediaParent(
      [String parentMediaId = MEDIA_ROOT_ID]) async {
    await _channel.invokeMethod('setBrowseMediaParent', parentMediaId);
  }

  /// Sends a request to your background audio task to add an item to the
  /// queue. This passes through to the `onAddQueueItem` method in your
  /// background audio task.
  static Future<void> addQueueItem(MediaItem mediaItem) async {
    await _channel.invokeMethod('addQueueItem', mediaItem.toJson());
  }

  /// Sends a request to your background audio task to add a item to the queue
  /// at a particular position. This passes through to the `onAddQueueItemAt`
  /// method in your background audio task.
  static Future<void> addQueueItemAt(MediaItem mediaItem, int index) async {
    await _channel.invokeMethod('addQueueItemAt', [mediaItem.toJson(), index]);
  }

  /// Sends a request to your background audio task to remove an item from the
  /// queue. This passes through to the `onRemoveQueueItem` method in your
  /// background audio task.
  static Future<void> removeQueueItem(MediaItem mediaItem) async {
    await _channel.invokeMethod('removeQueueItem', mediaItem.toJson());
  }

  /// A convenience method calls [addQueueItem] for each media item in the
  /// given list. Note that this will be inefficient if you are adding a lot
  /// of media items at once. If possible, you should use [updateQueue]
  /// instead.
  static Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    for (var mediaItem in mediaItems) {
      await addQueueItem(mediaItem);
    }
  }

  /// Sends a request to your background audio task to replace the queue with a
  /// new list of media items. This passes through to the `onUpdateQueue`
  /// method in your background audio task.
  static Future<void> updateQueue(List<MediaItem> queue) async {
    await _channel.invokeMethod(
        'updateQueue', queue.map((item) => item.toJson()).toList());
  }

  /// Sends a request to your background audio task to update the details of a
  /// media item. This passes through to the 'onUpdateMediaItem' method in your
  /// background audio task.
  static Future<void> updateMediaItem(MediaItem mediaItem) async {
    await _channel.invokeMethod('updateMediaItem', mediaItem.toJson());
  }

  /// Programmatically simulates a click of a media button on the headset.
  ///
  /// This passes through to `onClick` in the background audio task.
  static Future<void> click([MediaButton button = MediaButton.media]) async {
    await _channel.invokeMethod('click', button.index);
  }

  /// Sends a request to your background audio task to prepare for audio
  /// playback. This passes through to the `onPrepare` method in your
  /// background audio task.
  static Future<void> prepare() async {
    await _channel.invokeMethod('prepare');
  }

  /// Sends a request to your background audio task to prepare for playing a
  /// particular media item. This passes through to the `onPrepareFromMediaId`
  /// method in your background audio task.
  static Future<void> prepareFromMediaId(String mediaId) async {
    await _channel.invokeMethod('prepareFromMediaId', mediaId);
  }

  //static Future<void> prepareFromSearch(String query, Bundle extras) async {}
  //static Future<void> prepareFromUri(Uri uri, Bundle extras) async {}

  /// Sends a request to your background audio task to play the current media
  /// item. This passes through to 'onPlay' in your background audio task.
  static Future<void> play() async {
    await _channel.invokeMethod('play');
  }

  /// Sends a request to your background audio task to play a particular media
  /// item referenced by its media id. This passes through to the
  /// 'onPlayFromMediaId' method in your background audio task.
  static Future<void> playFromMediaId(String mediaId) async {
    await _channel.invokeMethod('playFromMediaId', mediaId);
  }

  /// Sends a request to your background audio task to play a particular media
  /// item. This passes through to the 'onPlayMediaItem' method in your
  /// background audio task.
  static Future<void> playMediaItem(MediaItem mediaItem) async {
    await _channel.invokeMethod('playMediaItem', mediaItem.toJson());
  }

  //static Future<void> playFromSearch(String query, Bundle extras) async {}
  //static Future<void> playFromUri(Uri uri, Bundle extras) async {}

  /// Sends a request to your background audio task to skip to a particular
  /// item in the queue. This passes through to the `onSkipToQueueItem` method
  /// in your background audio task.
  static Future<void> skipToQueueItem(String mediaId) async {
    await _channel.invokeMethod('skipToQueueItem', mediaId);
  }

  /// Sends a request to your background audio task to pause playback. This
  /// passes through to the `onPause` method in your background audio task.
  static Future<void> pause() async {
    await _channel.invokeMethod('pause');
  }

  /// Sends a request to your background audio task to stop playback and shut
  /// down the task. This passes through to the `onStop` method in your
  /// background audio task.
  static Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  /// Sends a request to your background audio task to seek to a particular
  /// position in the current media item. This passes through to the `onSeekTo`
  /// method in your background audio task.
  static Future<void> seekTo(Duration position) async {
    _seekPos = position;
    try {
      await _channel.invokeMethod('seekTo', position.inMilliseconds);
    } finally {
      _seekPos = null;
    }
  }

  /// Sends a request to your background audio task to skip to the next item in
  /// the queue. This passes through to the `onSkipToNext` method in your
  /// background audio task.
  static Future<void> skipToNext() async {
    await _channel.invokeMethod('skipToNext');
  }

  /// Sends a request to your background audio task to skip to the previous
  /// item in the queue. This passes through to the `onSkipToPrevious` method
  /// in your background audio task.
  static Future<void> skipToPrevious() async {
    await _channel.invokeMethod('skipToPrevious');
  }

  /// Sends a request to your background audio task to fast forward by the
  /// interval passed into the [start] method. This passes through to the
  /// `onFastForward` method in your background audio task.
  static Future<void> fastForward() async {
    await _channel.invokeMethod('fastForward');
  }

  /// Sends a request to your background audio task to rewind by the interval
  /// passed into the [start] method. This passes through to the `onRewind`
  /// method in the background audio task.
  static Future<void> rewind() async {
    await _channel.invokeMethod('rewind');
  }

  //static Future<void> setCaptioningEnabled(boolean enabled) async {}

  /// Sends a request to your background audio task to set the repeat mode.
  /// This passes through to the `onSetRepeatMode` method in your background
  /// audio task.
  static Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await _channel.invokeMethod('setRepeatMode', repeatMode.index);
  }

  /// Sends a request to your background audio task to set the shuffle mode.
  /// This passes through to the `onSetShuffleMode` method in your background
  /// audio task.
  static Future<void> setShuffleMode(
      AudioServiceShuffleMode shuffleMode) async {
    await _channel.invokeMethod('setShuffleMode', shuffleMode.index);
  }

  /// Sends a request to your background audio task to set a rating on the
  /// current media item. This passes through to the `onSetRating` method in
  /// your background audio task. The extras map must *only* contain primitive
  /// types!
  static Future<void> setRating(Rating rating,
      [Map<String, dynamic>? extras]) async {
    await _channel.invokeMethod('setRating', {
      "rating": rating.toRaw(),
      "extras": extras,
    });
  }

  /// Sends a request to your background audio task to set the audio playback
  /// speed. This passes through to the `onSetSpeed` method in your background
  /// audio task.
  static Future<void> setSpeed(double speed) async {
    await _channel.invokeMethod('setSpeed', speed);
  }

  /// Sends a request to your background audio task to begin or end seeking
  /// backward. This method passes through to the `onSeekBackward` method in
  /// your background audio task.
  static Future<void> seekBackward(bool begin) async {
    await _channel.invokeMethod('seekBackward', begin);
  }

  /// Sends a request to your background audio task to begin or end seek
  /// forward. This method passes through to the `onSeekForward` method in your
  /// background audio task.
  static Future<void> seekForward(bool begin) async {
    await _channel.invokeMethod('seekForward', begin);
  }

  //static Future<void> sendCustomAction(PlaybackStateCompat.CustomAction customAction,
  //static Future<void> sendCustomAction(String action, Bundle args) async {}

  /// Sends a custom request to your background audio task. This passes through
  /// to the `onCustomAction` in your background audio task.
  ///
  /// This may be used for your own purposes. [arguments] can be any data that
  /// is encodable by `StandardMessageCodec`.
  static Future customAction(String name, [dynamic arguments]) async {
    return await _channel.invokeMethod('$CUSTOM_PREFIX$name', arguments);
  }

  /// A stream tracking the current position, suitable for animating a seek bar.
  /// To ensure a smooth animation, this stream emits values more frequently on
  /// short media items where the seek bar moves more quickly, and less
  /// frequenly on long media items where the seek bar moves more slowly. The
  /// interval between each update will be no quicker than once every 16ms and
  /// no slower than once every 200ms.
  ///
  /// See [createPositionStream] for more control over the stream parameters.
  static ValueStream<Duration> get positionStream {
    if (_positionSubject == null) {
      _positionSubject = BehaviorSubject<Duration>(sync: true);
      _positionSubject!.addStream(createPositionStream(
          steps: 800,
          minPeriod: Duration(milliseconds: 16),
          maxPeriod: Duration(milliseconds: 200)));
    }
    return _positionSubject!.stream;
  }

  /// Creates a new stream periodically tracking the current position. The
  /// stream will aim to emit [steps] position updates at intervals of
  /// [duration] / [steps]. This interval will be clipped between [minPeriod]
  /// and [maxPeriod]. This stream will not emit values while audio playback is
  /// paused or stalled.
  ///
  /// Note: each time this method is called, a new stream is created. If you
  /// intend to use this stream multiple times, you should hold a reference to
  /// the returned stream.
  static Stream<Duration> createPositionStream({
    int steps = 800,
    Duration minPeriod = const Duration(milliseconds: 200),
    Duration maxPeriod = const Duration(milliseconds: 200),
  }) {
    assert(minPeriod <= maxPeriod);
    assert(minPeriod > Duration.zero);
    Duration? last;
    // ignore: close_sinks
    late StreamController<Duration> controller;
    late StreamSubscription<MediaItem?> mediaItemSubscription;
    late StreamSubscription<PlaybackState> playbackStateSubscription;
    Timer? currentTimer;
    Duration duration() => currentMediaItem?.duration ?? Duration.zero;
    Duration step() {
      var s = duration() ~/ steps;
      if (s < minPeriod) s = minPeriod;
      if (s > maxPeriod) s = maxPeriod;
      return s;
    }

    void yieldPosition(Timer? timer) {
      final newPosition = _seekPos ?? playbackState.currentPosition;
      if (last != newPosition) {
        controller.add(last = newPosition);
      }
    }

    controller = StreamController.broadcast(
      sync: true,
      onListen: () {
        mediaItemSubscription = currentMediaItemStream.listen((mediaItem) {
          // Potentially a new duration
          currentTimer?.cancel();
          currentTimer = Timer.periodic(step(), yieldPosition);
        });
        playbackStateSubscription = playbackStateStream.listen((state) {
          // Potentially a time discontinuity
          yieldPosition(currentTimer);
        });
      },
      onCancel: () {
        mediaItemSubscription.cancel();
        playbackStateSubscription.cancel();
      },
    );

    return controller.stream;
  }
}

class _AsyncTaskQueue {
  final _queuedAsyncTaskController = StreamController<_AsyncTaskQueueEntry>();

  _AsyncTaskQueue() {
    _process();
  }

  Future<void> _process() async {
    await for (var entry in _queuedAsyncTaskController.stream) {
      try {
        final result = await entry.asyncTask();
        entry.completer.complete(result);
      } catch (e, stacktrace) {
        entry.completer.completeError(e, stacktrace);
      }
    }
  }

  Future<dynamic> schedule(_AsyncTask asyncTask) async {
    final completer = Completer<dynamic>();
    _queuedAsyncTaskController.add(_AsyncTaskQueueEntry(asyncTask, completer));
    return completer.future;
  }
}

class _AsyncTaskQueueEntry {
  final _AsyncTask asyncTask;
  final Completer completer;

  _AsyncTaskQueueEntry(this.asyncTask, this.completer);
}

typedef _AsyncTask = Future<dynamic> Function();


_iosIsolateEntryPoint(int rawHandle) async {
  ui.CallbackHandle handle = ui.CallbackHandle.fromRawHandle(rawHandle);
  Function backgroundTask = ui.PluginUtilities.getCallbackFromHandle(handle)!;
  backgroundTask();
}

/// Backwards compatible extensions on rxdart's ValueStream
extension _ValueStreamExtension<T> on ValueStream<T> {
  /// Backwards compatible version of valueOrNull.
  T? get nvalue => hasValue ? value : null;
}