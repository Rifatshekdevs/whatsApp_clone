library social_media_recorder;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:zapp_app/colors.dart';
import 'package:zapp_app/provider/sound_record_notifier.dart';

/// used to show mic and show dragg text when
/// press into record icon
class ShowMicWithText extends StatelessWidget {
  final bool shouldShowText;
  final String? slideToCancelText;
  final SoundRecordNotifier soundRecorderState;
  final TextStyle? slideToCancelTextStyle;
  final Color? backGroundColor;
  final Widget? recordIcon;

  ShowMicWithText({
    required this.backGroundColor,
    required this.shouldShowText,
    required this.soundRecorderState,
    required this.slideToCancelTextStyle,
    required this.slideToCancelText,
    required this.recordIcon,
  });

  final colorizeColors = [
    Colors.black,
    Colors.grey.shade200,
    Colors.black,
  ];
  final colorizeTextStyle = TextStyle(
    fontSize: 14.0,
    fontFamily: 'Horizon',
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Transform.scale(
          scale:  1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(600),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeIn,
              width: 50,
              height: 50,
              child: Padding(
                padding: EdgeInsets.all(4.0),
                child: recordIcon ??
                    Container(
                      decoration: BoxDecoration(color: AppColors.primaryColor, shape: BoxShape.circle),
                      child: Icon(
                        Icons.mic,
                        size: 20,
                        color: AppColors.whiteColor,
                      ),
                    ),
              ),
            ),
          ),
        ),
        if (shouldShowText)
          Padding(
            padding: EdgeInsets.only(left: 8, right: 8),
            child: DefaultTextStyle(
              overflow: TextOverflow.clip,
              maxLines: 1,
              style: const TextStyle(fontSize: 14.0),
              child: AnimatedTextKit(
                animatedTexts: [
                  ColorizeAnimatedText(
                    slideToCancelText ?? "",
                    textStyle: slideToCancelTextStyle ?? colorizeTextStyle,
                    colors: colorizeColors,
                  ),
                ],
                isRepeatingAnimation: true,
                onTap: () {},
              ),
            ),
          ),
      ],
    );
  }
}
