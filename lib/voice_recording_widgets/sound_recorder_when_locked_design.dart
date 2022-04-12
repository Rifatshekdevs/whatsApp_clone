library social_media_recorder;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zapp_app/provider/sound_record_notifier.dart';
import 'package:zapp_app/voice_recording_widgets/show_counter.dart';

class SoundRecorderWhenLockedDesign extends StatelessWidget {
  final SoundRecordNotifier soundRecordNotifier;
  final String? cancelText;
  final Function sendRequestFunction;
  final Widget? recordIconWhenLockedRecord;
  final TextStyle? cancelTextStyle;
  final TextStyle? counterTextStyle;
  final Color recordIconWhenLockBackGroundColor;

  SoundRecorderWhenLockedDesign({
    required this.soundRecordNotifier,
    required this.cancelText,
    required this.sendRequestFunction,
    required this.recordIconWhenLockedRecord,
    required this.cancelTextStyle,
    required this.counterTextStyle,
    required this.recordIconWhenLockBackGroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 20,
      child: Row(
        children: [
          InkWell(
            onTap: () async {
              soundRecordNotifier.isShow = false;
              if (soundRecordNotifier.second > 1 || soundRecordNotifier.minute > 0) {
                String path = soundRecordNotifier.mPath;
                await Future.delayed(Duration(milliseconds: 500));
                sendRequestFunction(
                  File.fromUri(Uri(path: path)),
                  "${soundRecordNotifier.minute > 9 ? soundRecordNotifier.minute.toString() : "0" + soundRecordNotifier.minute.toString()}"
                  ":${soundRecordNotifier.second > 9 ? soundRecordNotifier.second.toString() : "0" + soundRecordNotifier.second.toString()}",
                );
              }
              soundRecordNotifier.resetEdgePadding();
            },
            child: Transform.scale(
              scale: 1.2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(600),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeIn,
                  width: 50,
                  height: 50,
                  child: Container(
                    color: recordIconWhenLockBackGroundColor,
                    child: Padding(
                      padding: EdgeInsets.all(4.0),
                      child: recordIconWhenLockedRecord ??
                          Icon(
                            Icons.send,
                            textDirection: TextDirection.ltr,
                            size: 20,
                            color: (soundRecordNotifier.buttonPressed) ? Colors.grey.shade200 : Colors.black,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Spacer(),
          InkWell(
              onTap: () {
                soundRecordNotifier.isShow = false;
                soundRecordNotifier.resetEdgePadding();
              },
              child: Text(
                cancelText ?? "",
                style: cancelTextStyle ?? TextStyle(color: Colors.black),
              )),
          Spacer(),
          ShowCounter(
            soundRecorderState: soundRecordNotifier,
            counterTextStyle: counterTextStyle,
          ),
        ],
      ),
    );
  }
}
