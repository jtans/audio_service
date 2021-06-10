
import 'dart:io';

import 'package:audio_service/audio/player/audio_player_interface.dart';
import 'package:flutter_ijkplayer/flutter_ijkplayer.dart';

/// IJK媒体播放器
/// TODO xiong -- 补充：补充音频播放状态等回调接口
class IjkAudioPlayer implements IAudioPlayer {

  IjkMediaController mediaController;

  IjkAudioPlayer(this.mediaController);

  @override
  void setNetworkDataSource(String netUrl) {
    mediaController.setNetworkDataSource(netUrl);
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
  void seekTo(double position) {
    mediaController.seekTo(position);
  }

  @override
  void play() {
    mediaController.play();
  }

  @override
  void pause() {
    mediaController.pause();
  }

  @override
  void reset() {
    mediaController.reset();
  }

  @override
  void stop() {
    mediaController.stop();
  }

  @override
  void dispose() {
    mediaController.dispose();
  }

  ///支持的倍率默认为 1.0, 上限不明,下限请不要小于等于 0,否则可能会 crash
  @override
  void setSpeed(double speed) {
    mediaController.setSpeed(speed);
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
  Future<double> getCurrentPosition() async {
    return await mediaController.getVideoInfo().then((value) => value.currentPosition ?? 0);
  }

  @override
  Future<double> getDuration() async {
    return await mediaController.getVideoInfo().then((value) => value.duration);
  }

}