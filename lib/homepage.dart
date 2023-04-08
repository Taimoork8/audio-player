import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'package:app_settings/app_settings.dart';
import 'package:url_launcher/url_launcher.dart';

bool rateus = false;
AlertDialog alert = const AlertDialog();
SharedPreferences prefs = SharedPreferences.getInstance() as SharedPreferences;
double currentvol = 0.5;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  bool _mPlayerIsInited = false;
  late Stopwatch _stopwatch;
  late Timer _timer;
  int _counter = 0;
  final Uri _url = Uri.parse('market://details?id=com.hairstyles.menhairstyle');

  Future<void> open() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    // Be careful : openAudioSession returns a Future.
    // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
    await _mPlayer!.openAudioSession();

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    setState(() {
      _mPlayerIsInited = true;
    });
  }

  void loadCounter() async {
    prefs = await SharedPreferences.getInstance();
    // rateus = prefs.getBool('Rateus')!;
    setState(() {
      _counter = ((prefs.getInt('counter') ?? 0));
      rateus = ((prefs.getBool('Rateus') ?? false));
      if (_counter < 2) {
        _counter++;
      } else if (_counter == 2) {
        if (rateus) {
          // once show than don't show it again
          Navigator.of(context).pop();
        }
        _counter = 0;
      } else {
        _counter = 0;
      }
      prefs.setBool('rateus', rateus);
      prefs.setInt('counter', _counter);
      dev.log('counter  : $_counter');
    });
  }

  @override
  void initState() {
    PerfectVolumeControl.hideUI =
        false; //set if system UI is hided or not on volume up/down
    Future.delayed(Duration.zero, () async {
      currentvol = await PerfectVolumeControl.getVolume();

      setState(() {
        //refresh UI
      });
    });

    PerfectVolumeControl.stream.listen((volume) {
      setState(() {
        currentvol = volume;
      });
    });

    _stopwatch = Stopwatch();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {});
    });
    open();
    loadCounter();
    // log('counter : $_counter');
    super.initState();
  }

  @override
  void dispose() {
    stopPlayer();
    // Be careful : you must `close` the audio session when you have finished with it.
    _mPlayer!.closeAudioSession();
    _mPlayer = null;
    _timer.cancel();
    super.dispose();
  }

  // -------  Here is the code to play from the microphone -------

  void play() async {
    await _mPlayer!.startPlayerFromMic();
    setState(() {});
  }

  Future<void> stopPlayer() async {
    if (_mPlayer != null) {
      await _mPlayer!.stopPlayer();
    }
  }

  // ----------------------

  getPlaybackFn() {
    if (_mPlayer!.isPlaying) {
      _stopwatch.start();
    } else {
      _stopwatch.reset();
    }
    if (!_mPlayerIsInited) {
      return null;
    }
    return _mPlayer!.isStopped
        ? play
        : () {
            stopPlayer().then(
              (value) => setState(
                () {},
              ),
            );
          };
  }

  void handleStartStop() {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
    } else {
      _stopwatch.stop();
    }
    setState(() {
      _stopwatch.reset();
    }); // re-render the page
  }

  @override
  Widget build(BuildContext context) {
    Widget makeBody() {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  formatTime(_stopwatch.elapsedMilliseconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 50.0,
                  ),
                ),
                const SizedBox(
                  height: 25.0,
                ),
                SizedBox(
                  height: 200.0,
                  width: 150.0,
                  child: TextButton(
                    onPressed: getPlaybackFn(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const CircleBorder(),
                    ),
                    child: Text(
                      _mPlayer!.isPlaying ? 'Stop' : 'Play',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: const CircleBorder(
                              side: BorderSide(width: 2.0),
                            ),
                          ),
                          child: const Icon(
                            Icons.bluetooth,
                            size: 50.0,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            AppSettings.openBluetoothSettings();
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 175.0,
                      ),
                      SizedBox(
                        height: 70.0,
                        width: 70.0,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            // foregroundColor: Colors.pink,
                            shape:
                                const CircleBorder(side: BorderSide(width: 2)),
                          ),
                          onPressed: () async {},
                          child: const Text(
                            'Rate us',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.teal,
        appBar: AppBar(
          backgroundColor: Colors.teal,
          title: const Center(
            child: Text('Mic'),
          ),
        ),
        body: makeBody(),
      ),
    );
  }
}
