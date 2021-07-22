import 'dart:ui';

import 'package:audio_service/audio/controller/audio_service_controller.dart';
import 'package:audio_service/audio/converter/audio_media_type_converter.dart';
import 'package:audio_service/audio/media/audio_media_resource.dart';

///音频控制器包装类，主要用于上层与 BackgroundTask 音频后台服务通信
///TODO xiong -- 优化：能否继承该类重载构造函数，实现不同数据源 MediaItem 的变更
class AudioServiceControllerWrapper {
  late AudioServiceController mAudioServiceController;

  AudioServiceControllerWrapper._privateConstructor() {
    mAudioServiceController = AudioServiceController<MediaItem>(
        typeConverter: AudioMediaTypeConverter());
  }

  static final AudioServiceControllerWrapper _instance =
      AudioServiceControllerWrapper._privateConstructor();

  factory AudioServiceControllerWrapper() {
    return _instance;
  }

  ///音频播放状态回调
  Stream<PlaybackState> get playbackStateStream =>
      mAudioServiceController.playbackStateStream;

  ///播放队列回调
  Stream<List<MediaItem>?> get queueStream =>
      mAudioServiceController.queueStream as Stream<List<MediaItem>?>;

  ///当前播放的媒体文件
  Stream<MediaItem?> get currentMediaItemStream =>
      mAudioServiceController.currentMediaItemStream as Stream<MediaItem?>;

  ///自定义事件回调
  Stream<dynamic> get customEventStream =>
      AudioServiceController.customEventStream;

  ///通知栏点击事件
  Stream<bool> get notificationClickEventStream =>
      mAudioServiceController.notificationClickEventStream;

  // static AudioServiceControllerDelegate get instance => _instance;

  Future<bool> start({
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
  }) {
    return mAudioServiceController.start(
      backgroundTask: backgroundTask,
      params: params,
      androidNotificationChannelName: androidNotificationChannelName,
      androidNotificationChannelDescription: androidNotificationChannelDescription,
      androidNotificationColor: androidNotificationColor,
      androidNotificationIcon: androidNotificationIcon,
      androidShowNotificationBadge: androidShowNotificationBadge,
      androidNotificationClickStartsActivity: androidNotificationClickStartsActivity,
      androidNotificationOngoing: androidNotificationOngoing,
      androidResumeOnClick: androidResumeOnClick,
      androidStopForegroundOnPause: androidStopForegroundOnPause,
      androidEnableQueue: androidEnableQueue,
      androidArtDownscaleSize: androidArtDownscaleSize,
      fastForwardInterval: fastForwardInterval,
      rewindInterval: rewindInterval,
    );
  }

  Future<void> connect({Function(bool)? onConnectCallback}) {
    return mAudioServiceController.connect(onConnectCallback : onConnectCallback);
  }

  Future<void> disconnect() => mAudioServiceController.disconnect();

  Future<void> prepare() async {
    mAudioServiceController.prepare();
  }

  Future<void> prepareFromMediaId(String mediaId) async {
    mAudioServiceController.prepareFromMediaId(mediaId);
  }

  ///播放
  Future<void> play() async {
    mAudioServiceController.play();
  }

  Future<void> playFromMediaId(String mediaId) async {
    mAudioServiceController.playFromMediaId(mediaId);
  }

  ///暂停播放
  Future<void> pause() async {
    mAudioServiceController.pause();
  }

  ///停止服务
  Future<void> stop() async {
    mAudioServiceController.stop();
  }

  ///跳转
  Future<void> seekTo(Duration position) async {
    mAudioServiceController.seekTo(position);
  }

  ///下一小节
  Future<void> skipToNext() async {
    mAudioServiceController.skipToNext();
  }

  ///上一小节
  Future<void> skipToPrevious() async {
    mAudioServiceController.skipToPrevious();
  }

  ///快进
  Future<void> fastForward() async {
    mAudioServiceController.fastForward();
  }

  ///快退
  Future<void> rewind() async {
    mAudioServiceController.rewind();
  }

  ///倍速
  Future<void> setSpeed(double speed) async {
    mAudioServiceController.setSpeed(speed);
  }

  ///速率
  Future<void> setRating(Rating rating) async {
    mAudioServiceController.setRating(rating);
  }

  ///自定义命令
  Future customAction(String name, [dynamic arguments]) async {
    mAudioServiceController.customAction(name, arguments);
  }
}
