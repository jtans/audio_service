
import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'audio_player_interface.dart';
import 'package:flutter_ijkplayer/flutter_ijkplayer.dart';

/// IJK媒体播放器
/// TODO xiong -- 补充：补充音频播放状态等回调接口
class IjkAudioPlayer implements IAudioPlayer {

  IjkMediaController mediaController;
  double _mCurrentSpeed = 1.0;

  Stream<VideoInfo>? videoInfoStream;
  Stream<IjkStatus>? statusStream;

  IjkAudioPlayer(this.mediaController) :
        videoInfoStream = mediaController.videoInfoStream,
        statusStream = mediaController.ijkStatusStream;


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
    mediaController.setFileDataSource(File(filePath));
  }

  @override
  Future<void> seekTo(Duration position) async {
    mediaController.seekTo(position.inSeconds.toDouble());
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
    _mCurrentSpeed = speed;
    mediaController.setSpeed(speed);
  }

  double getSpeed() {
    return _mCurrentSpeed;
  }

  @override
  void setVolume(int volume) {
    mediaController.setSystemVolume(volume);
  }

  @override
  bool isPlaying() {
    return mediaController.isPlaying;
  }

  @override
  Future<Duration> getCurrentPosition() async {
    return await mediaController.getVideoInfo().then((value) => Duration(seconds: (value.currentPosition ?? 0).toInt()));
  }

  @override
  Future<Duration> getDuration() async {
    return await mediaController.getVideoInfo().then((value) => Duration(seconds: value.duration.toInt()));
  }

}