
///音频播放接口
///不同的播放实现接口的具体播放功能
abstract class IAudioPlayer {

  ///设置网络数据源
  Future<void> setNetworkDataSource(String url);

  ///设置资源数据源
  void setAssetDataSource(String assetPath);

  ///设置文件数据源
  void setFileDataSource(String filePath);

  ///跳转播放进度到 [position]
  ///[position] -- 目标进度：单位是秒, 如1秒100毫秒=1.1s
  Future<void> seekTo(Duration position);

  ///播放
  Future<void> play();

  ///暂停
  Future<void> pause();

  ///重置播放器
  ///重置后需要重新设置数据源
  void reset();

  ///停止播放器
  ///暂停当前播放，播放进度回到开头
  Future<void> stop();

  ///释放资源
  void dispose();

  ///设置播放速度
  Future<void> setSpeed(double speed);

  ///获取播放速度
  double getSpeed();

  ///设置播放器音量
  ///[volume] -- 范围：0 ~ 100
  void setVolume(int volume);

  ///当前播放状态
  bool isPlaying();

  ///获取当前播放进度
  Future<Duration> getCurrentPosition();

  ///获取播放总时长
  Future<Duration> getDuration();
}