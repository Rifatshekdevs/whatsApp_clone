import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:zapp_app/screens/home_screen.dart';
import 'package:zapp_app/screens/profile_screen.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/utils/text_utils.dart';

import '../colors.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  _AppSettingsScreenState createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  TextUtils textUtils = TextUtils();
  AppUtils appUtils = AppUtils();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        centerTitle: false,
        title: textUtils.bold20(
            'Settings', AppColors.whiteColor, TextAlign.center),
        elevation: 0.0,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              color: Colors.grey.shade100,
              child: Center(
                child: textUtils.bold14('App Settings',
                    AppColors.lightGrey2Color, TextAlign.center),
              ),
            ),
            InkWell(
              onTap: () {
                Get.to(() => const ProfileScreen(origin: 'Edit'));
              },
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                child: subTitle('Profile Settings', Icons.arrow_forward_ios),
              ),
            ),
            InkWell(
              onTap: () {},
              child: subTitle('Privacy Policy', Icons.arrow_forward_ios),
            ),
            InkWell(
              onTap: () {},
              child: subTitle('Terms and conditions', Icons.arrow_forward_ios),
            ),
            subTitle('App Version', Icons.arrow_forward_ios),
            InkWell(
              onTap: () {
                showLogoutDialog();
              },
              child: subTitle('Logout', Icons.logout),
            ),
          ],
        ),
      ),
    );
  }

  subTitle(title, icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          textUtils.normal16(
              title, AppColors.lightGrey2Color, TextAlign.center),
          if (title != 'App Version')
            Icon(icon, color: AppColors.lightGrey2Color, size: 20.0),
          if (title == 'App Version')
            textUtils.normal14(
                '1.0.0', AppColors.lightGrey2Color, TextAlign.center),
        ],
      ),
    );
  }

  void showLogoutDialog() {
    Get.defaultDialog(
      title: "Confirmation",
      content: const Text(
        "Do you want to logout?",
        textAlign: TextAlign.center,
      ),
      cancel: ElevatedButton(
        onPressed: () {
          Get.back();
        },
        child: const Text("No"),
        style: ElevatedButton.styleFrom(primary: AppColors.primaryColor),
      ),
      confirm: ElevatedButton(
        onPressed: () async {
          await Hive.openBox('credentials');
          Hive.box('credentials').deleteFromDisk();
          Get.offAll(() => const HomeScreen());
        },
        child: const Text("Yes"),
        style: ElevatedButton.styleFrom(primary: Colors.red),
      ),
    );
  }
}
