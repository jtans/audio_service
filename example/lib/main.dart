import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio/background/audio_service_background.dart';
import 'package:audio_service/audio/background/task_audio_background_player.dart';
import 'package:audio_service/audio/controller/audio_service_controller_wrapper.dart';
import 'package:audio_service/audio/media/audio_media_resource.dart';
import 'package:audio_service/audio/ui/audio_service_local_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Service Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _MainScreenState();
  }

  // MainScreen(BuildContext context) {
  //   print("xiong -- MainScreen Create, 是否通过通知栏跳转音频页：${AudioServiceControllerWrapper.hasNotificationClick}");
  //   if (AudioServiceControllerWrapper.hasNotificationClick) {
  //     print("xiong -- MainScreen 跳转音频页");
  //     Navigator.push(context, MaterialPageRoute(builder: (context) {
  //       return AudioPlayerPageRoute();
  //     }));
  //   }
  //   AudioServiceControllerWrapper.notificationClickEventStream.listen((event) {
  //     print("xiong -- MainScreen notificationClick = $event");
  //     if (event == true) {
  //       print("xiong -- MainScreen 接收到通知栏回调，跳转音频页");
  //       Navigator.push(context, MaterialPageRoute(builder: (context) {
  //         return AudioPlayerPageRoute();
  //       }));
  //     }
  //   });
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Audio Service Demo - Refactor'),
  //     ),
  //     body: Center(
  //       child: Column(
  //         children: [
  //           RaisedButton(
  //             onPressed: () {
  //               Navigator.push(context, MaterialPageRoute(builder: (context) {
  //                 return AudioPlayerPageRoute();
  //               }));
  //             },
  //             child: Text('跳转音频播放页'),
  //           ),
  //           // StreamBuilder<bool>(
  //           //   stream: AudioServiceControllerWrapper().notificationClickEventStream,
  //           //   builder: (context, snapshot) {
  //           //     if(snapshot.data != null && snapshot.data == true) {
  //           //       print("xiong -- AudioServiceController notificationClickEventStream 跳转音频播放页"
  //           //           ", Notification Click Status: ${snapshot.data}");
  //           //       Navigator.push(context, MaterialPageRoute(builder: (context) {
  //           //         return AudioPlayerPageRoute();
  //           //       }));
  //           //     }
  //           //     return Text(
  //           //       'Notification Click Status: ${snapshot.data}',
  //           //     );
  //           //   },
  //           // ),
  //         ],
  //       )
  //     ),
  //   );
  // }
}

class _MainScreenState extends State<MainScreen> {

  @override
  void initState() {
    super.initState();
    print("xiong -- MainScreen initState, 是否通过通知栏跳转音频页：${AudioServiceControllerWrapper.hasNotificationClick}");
    if (AudioServiceControllerWrapper.hasNotificationClick) {
      print("xiong -- MainScreen 跳转音频页");
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return AudioPlayerPageRoute();
      }));
    }
    AudioServiceControllerWrapper.notificationClickEventStream.listen((event) {
      print("xiong -- MainScreen notificationClick = $event");
      if (event == true) {
        print("xiong -- MainScreen 接收到通知栏回调，跳转音频页");
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return AudioPlayerPageRoute();
        }));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Service Demo - Refactor'),
      ),
      body: Center(
          child: Column(
            children: [
              RaisedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return AudioPlayerPageRoute();
                  }));
                },
                child: Text('跳转音频播放页'),
              ),
              // StreamBuilder<bool>(
              //   stream: AudioServiceControllerWrapper().notificationClickEventStream,
              //   builder: (context, snapshot) {
              //     if(snapshot.data != null && snapshot.data == true) {
              //       print("xiong -- AudioServiceController notificationClickEventStream 跳转音频播放页"
              //           ", Notification Click Status: ${snapshot.data}");
              //       Navigator.push(context, MaterialPageRoute(builder: (context) {
              //         return AudioPlayerPageRoute();
              //       }));
              //     }
              //     return Text(
              //       'Notification Click Status: ${snapshot.data}',
              //     );
              //   },
              // ),
            ],
          )
      ),
    );
  }
}


List<String> mp3List = [
  "https://listen.10155.com/listener/womusic-bucket/education/20210311/082bcd475df34d37be735a8bdf443a4a.mp3?clientUser=N/A&channelid=3000007292&contentid=2068&tokenid=E71D6B1F48B9CE0D2214BBAEC79D6737&timestamp=1627875788&resolution=origin&isSegment=0",
  "http://antiserver.kuwo.cn/anti.s?useless=/resource/&format=mp3&rid=MUSIC_71115353&response=res&type=convert_url&",
  "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3",
  "https://s3.amazonaws.com/scifri-segments/scifri201711241.mp3",
];

//音频播放页面
class AudioPlayerPageRoute extends StatefulWidget {

  @override
  _AudioPlayerState createState() {
    return _AudioPlayerState();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text('音频播放页'),
  //       leading: IconButton(
  //         icon: Icon(
  //           Icons.arrow_back_sharp,
  //           color: Colors.white,
  //         ),
  //         onPressed: () {
  //           if (Navigator.canPop(context)) {
  //             Navigator.pop(context);
  //           }
  //         },
  //       ),
  //     ),
  //     body: Center(
  //       child: AudioServiceLocalWidget(
  //         child: AudioPlayerWidget(),
  //         onConnectResult: (success) {
  //           print("xiong --- MusicService connect result = $success");
  //           AudioServiceControllerWrapper().start(
  //             backgroundTask: _audioPlayerTaskEntryPoint,
  //             androidNotificationChannelName: 'Audio Service Demo',
  //             // Enable this if you want the Android service to exit the foreground state on pause.
  //             androidStopForegroundOnPause: true,
  //             androidNotificationColor: 0xFF2196f3,
  //             androidNotificationIcon: 'mipmap/ic_launcher',
  //             androidEnableQueue: true,
  //           ).then((value) {
  //               print("xiong --- MusicService start result = $value");
  //               if (value) {
  //                 AudioServiceControllerWrapper().customAction(
  //                     CUSTOM_CMD_ADD_MP3_RES, mp3List); //MediaLibrary().items
  //               }
  //             },
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }
}

class _AudioPlayerState extends State<AudioPlayerPageRoute> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('音频播放页'),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_sharp,
            color: Colors.white,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Center(
        child: AudioServiceLocalWidget(
          child: AudioPlayerWidget(),
          onConnectResult: (success) {
            print("xiong --- MusicService connect result = $success");
            AudioServiceControllerWrapper().start(
              backgroundTask: _audioPlayerTaskEntryPoint,
              androidNotificationChannelName: 'Audio Service Demo',
              // Enable this if you want the Android service to exit the foreground state on pause.
              androidStopForegroundOnPause: true,
              androidNotificationColor: 0xFF2196f3,
              androidNotificationIcon: 'mipmap/ic_launcher',
              androidEnableQueue: true,
            ).then((value) {
              print("xiong --- MusicService start result = $value");
              if (value || AudioServiceControllerWrapper().isRunning) {
                AudioServiceControllerWrapper().customAction(
                    CUSTOM_CMD_ADD_MP3_RES, mp3List); //MediaLibrary().items
              }
            },
            );
          },
        ),
      ),
    );
  }

}

class AudioPlayerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // return Center(
    // child: StreamBuilder<bool>(
    //   stream: AudioServiceControllerWrapper().runningStream,
    //   builder: (context, snapshot) {
    //     print("xiong -- running = ${snapshot.data}");
    //     if (snapshot.connectionState != ConnectionState.active) {
    //       // Don't show anything until we've ascertained whether or not the
    //       // service is running, since we want to show a different UI in
    //       // each case.
    //       return SizedBox();
    //     }
    //     final running = snapshot.data ?? false;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
//               if (!running) ...[
//                 // UI to show when we're not running, i.e. a menu.
//                 audioPlayerButton(),
// //                  if (kIsWeb || !Platform.isMacOS) textToSpeechButton(),
//               ] else ...[

        // audioPlayerButton(),

        // UI to show when we're running, i.e. player state/controls.
        // Queue display/controls.
        StreamBuilder<QueueState>(
          stream: _queueStateStream,
          builder: (context, snapshot) {
            final queueState = snapshot.data;
            final queue = queueState?.queue ?? [];
            final mediaItem = queueState?.mediaItem;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (queue.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.skip_previous),
                        iconSize: 64.0,
                        onPressed: mediaItem == queue.first
                            ? null
                            : AudioServiceControllerWrapper().skipToPrevious,
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_next),
                        iconSize: 64.0,
                        onPressed: mediaItem == queue.last
                            ? null
                            : AudioServiceControllerWrapper().skipToNext,
                      ),
                    ],
                  ),
                if (mediaItem?.title != null) Text(mediaItem!.title),
              ],
            );
          },
        ),
        // Play/pause/stop buttons.
        StreamBuilder<bool>(
          stream: AudioServiceControllerWrapper()
              .playbackStateStream
              .map((state) => state.playing)
              .distinct(),
          builder: (context, snapshot) {
            final playing = snapshot.data ?? false;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (playing) pauseButton() else playButton(),
                stopButton(),
              ],
            );
          },
        ),
        // A seek bar.
//                StreamBuilder<MediaState>(
//                  stream: _mediaStateStream,
//                  builder: (context, snapshot) {
//                    final mediaState = snapshot.data;
//                    return SeekBar(
//                      duration:
//                      mediaState?.mediaItem?.duration ?? Duration.zero,
//                      position: mediaState?.position ?? Duration.zero,
//                      onChangeEnd: (newPosition) {
//                        AudioServiceControllerWrapper().seekTo(newPosition);
//                      },
//                    );
//                  },
//                ),
        StreamBuilder<PlaybackState>(
            stream: AudioServiceControllerWrapper().playbackStateStream,
            builder: (context, snapshot) {
              Duration duration = Duration(seconds: (snapshot.data?.extras?[EXTRA_PLAYER_DURATION] ?? 0) as int);
              Duration position = snapshot.data?.position == null ? Duration.zero : snapshot.data!.position;
              // print("xiong -- Background Audio Controller duration = $duration, position = $position");
              return Column(
                children: [
                  SeekBar(
                    duration: duration,
                    position: position,
                    onChangeEnd: (newPosition) {
                      AudioServiceControllerWrapper().seekTo(newPosition);
                    },
                  ),
                ],
              );
            }),
        // Display the processing state.
        StreamBuilder<AudioProcessingState>(
          stream: AudioServiceControllerWrapper()
              .playbackStateStream
              .map((state) => state.processingState)
              .distinct(),
          builder: (context, snapshot) {
            final processingState = snapshot.data ?? AudioProcessingState.none;
            return Text("Processing state: ${describeEnum(processingState)}");
          },
        ),
        // Display the latest custom event.
        StreamBuilder(
          stream: AudioServiceControllerWrapper().customEventStream,
          builder: (context, snapshot) {
            return Text("custom event: ${snapshot.data}");
          },
        ),
        // Display the notification click status.
        StreamBuilder<bool>(
          stream: AudioServiceControllerWrapper.notificationClickEventStream,
          builder: (context, snapshot) {
            // if(snapshot.data != null && snapshot.data == true) {
            //   print("xiong -- AudioServiceController notificationClickEventStream 跳转音频播放页"
            //       ", Notification Click Status: ${snapshot.data}");
            //   Navigator.push(context, MaterialPageRoute(builder: (context) {
            //     return AudioPlayerPageRoute();
            //   }));
            // }
            return Text(
              'Notification Click Status: ${snapshot.data}',
            );
          },
        ),
        // ],
      ],
      // );
      // },
      // ),
    );
  }

  ElevatedButton audioPlayerButton() => startButton(
        'AudioPlayer',
        () {
          AudioServiceControllerWrapper()
              .start(
            backgroundTask: _audioPlayerTaskEntryPoint,
            androidNotificationChannelName: 'Audio Service Demo',
            // Enable this if you want the Android service to exit the foreground state on pause.
            androidStopForegroundOnPause: true,
            androidNotificationColor: 0xFF2196f3,
            androidNotificationIcon: 'mipmap/ic_launcher',
            androidEnableQueue: true,
          ).then((value) {
              print("xiong --- MusicService start result = $value");
              if (value ) {
                AudioServiceControllerWrapper().customAction(
                    CUSTOM_CMD_ADD_MP3_RES, mp3List); //MediaLibrary().items
              }
            },
          );
        },
      );

  ElevatedButton startButton(String label, VoidCallback onPressed) =>
      ElevatedButton(
        child: Text(label),
        onPressed: onPressed,
      );

  IconButton playButton() => IconButton(
        icon: Icon(Icons.play_arrow),
        iconSize: 64.0,
        onPressed: AudioServiceControllerWrapper().play,
      );

  IconButton pauseButton() => IconButton(
        icon: Icon(Icons.pause),
        iconSize: 64.0,
        onPressed: AudioServiceControllerWrapper().pause,
      );

  IconButton stopButton() => IconButton(
        icon: Icon(Icons.stop),
        iconSize: 64.0,
        onPressed: AudioServiceControllerWrapper().stop,
      );
}

// NOTE: Your entrypoint MUST be a top-level function.
void _audioPlayerTaskEntryPoint() async {
  AudioServiceBackground().run(() => AudioPlayerBackgroundTask());
}

/// A stream reporting the combined state of the current media item and its
/// current position.
// Stream<MediaState> get _mediaStateStream =>
//     Rx.combineLatest2<MediaItem?, Duration, MediaState>(
//         AudioServiceControllerWrapper().currentMediaItemStream,
//         AudioServiceControllerWrapper().positionStream,
//             (mediaItem, position) => MediaState(mediaItem, position));

/// A stream reporting the combined state of the current queue and the current
/// media item within that queue.
Stream<QueueState> get _queueStateStream =>
    Rx.combineLatest2<List<MediaItem>?, MediaItem?, QueueState>(
        AudioServiceControllerWrapper().queueStream,
        AudioServiceControllerWrapper().currentMediaItemStream,
        (queue, mediaItem) => QueueState(queue, mediaItem));

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  SeekBar({
    required this.duration,
    required this.position,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  _SeekBarState createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final value = min(_dragValue ?? widget.position.inMilliseconds.toDouble(),
        widget.duration.inMilliseconds.toDouble());
    if (_dragValue != null && !_dragging) {
      _dragValue = null;
    }
    return Stack(
      children: [
        Slider(
          min: 0.0,
          max: widget.duration.inMilliseconds.toDouble(),
          value: value,
          onChanged: (value) {
            if (!_dragging) {
              _dragging = true;
            }
            setState(() {
              _dragValue = value;
            });
            if (widget.onChanged != null) {
              widget.onChanged!(Duration(milliseconds: value.round()));
            }
          },
          onChangeEnd: (value) {
            if (widget.onChangeEnd != null) {
              widget.onChangeEnd!(Duration(milliseconds: value.round()));
            }
            _dragging = false;
          },
        ),
        Positioned(
          right: 16.0,
          bottom: 0.0,
          child: Text(
              RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                      .firstMatch("$_remaining")
                      ?.group(1) ??
                  '$_remaining',
              style: Theme.of(context).textTheme.caption),
        ),
      ],
    );
  }

  Duration get _remaining => widget.duration - widget.position;
}
