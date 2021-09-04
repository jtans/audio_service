import 'dart:async';
import 'dart:convert';
import 'package:fijkplayer/fijkplayer.dart';
import 'audio_player_interface.dart';

enum FKijkState {
  /// The state when a [FijkPlayer] is just created.
  /// Native ijkplayer memory and objects also be alloced or created when a [FijkPlayer] is created.
  ///
  /// * setDataSource()  -> [initialized]
  /// * reset()          -> self
  /// * release()        -> [end]
  idle,

  /// After call [FijkPlayer.setDataSource] on state [idle], the state becomes [initialized].
  ///
  /// * prepareAsync()   -> [asyncPreparing]
  /// * reset()          -> [idle]
  /// * release()        -> [end]
  initialized,

  /// There're many tasks to do during prepare, such as detect stream info in datasource, find and open decoder, start decode and refresh thread.
  /// So ijkplayer export a async api prepareAsync.
  /// When [FijkPlayer.prepareAsync] is called on state [initialized], ths state changed to [asyncPreparing] immediately.
  /// After all task in prepare have finished, the state changed to [prepared].
  /// Additionally, if any error occurs during prepare, the state will change to [error].
  ///
  /// * .....            -> [prepared]
  /// * .....            -> [error]
  /// * .....            -> [stopped]
  /// * reset()          -> [idle]
  /// * release()        -> [end]
  asyncPreparing,

  /// After finish all the heavy tasks during [FijkPlayer.prepareAsync],
  /// the state becomes [prepared] from [asyncPreparing].
  ///
  /// * seekTo()         -> self
  /// * start()          -> [started]
  /// * reset()          -> [idle]
  /// * release()        -> [end]
  prepared,

  /// * seekTo()         -> self
  /// * start()          -> self
  /// * pause()          -> [paused]
  /// * stop()           -> [stopped]
  /// * ......           -> [completed]
  /// * ......           -> [error]
  /// * reset()          -> [idle]
  /// * release()        -> [end]
  started,

  /// * seekTo()         -> self
  /// * start()          -> [started]
  /// * pause()          -> self
  /// * stop()           -> [stopped]
  /// * reset()          -> [idle]
  /// * release()        -> [end]
  paused,

  /// * seekTo()         -> [paused]
  /// * start()          -> [started] (from beginning)
  /// * pause()          -> self
  /// * stop()           -> [stopped]
  /// * reset()          -> [idle]
  /// * release()        -> [end]
  completed,

  /// * stop()           -> self
  /// * prepareAsync()   -> [asyncPreparing]
  /// * reset()          -> [idle]
  /// * release()        -> [end]
  stopped,

  /// * reset()          -> [idle]
  /// * release()        -> [end]
  error,

  /// * release()        -> self
  end
}

extension on FijkState {
  FKijkState get toFKijkState {
    return FKijkState.values[index];
  }
}

class FKIjkPlayer {
  FijkPlayer mediaController = FijkPlayer();
  double _mCurrentSpeed = 1.0;
  double width = 0;
  double height = 0;
  Duration currentPosition = Duration.zero;
  FijkValue ijkValue = FijkValue.uninitialized();
  VideoInfo? videoInfo;

  StreamController<VideoInfo> _streamControllerVideoInfo =
      StreamController.broadcast();
  Stream<VideoInfo>? get videoInfoStream => _streamControllerVideoInfo.stream;

  StreamController<bool> _streamControllerPlaying =
      StreamController.broadcast();
  Stream<bool>? get playingStream => _streamControllerPlaying.stream;

  StreamController<FKijkState> _streamControllerStatus =
      StreamController.broadcast();
  Stream<FKijkState>? get statusStream => _streamControllerStatus.stream;
  StreamSubscription? _streamSubscriptionCurrentPosUpdate;

  FKIjkPlayer() {
    //监听属性变化
    mediaController.addListener(_fijkValueListener);
    //监听当前播放位置
    _streamSubscriptionCurrentPosUpdate =
        mediaController.onCurrentPosUpdate.listen((event) {
      currentPosition = event;
      getVideoInfo().then((value) {
        _streamControllerVideoInfo.add(value);
      });
      _streamControllerPlaying.add(mediaController.state == FijkState.started);
    });
  }

  void dispose() {
    _streamSubscriptionCurrentPosUpdate?.cancel();
    mediaController.removeListener(_fijkValueListener);
    mediaController.dispose();
    mediaController.release();
    _streamControllerVideoInfo.close();
    _streamControllerPlaying.close();
    _streamControllerStatus.close();
  }

  void _fijkValueListener() {
    FijkValue value = mediaController.value;
    if (value.prepared) {
      width = value.size?.width ?? 0;
      height = value.size?.height ?? 0;
    }
    ijkValue = value;
    _streamControllerStatus.add(ijkValue.state.toFKijkState);
    _streamControllerPlaying.add(ijkValue.state == FijkState.started);
  }

  Future<void> seekToProgress(double progress) async {
    final d = await getDuration();
    int msec = (d.inMilliseconds * progress).toInt();
    await mediaController.seekTo(msec);
  }

  Future<void> setNetworkDataSource(String netUrl, {bool autoPlay = false}) async {
    await mediaController.setDataSource(netUrl, autoPlay: autoPlay);
  }

  void setAssetDataSource(String assetPath) {
    mediaController.setDataSource(assetPath);
  }

  void setFileDataSource(String filePath) {
    mediaController.setDataSource(filePath);
  }

  Future<void> seekTo(Duration position) async {
    mediaController.seekTo(position.inMilliseconds);
  }

  Future<void> play() async {
    await mediaController.start();
  }

  Future<void> pause() async {
    await mediaController.pause();
  }

  Future<void> reset() async {
    await mediaController.reset();
  }

  Future<void> stop() async {
    mediaController.stop();
  }

  ///支持的倍率默认为 1.0, 上限不明,下限请不要小于等于 0,否则可能会 crash
  Future<void> setSpeed(double speed) async {
    _mCurrentSpeed = speed;
    mediaController.setSpeed(speed);
  }

  double getSpeed() {
    return _mCurrentSpeed;
  }

  void setVolume(int volume) {
    mediaController.setVolume(volume.toDouble());
  }

  bool isPlaying() {
    return mediaController.state == FijkState.started;
  }

  Future<Duration> getCurrentPosition() async {
    return currentPosition;
  }

  Future<Duration> getDuration() async {
    return ijkValue.duration;
  }

  Future<VideoInfo> getVideoInfo() async {
    final info = VideoInfo.fromMap({
      "width": (ijkValue.size?.width ?? 0).toInt(),
      "height": (ijkValue.size?.height ?? 0).toInt(),
      "duration": ijkValue.duration.inSeconds.toDouble(),
      "currentPosition": currentPosition.inSeconds.toDouble(),
      "isPlaying": ijkValue.state == FijkState.started,
      "degree": 0,
      "tcpSpeed": 0
    });
    videoInfo = info;
    return info;
  }
}

/// IJK媒体播放器
/// TODO xiong -- 补充：补充音频播放状态等回调接口
class IjkAudioPlayer implements IAudioPlayer {
  FKIjkPlayer mediaController;

  Stream<VideoInfo>? videoInfoStream;
  Stream<FKijkState>? statusStream;
  StreamSubscription? _streamSubscriptionCurrentPosUpdate;

  IjkAudioPlayer(this.mediaController): this.videoInfoStream = mediaController.videoInfoStream, this.statusStream = mediaController.statusStream;

  @override
  Future<void> setNetworkDataSource(String netUrl) async {
    await mediaController.setNetworkDataSource(netUrl);
  }

  @override
  void setAssetDataSource(String assetPath) {
    mediaController.setAssetDataSource(assetPath);
  }

  @override
  void setFileDataSource(String filePath) {
    mediaController.setFileDataSource(filePath);
  }

  @override
  Future<void> seekTo(Duration position) async {
    mediaController.seekTo(position);
  }

  @override
  Future<void> play() async {
    await mediaController.play();
  }

  @override
  Future<void> pause() async {
    await mediaController.pause();
  }

  @override
  Future<void> reset() async {
    await mediaController.reset();
  }

  @override
  Future<void> stop() async {
    mediaController.stop();
  }

  @override
  void dispose() {
    mediaController.dispose();
  }

  ///支持的倍率默认为 1.0, 上限不明,下限请不要小于等于 0,否则可能会 crash
  @override
  Future<void> setSpeed(double speed) async {
    mediaController.setSpeed(speed);
  }

  double getSpeed() {
    return mediaController.getSpeed();
  }

  @override
  void setVolume(int volume) {
    mediaController.setVolume(volume);
  }

  @override
  bool isPlaying() {
    return mediaController.isPlaying();
  }

  @override
  Future<Duration> getCurrentPosition() async {
    return mediaController.currentPosition;
  }

  @override
  Future<Duration> getDuration() async {
    return mediaController.getDuration();
  }

  Future<VideoInfo> getVideoInfo() async {
    return mediaController.getVideoInfo();
  }
}

/// about video info
class VideoInfo {
  /// Width of Video
  int? width;

  /// Height of Video
  int? height;

  /// Total length of video
  double duration = 0;

  /// Current playback progress
  double? currentPosition;

  /// In play
  bool isPlaying = false;

  /// Degree of Video
  int? degree;

  /// The media tcp speed, unit is byte
  int? tcpSpeed;

  Map<String, dynamic>? _map;

  /// Percentage playback progress
  double get progress => (currentPosition ?? 0) / duration;

  ///Is there any information?
  bool get hasData => _map != null;

  /// Aspect ratio
  double get ratio {
    double r;
    if (width != null && height != null) {
      if (width == 0 || height == 0) {
        r = 1280 / 720;
      } else {
        r = width! / height!;
      }
    } else {
      r = 1280 / 720;
    }

    return r;
  }

  /// Constructing from the native method
  VideoInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return;
    }
    this._map = map;
    this.width = map["width"];
    this.height = map["height"];
    this.duration = map["duration"];
    this.currentPosition = map["currentPosition"];
    this.isPlaying = map["isPlaying"];
    this.degree = map["degree"];
    this.tcpSpeed = map["tcpSpeed"];
  }

  @override
  String toString() {
    if (_map == null) {
      return "null";
    }
    return json.encode(_map);
  }
}
