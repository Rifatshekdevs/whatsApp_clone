library social_media_recorder;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zapp_app/colors.dart';
import 'package:zapp_app/provider/sound_record_notifier.dart';
import 'package:zapp_app/utils/audio_encoder_type.dart';
import 'package:zapp_app/voice_recording_widgets/lock_record.dart';
import 'package:zapp_app/voice_recording_widgets/show_counter.dart';
import 'package:zapp_app/voice_recording_widgets/show_mic_with_text.dart';
import 'package:zapp_app/voice_recording_widgets/sound_recorder_when_locked_design.dart';

class SocialMediaRecorder extends StatefulWidget {
  /// function reture the recording sound file
  final Function(File soundFile, String duration) sendRequestFunction;

  /// recording Icon That pressesd to start record
  final Widget? recordIcon;

  /// recording Icon when user locked the record
  final Widget? recordIconWhenLockedRecord;

  /// use to change the backGround Icon when user recording sound
  final Color? recordIconBackGroundColor;

  /// use to change the Icon backGround color when user locked the record
  final Color? recordIconWhenLockBackGroundColor;

  /// use to change all recording widget color
  final Color? backGroundColor;

  /// use to change the counter style
  final TextStyle? counterTextStyle;

  /// text to know user should drag in the left to cancel record
  final String? slideToCancelText;

  /// use to change slide to cancel textstyle
  final TextStyle? slideToCancelTextStyle;

  /// this text show when lock record and to tell user should press in this text to cancel recod
  final String? cancelText;

  /// use to change cancel text style
  final TextStyle? cancelTextStyle;

  /// put you file directory storage path if you didn't pass it take deafult path
  final String? storeSoundRecoringPath;

  /// Chose the encode type
  final AudioEncoderType encode;

  SocialMediaRecorder({
    this.storeSoundRecoringPath = "",
    required this.sendRequestFunction,
    this.recordIcon,
    this.recordIconWhenLockedRecord,
    this.recordIconBackGroundColor = AppColors.primaryColor,
    this.recordIconWhenLockBackGroundColor = AppColors.primaryColor,
    this.backGroundColor,
    this.cancelTextStyle,
    this.counterTextStyle,
    this.slideToCancelTextStyle,
    this.slideToCancelText = " Slide to Cancel >",
    this.cancelText = "Cancel",
    this.encode = AudioEncoderType.AAC,
  });

  @override
  _SocialMediaRecorder createState() => _SocialMediaRecorder();
}

class _SocialMediaRecorder extends State<SocialMediaRecorder> {
  late SoundRecordNotifier soundRecordNotifier;

  @override
  void initState() {
    soundRecordNotifier = SoundRecordNotifier();
    soundRecordNotifier.initialStorePathRecord = widget.storeSoundRecoringPath ?? "";
    soundRecordNotifier.isShow = false;
    soundRecordNotifier.voidInitialSound();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => soundRecordNotifier),
        ],
        child: Consumer<SoundRecordNotifier>(
          builder: (context, value, _) {
            return Directionality(textDirection: TextDirection.rtl, child: makeBody(value));
          },
        ));
  }

  Widget makeBody(SoundRecordNotifier state) {
    return GestureDetector(
      onHorizontalDragUpdate: (scrollEnd) {
        state.updateScrollValue(scrollEnd.globalPosition, context);
      },
      onHorizontalDragEnd: (x) {},
      child: Container(
        margin: state.lockScreenRecord ? EdgeInsets.symmetric(horizontal: 10) : EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.all(Radius.circular(25)),
        ),
        child: recordVoice(state),
      ),
    );
  }

  Widget recordVoice(SoundRecordNotifier state) {
    if (state.lockScreenRecord == true) {
      return SoundRecorderWhenLockedDesign(
        cancelText: widget.cancelText,
        cancelTextStyle: widget.cancelTextStyle,
        recordIconWhenLockBackGroundColor: widget.recordIconWhenLockBackGroundColor ?? AppColors.primaryColor,
        counterTextStyle: widget.counterTextStyle,
        recordIconWhenLockedRecord: widget.recordIconWhenLockedRecord,
        sendRequestFunction: widget.sendRequestFunction,
        soundRecordNotifier: state,
      );
    }

    return Listener(
      onPointerDown: (details) async {
        state.setNewInitialDraggableHeight(details.position.dy);
        state.resetEdgePadding();

        soundRecordNotifier.isShow = true;
        state.record();
      },
      onPointerUp: (details) async {
        if (!state.isLocked) {
          if (state.buttonPressed) {
            if (state.second > 1 || state.minute > 0) {
              String path = state.mPath;
              await Future.delayed(Duration(milliseconds: 500));
              widget.sendRequestFunction(
                File.fromUri(Uri(path: path)),
                "${state.minute > 9 ? state.minute.toString() : "0" + state.minute.toString()}:"
                "${state.second > 9 ? state.second.toString() : "0" + state.second.toString()}",
              );
            }
          }
          state.resetEdgePadding();
        }
      },
      child: Container(
          width: (soundRecordNotifier.isShow) ? MediaQuery.of(context).size.width : 50,
          child: Stack(
            children: [
              AnimatedPadding(
                duration: Duration(milliseconds: state.edge == 0 ? 700 : 0),
                curve: Curves.easeIn,
                padding: EdgeInsets.only(right: state.edge * 0.8),
                child: Container(
                  color: widget.backGroundColor ?? AppColors.whiteColor,
                  child: Stack(
                    children: [
                      ShowMicWithText(
                        backGroundColor: widget.recordIconBackGroundColor,
                        recordIcon: widget.recordIcon,
                        shouldShowText: soundRecordNotifier.isShow,
                        soundRecorderState: state,
                        slideToCancelTextStyle: widget.slideToCancelTextStyle,
                        slideToCancelText: widget.slideToCancelText,
                      ),
                      if (soundRecordNotifier.isShow) ShowCounter(soundRecorderState: state),
                    ],
                  ),
                ),
              ),
              Container(width: 60, child: LockRecord(soundRecorderState: state))
            ],
          )),
    );
  }
}
