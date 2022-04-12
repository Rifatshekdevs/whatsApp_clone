import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:zapp_app/colors.dart';
import 'package:zapp_app/utils/text_utils.dart';

class AppUtils {
  TextUtils textUtils = TextUtils();

  inputDecoration(text, color) {
    return InputDecoration(
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.blackColor, fontFamily: 'SFPro', fontWeight: FontWeight.w500),
      hintText: text,
      labelStyle: const TextStyle(fontSize: 14, color: AppColors.blackColor, fontFamily: 'SFPro', fontWeight: FontWeight.w500),
      labelText: text,
      filled: true,
      alignLabelWithHint: true,
      fillColor: AppColors.whiteColor,
      contentPadding: const EdgeInsets.all(15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color)),
    );
  }

  messageInputDecoration(text, color) {
    return InputDecoration(
      hintStyle: TextStyle(fontSize: 14, color: AppColors.blackColor, fontFamily: 'SFPro', fontWeight: FontWeight.w500),
      hintText: text,
      border: InputBorder.none,
      contentPadding: EdgeInsets.all(15),
    );
  }

  boxDecoration(color, borderColor) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(10),
    );
  }

  makeButton(color, text) {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: color),
        borderRadius: const BorderRadius.all(Radius.circular(30.0)),
      ),
      child: Center(child: textUtils.bold16(text, AppColors.whiteColor, TextAlign.center)),
    );
  }

  notLogin() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset('assets/images/alert.png', height: 80, width: 80),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: textUtils.bold20('Coming Soon', AppColors.primaryColor, TextAlign.center),
        ),
      ],
    );
  }

  showLoadingDialog() {
    Get.dialog(
      const Center(child: CircularProgressIndicator(backgroundColor: AppColors.primaryColor, color: AppColors.whiteColor)),
      barrierDismissible: false,
      useSafeArea: true,
    );
  }

  showToast(text) {
    return Fluttertoast.showToast(msg: "" + text, toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM, fontSize: 16.0);
  }

  getUserId() {
    var credentials = Hive.box('credentials');
    return credentials.get('uid');
  }

  String timeAgoSinceDate(String dateString, int newTimeStamp, {bool numericDates = true}) {
    int timeStamp = 0;
    if (newTimeStamp == 0) {
      timeStamp = DateFormat('yyyy-MM-dd hh:mm:ss').parse(dateString).millisecondsSinceEpoch;
    } else {
      timeStamp = newTimeStamp;
    }

    var date = DateTime.fromMillisecondsSinceEpoch(timeStamp);
    final date2 = DateTime.now();
    final difference = date2.difference(date);
    if (difference.inDays > 8) {
      return DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(timeStamp));
    } else if ((difference.inDays / 7).floor() >= 1) {
      return (numericDates) ? '1 week ago' : 'Last week';
    } else if (difference.inDays >= 2) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays >= 1) {
      return (numericDates) ? '1 day ago' : 'Yesterday';
    } else if (difference.inHours >= 2) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours >= 1) {
      return (numericDates) ? '1 hour ago' : 'An hour ago';
    } else if (difference.inMinutes >= 2) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inMinutes >= 1) {
      return (numericDates) ? '1 minute ago' : 'A minute ago';
    } else if (difference.inSeconds >= 3) {
      return '${difference.inSeconds} seconds ago';
    } else {
      return 'Just now';
    }
  }
}
