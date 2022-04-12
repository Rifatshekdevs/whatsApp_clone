// ignore_for_file: unrelated_type_equality_checks

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zapp_app/common/common.dart';

class PlayAudio extends StatefulWidget {
  final String? url;
  final Color? color;

  const PlayAudio({Key? key, this.url, this.color}) : super(key: key);

  @override
  _PlayAudioState createState() => _PlayAudioState();
}

class _PlayAudioState extends State<PlayAudio> {
  //for audio files
  late AudioCache audioCache;
  AudioPlayer audioPlayer = AudioPlayer();
  Duration _duration = new Duration();
  Rx<Duration> _position = new Duration(seconds: 0).obs;

  @override
  void initState() {
    super.initState();
    //for audio inside initState
    audioCache = new AudioCache(fixedPlayer: audioPlayer);
    audioPlayer.onDurationChanged.listen((Duration d) {
      print('Max duration: $d');
      setState(() => _duration = d);
    });

    audioPlayer.onAudioPositionChanged.listen((Duration p) {
      setState(() => _position.value = p);
    });

    audioPlayer.onPlayerCompletion.listen((event) {
      setState(() {
        audioPlayer.seek(Duration.zero);
      });
    });

    print('audio widget: ' + widget.url!);
    Common.audioPlayersList.add(CustomAudioModel(audioPlayer.playerId, audioPlayer));
  }

  @override
  void dispose() {
    super.dispose();
    audioPlayer.dispose();
  }

  void seekToSeconds(int second) {
    Duration newDuration = Duration(seconds: second);
    audioPlayer.seek(newDuration);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              print(audioPlayer.playerId);

              for (int i = 0; i < Common.audioPlayersList.length; i++) {
                CustomAudioModel model = Common.audioPlayersList[i];
                print(audioPlayer.state.toString() + " : " + model.id + " : " + audioPlayer.playerId);
                if (model.id != audioPlayer.playerId) {
                  model.audioPlayer.pause();
                } else {
                  if (audioPlayer.state == PlayerState.PLAYING) {
                    audioPlayer.pause();
                  } else {
                    audioPlayer.play(widget.url!);
                  }
                }

                setState(() {});
              }
            },
            child: Icon(
              audioPlayer.state == PlayerState.PLAYING ? Icons.pause : Icons.play_arrow,
              size: 20,
              color: widget.color,
            ),
          ),
          Container(
            width: 170,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 30,
                  child: SliderTheme(
                    data: SliderThemeData(thumbColor: widget.color, thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7)),
                    child: Slider(
                      activeColor: widget.color,
                      inactiveColor: Colors.grey,
                      value: _position.value.inSeconds.toDouble(),
                      max: _duration.inSeconds.toDouble(),
                      onChanged: (double value) {
                        seekToSeconds(value.toInt());
                        value = value;
                      },
                    ),
                  ),
                ),
                Obx(() {
                  return Padding(
                    padding: const EdgeInsets.only(left: 25),
                    child: Text(
                      _position == Duration.zero
                          ? widget.url!.split("(").last
                          : _position.value.inHours > 0
                              ? "${_position.toString().split(":")[0]}:${_position.toString().split(":")[1]}:${_position.toString().split(":")[2]}"
                              : "${_position.toString().split(":")[1]}:${_position.toString().split(":")[2].split(".").first}",
                      style: TextStyle(fontSize: 13, color: widget.color, fontWeight: FontWeight.bold),
                    ),
                  );
                })
              ],
            ),
          ),
        ],
      ),
    );
  }
}
