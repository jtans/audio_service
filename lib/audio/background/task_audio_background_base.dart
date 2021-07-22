import 'package:audio_service/audio/converter/audio_media_type_converter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:audio_service/audio/media/audio_media_resource.dart';
import 'package:audio_service/audio/controller/audio_service_controller.dart';

import 'audio_service_background.dart';

/// An audio task that can run in the background and react to audio events.
///
/// You should subclass [BackgroundAudioTask] and override the callbacks for
/// eac h type of event that your background task wishes to react to. At a
/// minimum, you must override [onStart] and [onStop] to handle initialising
/// and shutting down the audio task.
///
/// 音频后台任务处理器
/// 主要用于 dart层处理音频后台服务接收的播放控制回调，继承此类实现具体的播放功能
abstract class BackgroundAudioTask<T> {
  final BaseCacheManager? cacheManager;
  late Duration _fastForwardInterval;
  late Duration _rewindInterval;

  late T mMediaItem;
  late List<T> mMediaQueue;
  late IAudioMediaTypeConverter mMediaTypeConverter;

  /// Subclasses may supply a [cacheManager] to  manage the loading of artwork,
  /// or an instance of [DefaultCacheManager] will be used by default.
  BackgroundAudioTask({BaseCacheManager? cacheManager})
      : this.cacheManager = cacheManager ?? (testMode ? null : DefaultCacheManager());

  /// The fast forward interval passed into [AudioService.start].
  Duration get fastForwardInterval => _fastForwardInterval;

  /// The rewind interval passed into [AudioService.start].
  Duration get rewindInterval => _rewindInterval;

  /// Called once when this audio task is first started and ready to play
  /// audio, in response to [AudioService.start]. [params] will contain any
  /// params passed into [AudioService.start] when starting this background
  /// audio task.
  Future<void> onStart(Map<String, dynamic>? params) async {}

  /// Called when a client has requested to terminate this background audio
  /// task, in response to [AudioService.stop]. You should implement this
  /// method to stop playing audio and dispose of any resources used.
  ///
  /// If you override this, make sure your method ends with a call to `await
  /// super.onStop()`. The isolate containing this task will shut down as soon
  /// as this method completes.
  @mustCallSuper
  Future<void> onStop() async {
    mMediaQueue = [];
    await AudioServiceBackground.instance.shutdown();
  }

  /// Called when a media browser client, such as Android Auto, wants to query
  /// the available media items to display to the user.
  Future<List<T>> onLoadChildren(String parentMediaId) async => [];

  /// Called when the media button on the headset is pressed, or in response to
  /// a call from [AudioService.click]. The default behaviour is:
  ///
  /// * On [MediaButton.media], toggle [onPlay] and [onPause].
  /// * On [MediaButton.next], call [onSkipToNext].
  /// * On [MediaButton.previous], call [onSkipToPrevious].
  Future<void> onClick(MediaButton button) async {
    switch (button) {
      case MediaButton.media:
        if (AudioServiceBackground.state.playing == true) {
          await onPause();
        } else {
          await onPlay();
        }
        break;
      case MediaButton.next:
        await onSkipToNext();
        break;
      case MediaButton.previous:
        await onSkipToPrevious();
        break;
    }
  }

  /// Called when a client has requested to pause audio playback, such as via a
  /// call to [AudioService.pause]. You should implement this method to pause
  /// audio playback and also broadcast the appropriate state change via
  /// [AudioServiceBackground.setState].
  Future<void> onPause() async {}

  /// Called when a client has requested to prepare audio for playback, such as
  /// via a call to [AudioService.prepare].
  Future<void> onPrepare() async {}

  /// Called when a client has requested to prepare a specific media item for
  /// audio playback, such as via a call to [AudioService.prepareFromMediaId].
  Future<void> onPrepareFromMediaId(String mediaId) async {}

  /// Called when a client has requested to resume audio playback, such as via
  /// a call to [AudioService.play]. You should implement this method to play
  /// audio and also broadcast the appropriate state change via
  /// [AudioServiceBackground.setState].
  Future<void> onPlay() async {}

  /// Called when a client has requested to play a media item by its ID, such
  /// as via a call to [AudioService.playFromMediaId]. You should implement
  /// this method to play audio and also broadcast the appropriate state change
  /// via [AudioServiceBackground.setState].
  Future<void> onPlayFromMediaId(String mediaId) async {}

  /// Called when the Flutter UI has requested to play a given media item via a
  /// call to [AudioService.playMediaItem]. You should implement this method to
  /// play audio and also broadcast the appropriate state change via
  /// [AudioServiceBackground.setState].
  ///
  /// Note: This method can only be triggered by your Flutter UI. Peripheral
  /// devices such as Android Auto will instead trigger
  /// [AudioService.onPlayFromMediaId].
  Future<void> onPlayMediaItem(T mediaItem) async {}

  /// Called when a client has requested to add a media item to the queue, such
  /// as via a call to [AudioService.addQueueItem].
  Future<void> onAddQueueItem(T mediaItem) async {}

  /// Called when the Flutter UI has requested to set a new queue.
  ///
  /// If you use a queue, your implementation of this method should call
  /// [AudioServiceBackground.setQueue] to notify all clients that the queue
  /// has changed.
  Future<void> onUpdateQueue(List<T> queue) async {}

  /// Called when the Flutter UI has requested to update the details of
  /// a media item.
  Future<void> onUpdateMediaItem(T mediaItem) async {}

  /// Called when a client has requested to add a media item to the queue at a
  /// specified position, such as via a request to
  /// [AudioService.addQueueItemAt].
  Future<void> onAddQueueItemAt(T mediaItem, int index) async {}

  /// Called when a client has requested to remove a media item from the queue,
  /// such as via a request to [AudioService.removeQueueItem].
  Future<void> onRemoveQueueItem(T mediaItem) async {}

  /// Called when a client has requested to skip to the next item in the queue,
  /// such as via a request to [AudioService.skipToNext].
  ///
  /// By default, calls [onSkipToQueueItem] with the queue item after
  /// [AudioServiceBackground.mediaItem] if it exists.
  Future<void> onSkipToNext() => skip(1);

  /// Called when a client has requested to skip to the previous item in the
  /// queue, such as via a request to [AudioService.skipToPrevious].
  ///
  /// By default, calls [onSkipToQueueItem] with the queue item before
  /// [AudioServiceBackground.mediaItem] if it exists.
  Future<void> onSkipToPrevious() => skip(-1);

  /// Called when a client has requested to fast forward, such as via a
  /// request to [AudioService.fastForward]. An implementation of this callback
  /// can use the [fastForwardInterval] property to determine how much audio
  /// to skip.
  Future<void> onFastForward() async {}

  /// Called when a client has requested to rewind, such as via a request to
  /// [AudioService.rewind]. An implementation of this callback can use the
  /// [rewindInterval] property to determine how much audio to skip.
  Future<void> onRewind() async {}

  /// Called when a client has requested to skip to a specific item in the
  /// queue, such as via a call to [AudioService.skipToQueueItem].
  Future<void> onSkipToQueueItem(String mediaId) async {}

  /// Called when a client has requested to seek to a position, such as via a
  /// call to [AudioService.seekTo]. If your implementation of seeking causes
  /// buffering to occur, consider broadcasting a buffering state via
  /// [AudioServiceBackground.setState] while the seek is in progress.
  Future<void> onSeekTo(Duration position) async {}

  /// Called when a client has requested to rate the current media item, such as
  /// via a call to [AudioService.setRating].
  Future<void> onSetRating(
      Rating rating, Map<dynamic, dynamic>? extras) async {}

  /// Called when a client has requested to change the current repeat mode.
  Future<void> onSetRepeatMode(AudioServiceRepeatMode repeatMode) async {}

  /// Called when a client has requested to change the current shuffle mode.
  Future<void> onSetShuffleMode(AudioServiceShuffleMode shuffleMode) async {}

  /// Called when a client has requested to either begin or end seeking
  /// backward.
  Future<void> onSeekBackward(bool begin) async {}

  /// Called when a client has requested to either begin or end seeking
  /// forward.
  Future<void> onSeekForward(bool begin) async {}

  /// Called when the Flutter UI has requested to set the speed of audio
  /// playback. An implementation of this callback should change the audio
  /// speed and broadcast the speed change to all clients via
  /// [AudioServiceBackground.setState].
  Future<void> onSetSpeed(double speed) async {}

  /// Called when a custom action has been sent by the client via
  /// [AudioService.customAction]. The result of this method will be returned
  /// to the client.
  Future<dynamic> onCustomAction(String name, dynamic arguments) async {}

  /// Called on Android when the user swipes away your app's task in the task
  /// manager. Note that if you use the `androidStopForegroundOnPause` option to
  /// [AudioService.start], then when your audio is paused, the operating
  /// system moves your service to a lower priority level where it can be
  /// destroyed at any time to reclaim memory. If the user swipes away your
  /// task under these conditions, the operating system will destroy your
  /// service, and you may override this method to do any cleanup. For example:
  ///
  /// ```dart
  /// Future<void> onTaskRemoved() {
  ///   if (!AudioServiceBackground.state.playing) {
  ///     await onStop();
  ///   }
  /// }
  /// ```
  Future<void> onTaskRemoved() async {}

  /// Called on Android when the user swipes away the notification. The default
  /// implementation (which you may override) calls [onStop]. Note that by
  /// default, the service runs in the foreground state which (despite the name)
  /// allows the service to run at a high priority in the background without the
  /// operating system killing it. While in the foreground state, the
  /// notification cannot be swiped away. You can pass a parameter value of
  /// `true` for `androidStopForegroundOnPause` in the [AudioService.start]
  /// method if you would like the service to exit the foreground state when
  /// playback is paused. This will allow the user to swipe the notification
  /// away while playback is paused (but it will also allow the operating system
  /// to kill your service at any time to free up resources).
  Future<void> onClose() => onStop();

  Future<void> skip(int offset);

  String getMediaId(T mediaItem);

  T convertRawMapToMediaItem(Map raw) {
    return mMediaTypeConverter.convertRawMapToMediaItem(raw);
  }

  List<T> convertRawListToMediaItemList(List rawList) {
    return mMediaTypeConverter.convertRawListToMediaItemList(rawList) as List<T>;
  }

  List convertMediaItemListToRawList(List<T> mediaItemList) {
    return mMediaTypeConverter.convertMediaItemListToRawList(mediaItemList);
  }

  void setParams({
    required Duration fastForwardInterval,
    required Duration rewindInterval,
  }) {
    _fastForwardInterval = fastForwardInterval;
    _rewindInterval = rewindInterval;
  }

}