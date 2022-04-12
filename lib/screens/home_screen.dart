import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zapp_app/colors.dart';
import 'package:zapp_app/controller/common_controller.dart';
import 'package:zapp_app/screens/call_screens/audio_call/incoming_audio_call_screen.dart';
import 'package:zapp_app/screens/home_fragments/chat_fragment.dart';
import 'package:zapp_app/screens/home_fragments/discount_fragment.dart';
import 'package:zapp_app/screens/home_fragments/forum_fragment.dart';
import 'package:zapp_app/screens/home_fragments/news_fragment.dart';
import 'package:zapp_app/screens/home_fragments/shop_fragment.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/utils/text_utils.dart';

import 'call_screens/video_call/incoming_video_call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  RxInt selectedIndex = 0.obs;
  TextUtils textUtils = TextUtils();
  AppUtils appUtils = AppUtils();
  final databaseReference = FirebaseDatabase.instance.reference();
  CommonController commonController = Get.find<CommonController>();

  @override
  void initState() {
    super.initState();
    updateToken();
    userPermissions();
    listenerForCalls();
  }

  listenerForCalls() {
    databaseReference
        .child("Calls")
        .orderByChild("receiverId")
        .equalTo(commonController.myData.uid.toString())
        .onChildAdded
        .listen((event) {
      if (event.snapshot.value["type"] == "audio" &&
          event.snapshot.value["status"] == "calling") {
        Get.to(() => IncomingAudioCallScreen(event: event));
      } else if (event.snapshot.value["type"] == "video" &&
          event.snapshot.value["status"] == "calling") {
        Get.to(() => IncomingVideoCallScreen(event: event));
      }
    });
  }

  userPermissions() async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.camera, Permission.microphone].request();
    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted) {
      print('Granted');
    } else {
      appUtils
          .showToast('You need to allow all permission in order to continue');
    }
  }

  updateToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    databaseReference
        .child('Users')
        .child(appUtils.getUserId())
        .update({"token": token});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        showAlertDialog();
        return false;
      },
      child: Obx(() => Scaffold(
            backgroundColor: AppColors.whiteColor,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: AppColors.primaryColor,
              toolbarHeight: 0.0,
              elevation: 0.0,
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: selectedIndex.value,
              elevation: 0,
              backgroundColor: AppColors.whiteColor,
              selectedItemColor: AppColors.primaryColor,
              unselectedItemColor: AppColors.lightGreyColor,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              unselectedLabelStyle: TextStyle(
                  color: AppColors.lightGreyColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: "SFPro"),
              selectedLabelStyle: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: "SFPro"),
              type: BottomNavigationBarType.fixed,
              onTap: (p0) {
                selectedIndex.value = p0;
              },
              items: [
                /// Chat
                BottomNavigationBarItem(
                  icon: Image(
                    image: AssetImage('assets/images/chat.png'),
                    height: 20,
                    width: 20,
                    color: selectedIndex.value == 0
                        ? AppColors.primaryColor
                        : AppColors.lightGreyColor,
                  ),
                  label: "Chat",
                ),

                /// Discount
                BottomNavigationBarItem(
                  icon: Image(
                    image: AssetImage('assets/images/discount.png'),
                    height: 20,
                    width: 20,
                    color: selectedIndex.value == 1
                        ? AppColors.primaryColor
                        : AppColors.lightGreyColor,
                  ),
                  label: "Discount",
                ),

                /// Shop
                BottomNavigationBarItem(
                  icon: Image(
                    image: AssetImage('assets/images/shop.png'),
                    height: 20,
                    width: 20,
                    color: selectedIndex.value == 2
                        ? AppColors.primaryColor
                        : AppColors.lightGreyColor,
                  ),
                  label: "Shop",
                ),

                /// Forum
                BottomNavigationBarItem(
                  icon: Image(
                    image: AssetImage('assets/images/forum.png'),
                    height: 20,
                    width: 20,
                    color: selectedIndex.value == 3
                        ? AppColors.primaryColor
                        : AppColors.lightGreyColor,
                  ),
                  label: "Forum",
                ),

                /// News
                BottomNavigationBarItem(
                  icon: Image(
                    image: AssetImage('assets/images/news.png'),
                    height: 20,
                    width: 20,
                    color: selectedIndex.value == 4
                        ? AppColors.primaryColor
                        : AppColors.lightGreyColor,
                  ),
                  label: "News",
                ),
              ],
            ),
            body: SafeArea(
              child: Container(child: _getPage(selectedIndex.value)),
            ),
          )),
    );
  }

  _getPage(int page) {
    switch (page) {
      case 0:
        return const ChatFragment();
      case 1:
        return const DiscountFragment();
      case 2:
        return const ShopFragment();
      case 3:
        return const ForumFragment();
      case 4:
        return const NewsFragment();
    }
  }

  void showAlertDialog() {
    Get.defaultDialog(
      title: "Exit App",
      content: const Text(
        "Do you want to close the app?",
        textAlign: TextAlign.center,
      ),
      cancel: ElevatedButton(
        onPressed: () {
          Get.back();
        },
        child: const Text("No"),
        style: ElevatedButton.styleFrom(primary: AppColors.redColor),
      ),
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          } else {
            exit(0);
          }
        },
        child: const Text("Yes"),
        style: ElevatedButton.styleFrom(primary: AppColors.primaryColor),
      ),
    );
  }
}
