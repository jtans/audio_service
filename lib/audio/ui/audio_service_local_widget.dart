import 'package:audio_service/audio/controller/audio_service_controller_wrapper.dart';
import 'package:flutter/material.dart';

/// 主要使用于局部单独需要展示音频内容的界面，生命周期绑定当前页面
/// 应用场景：APP局部单页面与后台服务的通信
/// PS：关闭页面并不会杀掉 Service，只会断开当前页面与Service的通信连接
class AudioServiceLocalWidget extends StatefulWidget {
  final Widget child;
  final Function(bool)? onConnectResult;

  AudioServiceLocalWidget({required this.child, this.onConnectResult});

  @override
  _AudioServiceLocalWidgetState createState() => _AudioServiceLocalWidgetState();
}

class _AudioServiceLocalWidgetState extends State<AudioServiceLocalWidget> {

  @override
  void initState() {
    super.initState();
    AudioServiceControllerWrapper().connect(onConnectCallback: widget.onConnectResult);
  }

  @override
  void dispose() {
    AudioServiceControllerWrapper().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}