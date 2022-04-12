import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:zapp_app/colors.dart';
import 'package:zapp_app/common/common.dart';
import 'package:zapp_app/model/user_model.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/utils/text_utils.dart';

class IncomingAudioCallScreen extends StatefulWidget {
  final Event? event;

  const IncomingAudioCallScreen({Key? key, this.event}) : super(key: key);

  @override
  _IncomingAudioCallScreenState createState() =>
      _IncomingAudioCallScreenState();
}

class _IncomingAudioCallScreenState extends State<IncomingAudioCallScreen> {
  AppUtils utils = AppUtils();
  TextUtils textUtils = TextUtils();

  Rx<UserModel> otherUserData = UserModel().obs;

  late final RtcEngine _engine;

  RxBool isJoined = false.obs;
  RxBool openMicrophone = true.obs;
  RxBool enableSpeakerphone = false.obs;
  bool playEffect = false;

  String callerID = "";
  String receiverID = "";
  String channelId = "";

  final databaseReference = FirebaseDatabase.instance.reference();

  RxInt seconds = 0.obs;
  RxInt minutes = 0.obs;
  RxInt hours = 0.obs;

  String firebaseNode = "";

  RxBool callPicked = false.obs;

  late StreamSubscription _onChildValueChanged;

  @override
  void dispose() {
    super.dispose();

    _engine.destroy();
  }

  @override
  void initState() {
    super.initState();

    callerID = widget.event!.snapshot.value["callerId"].toString();
    receiverID = widget.event!.snapshot.value["receiverId"].toString();

    getUserData(callerID);

    FlutterRingtonePlayer.play(
        android: AndroidSounds.ringtone,
        ios: IosSounds.glass,
        looping: true,
        volume: 0.1,
        asAlarm: false);

    channelId = callerID + receiverID;

    databaseReference
        .child("Calls")
        .orderByChild("receiverId")
        .equalTo(receiverID)
        .once()
        .then((snapShot) async {
      if (snapShot.value != null) {
        Map<String, dynamic> decoded = jsonDecode(jsonEncode(snapShot.value));

        String node = "";

        for (var value in decoded.keys) {
          node = value;
        }

        firebaseNode = node;
      }
    });

    _onChildValueChanged = databaseReference
        .child("Calls")
        .child(firebaseNode)
        .onChildChanged
        .listen((event) async {
      if (event.snapshot.value['status'] == "call_ended_by_caller") {
        if (callPicked.value) {
          await _engine.leaveChannel();
        }
        Fluttertoast.showToast(msg: "Call ended");
        await _onChildValueChanged.cancel();
        Get.back();
      }
    });

    _initEngine();
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

  _initEngine() async {
    _engine =
        await RtcEngine.createWithContext(RtcEngineContext(Common.APP_ID));
    _addListeners();

    await _engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(ClientRole.Broadcaster);
    await _engine.setEnableSpeakerphone(enableSpeakerphone.value);
    await _engine.enableLocalAudio(openMicrophone.value);

    Common.token = await generateAgoraToken(channelId);
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

  _addListeners() {
    _engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (channel, uid, elapsed) {
        debugPrint('joinChannelSuccess $channel $uid $elapsed');
        isJoined.value = true;
        FlutterRingtonePlayer.stop();
      },
      userJoined: (int uid, int elapsed) {
        debugPrint("user joined: " + uid.toString());
      },
      leaveChannel: (stats) async {
        debugPrint('leaveChannel ${stats.toJson()}');
        isJoined.value = false;
        FlutterRingtonePlayer.stop();
      },
    ));
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

  _joinChannel() async {
    await _engine
        .joinChannel(Common.token, channelId, null, 0)
        .catchError((onError) {
      debugPrint('error ${onError.toString()}');
    });

    callPicked.value = true;
    startTimer();
    databaseReference
        .child("Calls")
        .child(firebaseNode)
        .update({"status": "picked"});
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

    await _engine.leaveChannel();

    Get.back();
  }

  _switchMicrophone() {
    _engine.enableLocalAudio(!openMicrophone.value).then((value) {
      setState(() {
        openMicrophone.value = !openMicrophone.value;
      });
    }).catchError((err) {
      debugPrint('enableLocalAudio $err');
    });
  }

  _switchSpeakerphone() {
    _engine.setEnableSpeakerphone(!enableSpeakerphone.value).then((value) {
      setState(() {
        enableSpeakerphone.value = !enableSpeakerphone.value;
      });
    }).catchError((err) {
      debugPrint('setEnableSpeakerphone $err');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: textUtils.normal16('Incoming call',
                          AppColors.greyColor, TextAlign.center),
                    ),
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: Card(
                        elevation: 0.0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          side: BorderSide(
                              width: 2, color: AppColors.primaryColor),
                        ),
                        child: Obx(() {
                          return Center(
                            child: ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
                              child: otherUserData.value.profilePicture !=
                                          null &&
                                      otherUserData.value.profilePicture !=
                                          'default'
                                  ? Image(
                                      image: NetworkImage(
                                          otherUserData.value.profilePicture!),
                                      alignment: Alignment.topCenter,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                    )
                                  : const Image(
                                      image: AssetImage(
                                          'assets/images/profile_placeholder.png'),
                                      alignment: Alignment.topCenter,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                    ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Obx(() {
                      return Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: otherUserData.value.firstName != null
                            ? textUtils.bold22(
                                otherUserData.value.firstName! +
                                    " " +
                                    otherUserData.value.lastName!,
                                AppColors.primaryColor,
                                TextAlign.center)
                            : textUtils.bold22(
                                '', AppColors.primaryColor, TextAlign.center),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Obx(() => callPicked.value
                          ? Obx(() => textUtils.normal16(
                              hours.value.toString() +
                                  ":" +
                                  minutes.value.toString() +
                                  ":" +
                                  seconds.value.toString(),
                              AppColors.primaryColor,
                              TextAlign.center))
                          : textUtils.normal16(
                              '', AppColors.primaryColor, TextAlign.center)),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Obx(() => callPicked.value
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      _switchSpeakerphone();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      primary: AppColors.primaryColor,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(15),
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                        child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      child: Obx(() => enableSpeakerphone.value
                                          ? const Icon(Icons.volume_up_rounded,
                                              size: 35)
                                          : const Icon(Icons.volume_off_rounded,
                                              size: 35)),
                                    )),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: textUtils.normal14('Speaker',
                                        AppColors.greyColor, TextAlign.center),
                                  )
                                ],
                              ),
                              Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      _switchMicrophone();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      primary: AppColors.primaryColor,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(15),
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15),
                                        child: Obx(() => openMicrophone.value
                                            ? const Icon(Icons.mic_rounded,
                                                size: 35)
                                            : const Icon(Icons.mic_off_rounded,
                                                size: 35)),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: textUtils.normal14('Mute',
                                        AppColors.greyColor, TextAlign.center),
                                  )
                                ],
                              ),
                            ],
                          )
                        : Container()),
                    Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  FlutterRingtonePlayer.stop();
                                  if (callPicked.value) {
                                    _leaveChannel();
                                  } else {
                                    databaseReference
                                        .child("Calls")
                                        .child(firebaseNode)
                                        .update({"status": "declined"});
                                    Get.back();
                                  }
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
                                    child:
                                        Icon(Icons.call_end_rounded, size: 35),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: textUtils.normal14('Reject',
                                    AppColors.greyColor, TextAlign.center),
                              )
                            ],
                          ),
                          if (!callPicked.value)
                            Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    _joinChannel();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    primary: AppColors.primaryColor,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(15),
                                      ),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 15),
                                      child: Icon(Icons.call_rounded, size: 35),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: textUtils.normal14('Accept',
                                      AppColors.greyColor, TextAlign.center),
                                )
                              ],
                            )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
