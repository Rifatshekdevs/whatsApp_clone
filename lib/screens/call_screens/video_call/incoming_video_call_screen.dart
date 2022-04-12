import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:zapp_app/colors.dart';
import 'package:zapp_app/common/common.dart';
import 'package:zapp_app/controller/common_controller.dart';
import 'package:zapp_app/model/user_model.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/utils/text_utils.dart';

class IncomingVideoCallScreen extends StatefulWidget {
  final Event? event;

  const IncomingVideoCallScreen({Key? key, this.event}) : super(key: key);

  @override
  _IncomingVideoCallScreenState createState() =>
      _IncomingVideoCallScreenState();
}

class _IncomingVideoCallScreenState extends State<IncomingVideoCallScreen> {
  AppUtils utils = AppUtils();
  TextUtils textUtils = TextUtils();

  RxBool visible = true.obs;
  RxBool showData = true.obs;

  RxBool joined = false.obs;
  RxInt remoteUid = 0.obs;
  RxBool openMicrophone = true.obs;
  RxBool enableSpeakerphone = false.obs;

  late RtcEngine rtcEngine;

  String callerID = "";
  String receiverID = "";
  String channelId = "";

  RxInt seconds = 0.obs;
  RxInt minutes = 0.obs;
  RxInt hours = 0.obs;

  CommonController commonController = Get.find<CommonController>();

  final databaseReference = FirebaseDatabase.instance.reference();

  String firebaseNode = "";

  late StreamSubscription _childChangeListener;

  Rx<UserModel> otherUserData = UserModel().obs;

  @override
  void dispose() {
    super.dispose();

    rtcEngine.destroy();
  }

  @override
  void initState() {
    super.initState();

    receiverID = commonController.myData.uid.toString();
    callerID = widget.event!.snapshot.value["callerId"];

    channelId = callerID + receiverID;

    getUserData(callerID);

    remoteUid.value = -1;

    FlutterRingtonePlayer.play(
        android: AndroidSounds.ringtone,
        ios: IosSounds.glass,
        looping: true,
        volume: 0.1,
        asAlarm: false);

    databaseReference
        .child("Calls")
        .orderByChild("receiverId")
        .equalTo(receiverID)
        .once()
        .then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        Map<String, dynamic> decoded = jsonDecode(jsonEncode(snapshot.value));

        String node = "";

        for (var value in decoded.keys) {
          node = value;
        }

        firebaseNode = node;
      }
    });

    print("Node : " + firebaseNode);

    _childChangeListener = databaseReference
        .child("Calls")
        .child(firebaseNode)
        .onChildChanged
        .listen((event) async {
      if (event.snapshot.value['status'] == "call_ended_by_caller") {
        Fluttertoast.showToast(msg: "Call Ended");
        await rtcEngine.leaveChannel();
        _childChangeListener.cancel();
        FlutterRingtonePlayer.stop();
        Get.back();
      }
    });

    initPlatformState();
  }

  getUserData(String uid) async {
    FirebaseDatabase.instance
        .reference()
        .child('Users')
        .child(uid)
        .once()
        .then((DataSnapshot dataSnapshot) {
      if (dataSnapshot.exists) {
        otherUserData.value = UserModel.fromJson(Map.from(dataSnapshot.value));
      } else {
        utils.showToast('No user found for that id');
      }
    }).onError((error, stackTrace) {
      utils.showToast(error.toString());
    });
  }

  Future<void> initPlatformState() async {
    rtcEngine =
        await RtcEngine.createWithContext(RtcEngineContext(Common.APP_ID));

    _addListeners();

    await rtcEngine.enableVideo();
    await rtcEngine.setEnableSpeakerphone(enableSpeakerphone.value);
    await rtcEngine.enableLocalAudio(openMicrophone.value);

    Common.token = await generateAgoraToken(channelId);

    //_joinChannel();
  }

  Future<String> generateAgoraToken(String channelID) async {
    var response = await http.get(Uri.parse(
        "https://agoratokenproject.herokuapp.com/agora-token?appId=${Common.APP_ID}&appCertificate=${Common.APP_CERTIFICATE}&channelName=$channelID"));

    debugPrint("status code: " +
        response.statusCode.toString() +
        " agora token response:" +
        response.body.toString());

    return jsonDecode(response.body)["token"];
  }

  _joinChannel() async {
    await rtcEngine.joinChannel(Common.token, channelId, null, 0);
  }

  _addListeners() {
    rtcEngine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (String channel, int uid, int elapsed) {
        debugPrint('joinChannelSuccess $channel $uid');
        joined.value = true;
        FlutterRingtonePlayer.stop();
      },
      userJoined: (int uid, int elapsed) {
        debugPrint('userJoined $uid');
        remoteUid.value = uid;
        showData.value = false;
        FlutterRingtonePlayer.stop();
        startTimer();
      },
      userOffline: (int uid, UserOfflineReason reason) {
        debugPrint('userOffline $uid');
        remoteUid.value = -1;
        FlutterRingtonePlayer.stop();
      },
      leaveChannel: (stats) async {
        debugPrint('leaveChannel ${stats.toJson()}');
        joined.value = false;
        FlutterRingtonePlayer.stop();
      },
    ));
  }

  _leaveChannel() async {
    databaseReference
        .child("Calls")
        .orderByChild("callerId")
        .equalTo(callerID)
        .once()
        .then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        Map<String, dynamic> decoded = jsonDecode(jsonEncode(snapshot.value));

        String node = "";

        for (var value in decoded.keys) {
          node = value;
        }

        debugPrint(snapshot.key.toString() +
            " : " +
            snapshot.value.toString() +
            " path: " +
            databaseReference.child("Calls").child(node).path);

        databaseReference
            .child("Calls")
            .child(node)
            .update({'status': 'call_ended_by_receiver'});
      }
    });

    await rtcEngine.leaveChannel();

    Get.back();
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    Timer.periodic(
      oneSec,
      (Timer timer) {
        seconds.value = seconds.value + 1;
        if (seconds.value > 59) {
          minutes.value += 1;
          seconds.value = 0;
          if (minutes.value > 59) {
            hours.value += 1;
            minutes.value = 0;
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: AppColors.primaryColor,
            child: Obx(() {
              return Stack(
                children: [
                  SizedBox(
                    height: visible.value
                        ? MediaQuery.of(context).size.height / 1.25
                        : MediaQuery.of(context).size.height,
                    child: Stack(
                      children: [
                        /**
                         * Remote View */
                        InkWell(
                          onTap: () {
                            visible.value = !visible.value;
                          },
                          child: Obx(() => remoteUid.value != -1
                              ? SizedBox(
                                  height: visible.value
                                      ? MediaQuery.of(context).size.height /
                                          1.25
                                      : MediaQuery.of(context).size.height,
                                  child: rtc_remote_view.SurfaceView(
                                      uid: remoteUid.value),
                                )
                              : Container()),
                        ),

                        /**
                         * User Details */
                        Positioned(
                          top: 0.0,
                          left: 0.0,
                          right: 0.0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: visible.value ? 1 : 0,
                            child: Container(
                              color: AppColors.primaryColor,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(top: 30, bottom: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    otherUserData.value.firstName != null
                                        ? textUtils.bold22(
                                            otherUserData.value.firstName! +
                                                " " +
                                                otherUserData.value.lastName!,
                                            AppColors.whiteColor,
                                            TextAlign.center)
                                        : textUtils.bold22(
                                            '',
                                            AppColors.whiteColor,
                                            TextAlign.center),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Obx(() => joined.value
                                          ? Obx(() => textUtils.normal16(
                                              hours.value.toString() +
                                                  ":" +
                                                  minutes.value.toString() +
                                                  ":" +
                                                  seconds.value.toString(),
                                              AppColors.whiteColor,
                                              TextAlign.center))
                                          : textUtils.normal16(
                                              'Ringing',
                                              AppColors.whiteColor,
                                              TextAlign.center)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        /**
                         * Local View */
                        Obx(() => remoteUid.value == -1
                            ? SizedBox(
                                height: visible.value
                                    ? MediaQuery.of(context).size.height / 1.25
                                    : MediaQuery.of(context).size.height,
                                child: rtc_local_view.SurfaceView(),
                              )
                            : Positioned(
                                right: 0.0,
                                bottom: 0.0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15, horizontal: 10),
                                  child: ClipRRect(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(20)),
                                      child: SizedBox(
                                        height: 170,
                                        width: 120,
                                        child: rtc_local_view.SurfaceView(),
                                      )),
                                ),
                              )),
                      ],
                    ),
                  ),
                  if (showData.value)
                    Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 30),
                          Obx(() => ClipRRect(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(30)),
                                child: otherUserData.value.profilePicture !=
                                            null &&
                                        otherUserData.value.profilePicture !=
                                            'default'
                                    ? CachedNetworkImage(
                                        fit: BoxFit.cover,
                                        imageUrl:
                                            otherUserData.value.profilePicture!,
                                        height: 125,
                                        width: 125,
                                        progressIndicatorBuilder:
                                            (context, url, downloadProgress) =>
                                                SizedBox(
                                          height: 50,
                                          width: 50,
                                          child: Center(
                                              child: CircularProgressIndicator(
                                                  value: downloadProgress
                                                      .progress)),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Image.asset(
                                                "assets/images/profile_placeholder.png",
                                                height: 125,
                                                width: 125),
                                      )
                                    : Image.asset(
                                        "assets/images/profile_placeholder.png",
                                        height: 125,
                                        width: 125),
                              )),
                          SizedBox(height: 10),
                          Obx(() => otherUserData.value.firstName != null
                              ? textUtils.bold20(
                                  otherUserData.value.firstName! +
                                      " " +
                                      otherUserData.value.lastName!,
                                  AppColors.whiteColor,
                                  TextAlign.center)
                              : textUtils.bold20(
                                  '', AppColors.whiteColor, TextAlign.center)),
                          SizedBox(height: 10),
                          textUtils.bold20('ZappApp video call',
                              AppColors.whiteColor, TextAlign.center),
                        ],
                      ),
                    ),
                  Obx(
                    () => remoteUid.value == -1
                        ?
                        /**
                     * Call Requesting Controls */
                        Positioned(
                            bottom: 0.0,
                            left: 0.0,
                            right: 0.0,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 500),
                              opacity: visible.value ? 1 : 0,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    acceptCallButton(),
                                    rejectCallButton()
                                  ],
                                ),
                              ),
                            ),
                          )
                        :
                        /**
                     * Call Established Controls */
                        Positioned(
                            bottom: 0.0,
                            left: 0.0,
                            right: 0.0,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 500),
                              opacity: visible.value ? 1 : 0,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    speakerButton(),
                                    micButton(),
                                    callEndButton(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  )
                ],
              );
            })),
      ),
    );
  }

  Widget speakerButton() {
    return ElevatedButton(
      onPressed: () {
        _switchSpeakerphone();
      },
      style: ElevatedButton.styleFrom(
        primary: AppColors.whiteOpacityColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(15),
          ),
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Obx(() => enableSpeakerphone.value
              ? const Icon(Icons.volume_up_rounded, size: 35)
              : const Icon(Icons.volume_off_rounded, size: 35)),
        ),
      ),
    );
  }

  _switchSpeakerphone() {
    rtcEngine.setEnableSpeakerphone(!enableSpeakerphone.value).then((value) {
      setState(() {
        enableSpeakerphone.value = !enableSpeakerphone.value;
      });
    }).catchError((err) {
      debugPrint('setEnableSpeakerphone $err');
    });
  }

  _switchMicrophone() {
    rtcEngine.enableLocalAudio(!openMicrophone.value).then((value) {
      setState(() {
        openMicrophone.value = !openMicrophone.value;
      });
    }).catchError((err) {
      debugPrint('enableLocalAudio $err');
    });
  }

  Widget micButton() {
    return ElevatedButton(
      onPressed: () {
        _switchMicrophone();
      },
      style: ElevatedButton.styleFrom(
        primary: AppColors.whiteOpacityColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(15),
          ),
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Obx(() => openMicrophone.value
              ? const Icon(Icons.mic_rounded, size: 35)
              : const Icon(Icons.mic_off_rounded, size: 35)),
        ),
      ),
    );
  }

  Widget callEndButton() {
    return ElevatedButton(
      onPressed: () async {
        _leaveChannel();
      },
      style: ElevatedButton.styleFrom(
        primary: Colors.red,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(15),
          ),
        ),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Icon(Icons.call_end_rounded, size: 35),
        ),
      ),
    );
  }

  Widget acceptCallButton() {
    return ElevatedButton(
      onPressed: () {
        _joinChannel();
      },
      style: ElevatedButton.styleFrom(
        primary: AppColors.whiteColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(15),
          ),
        ),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Icon(Icons.videocam, size: 35, color: AppColors.primaryColor),
        ),
      ),
    );
  }

  Widget rejectCallButton() {
    return ElevatedButton(
      onPressed: () async {
        databaseReference
            .child("Calls")
            .child(firebaseNode)
            .update({"status": "declined"});
        FlutterRingtonePlayer.stop();
        Get.back();
      },
      style: ElevatedButton.styleFrom(
        primary: Colors.red,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(15),
          ),
        ),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Icon(Icons.call_end_rounded, size: 35),
        ),
      ),
    );
  }
}
