import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:zapp_app/colors.dart';
import 'package:zapp_app/controller/common_controller.dart';
import 'package:zapp_app/model/user_model.dart';
import 'package:zapp_app/screens/home_screen.dart';
import 'package:zapp_app/screens/profile_screen.dart';
import 'package:zapp_app/utils/app_utils.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.notification != null) {
    // final title = message.notification!.title;
    // final body = message.notification!.body;
    // showNotification(title: title, body: body);
  }
  print('Handling a background message ${message.messageId}');
  return Future<void>.value();
}

void showNotification({String? title, String? body}) {
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'notification', 'Channel for notification',
      icon: 'app_icon',
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'ticker',
      playSound: true);

  var iOSPlatformChannelSpecifics = IOSNotificationDetails();

  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics);

  flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics,
      payload: 'Custom_Sound');
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AppUtils utils = AppUtils();
  Timer? timer;
  final box = Hive.box('credentials');
  CommonController commonController = Get.find<CommonController>();

  // For handling notification when the app is in terminated state
  checkForInitialMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print("app is terminated and opened from notification:\n" +
          "title: " +
          initialMessage.notification!.title! +
          "\n" +
          "body: " +
          initialMessage.notification!.body!);
    }
  }

  registerNotification() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = IOSInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification:
            (int? id, String? title, String? body, String? payload) async {});
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {
      if (payload != null) {
        debugPrint('notification payload: ' + payload);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage? message) {
      RemoteNotification notification = message!.notification!;
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'notification',
            'Channel for notification',
            icon: 'app_icon',
          ),
        ),
      );
    });
  }

  @override
  void initState() {
    // checkForInitialMessage();

    // //when app is in background but not terminated
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
    //   print("app in background but not terminated and opened from notification:\n" +
    //       "title: " +
    //       message!.notification!.title! +
    //       "\n" +
    //       "body: " +
    //       message.notification!.body!);
    // });

    // registerNotification();
    super.initState();
    timer = Timer(const Duration(seconds: 3), () async {
      {
        Get.offAll(() => const HomeScreen());
      }
    });
  }

  // checkUser(String uid) async {
  //   FirebaseDatabase.instance.reference().child('Users').child(uid).once().then((DataSnapshot dataSnapshot) {
  //     if (dataSnapshot.exists) {
  //       commonController.myData = UserModel.fromJson(Map.from(dataSnapshot.value));
  //       if (commonController.myData.firstName == 'default') {
  //         Get.offAll(() => const ProfileScreen(origin: 'Add'));
  //       } else {
  //         Get.offAll(() => const HomeScreen());
  //       }
  //     } else {
  //       Get.offAll(() => const LoginScreen());
  //     }
  //   }).onError((error, stackTrace) {
  //     Get.offAll(() => const LoginScreen());
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: Center(
          child: Image.asset("assets/images/logo.png",
              color: AppColors.primaryColor, height: 150, width: 150)),
    );
  }
}
