import 'package:audio_service/audio/controller/audio_service_controller_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio/controller/audio_service_controller.dart';

/// A widget that maintains a connection to [AudioServiceController].
///
/// Insert this widget at the top of your `/` route's widget tree to maintain
/// the connection across all routes. e.g.
///
/// ```
/// return MaterialApp(
///   home: AudioServiceGlobalWidget(MainScreen()),
/// );
/// ```
///
/// Note that this widget will not work if it wraps around [MateriaApp] itself,
/// you must place it in the widget tree within your route.
///
/// 主要使用于整个APP，生命周期绑定整个APP
/// 应用场景：APP内部全局保持与后台服务的通信
class AudioServiceGlobalWidget extends StatefulWidget {
  final Widget child;

  AudioServiceGlobalWidget({required this.child});

  @override
  _AudioServiceGlobalWidgetState createState() => _AudioServiceGlobalWidgetState();
}

class _AudioServiceGlobalWidgetState extends State<AudioServiceGlobalWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    AudioServiceControllerWrapper().connect();
  }

  @override
  void dispose() {
    AudioServiceControllerWrapper().disconnect();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        AudioServiceControllerWrapper().connect();
        break;
      case AppLifecycleState.paused:
        AudioServiceControllerWrapper().disconnect();
        break;
      default:
        break;
    }
  }

  @override
  Future<bool> didPopRoute() async {
    AudioServiceControllerWrapper().disconnect();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}