import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:zapp_app/colors.dart';
import 'package:zapp_app/common/common.dart';
import 'package:zapp_app/controller/common_controller.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/utils/text_utils.dart';
import 'package:http/http.dart' as http;

class OutgoingAudioCallScreen extends StatefulWidget {
  final String? profilePicture, name, id;

  const OutgoingAudioCallScreen({Key? key, this.profilePicture, this.name, this.id}) : super(key: key);

  @override
  _OutgoingAudioCallScreenState createState() => _OutgoingAudioCallScreenState();
}

class _OutgoingAudioCallScreenState extends State<OutgoingAudioCallScreen> {
  AppUtils utils = AppUtils();
  TextUtils textUtils = TextUtils();

  late final RtcEngine _engine;

  RxBool isJoined = false.obs;
  RxBool openMicrophone = true.obs;
  RxBool enableSpeakerphone = false.obs;
  bool playEffect = false;

  final databaseReference = FirebaseDatabase.instance.reference();

  String callerID = "";
  String receiverID = "";
  String channelId = "";

  CommonController commonController = Get.find<CommonController>();

  RxBool otherUserJoined = false.obs;

  RxInt seconds = 0.obs;
  RxInt minutes = 0.obs;
  RxInt hours = 0.obs;

  late StreamSubscription childChangeListener;

  String firebaseNode = "";

  @override
  void dispose() {
    super.dispose();
    _engine.destroy();
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
  void initState() {
    super.initState();

    receiverID = widget.id!;
    callerID = commonController.myData.uid.toString();

    channelId = callerID + receiverID;

    print(channelId);

    childChangeListener = databaseReference.child("Calls").orderByChild("callerId").equalTo(callerID).onChildChanged.listen((Event event) async {
      if (event.snapshot.value['status'] == 'declined') {
        Fluttertoast.showToast(msg: "User declined your call");
        _leaveChannel();
      } else if (event.snapshot.value['status'] == "call_ended_by_receiver") {
        Fluttertoast.showToast(msg: "Call ended");
        childChangeListener.cancel();
        await _engine.leaveChannel();
        Get.back();
      }
    });

    _initEngine();
  }

  _initEngine() async {
    _engine = await RtcEngine.createWithContext(RtcEngineContext(Common.APP_ID));
    _addListeners();

    await _engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(ClientRole.Broadcaster);
    await _engine.setEnableSpeakerphone(enableSpeakerphone.value);
    await _engine.enableLocalAudio(openMicrophone.value);

    Common.token = await generateAgoraToken(channelId);

    _joinChannel();
  }

  Future<String> generateAgoraToken(String channelID) async {
    var response = await http.get(Uri.parse(
        "https://agoratokenproject.herokuapp.com/agora-token?appId=${Common.APP_ID}&appCertificate=${Common.APP_CERTIFICATE}&channelName=$channelID"));

    debugPrint("status code: " + response.statusCode.toString() + " agora token response:" + response.body.toString());

    return jsonDecode(response.body)["token"];
  }

  _addListeners() {
    _engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (channel, uid, elapsed) {
        debugPrint('joinChannelSuccess $channel $uid $elapsed');
        isJoined.value = true;
      },
      userJoined: (int uid, int elapsed) {
        debugPrint("user joined: " + uid.toString());
        otherUserJoined.value = true;
        startTimer();
      },
      leaveChannel: (stats) async {
        debugPrint('leaveChannel ${stats.toJson()}');
        isJoined.value = false;
      },
    ));
  }

  _joinChannel() async {
    databaseReference.child("Calls").push().set({
      "callerId": callerID,
      "receiverId": receiverID,
      "status": "calling",
      "channelId": channelId,
      "time": DateTime.now().millisecondsSinceEpoch.toString(),
      "type": "audio"
    }).then((value) {
      databaseReference.child("Calls").orderByChild("callerId").equalTo(callerID).once().then((DataSnapshot snapshot) {
        if (snapshot.value != null) {
          Map<String, dynamic> decoded = jsonDecode(jsonEncode(snapshot.value));

          String node = "";

          for (var value in decoded.keys) {
            node = value;
          }

          firebaseNode = node;
        }
      });
    });
  }

  _leaveChannel() async {
    childChangeListener.cancel();
    databaseReference.child("Calls").child(firebaseNode).update({'status': 'call_ended_by_caller'});
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
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: AppColors.primaryColor,
          child: Stack(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height / 1.25,
                child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    child: Stack(
                      children: [
                        widget.profilePicture != null && widget.profilePicture != 'default'
                            ? Image(
                                image: NetworkImage(widget.profilePicture!),
                                alignment: Alignment.topCenter,
                                fit: BoxFit.cover,
                                height: MediaQuery.of(context).size.height / 1.25,
                                width: MediaQuery.of(context).size.width,
                              )
                            : Image(
                                image: const AssetImage('assets/images/placeholder.png'),
                                alignment: Alignment.topCenter,
                                fit: BoxFit.cover,
                                height: MediaQuery.of(context).size.height / 1.25,
                                width: MediaQuery.of(context).size.width,
                              ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: const Alignment(-1, -1),
                              end: const Alignment(-1, 1),
                              colors: [Colors.transparent, AppColors.primaryColor.withAlpha(450)],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0.0,
                          left: 0.0,
                          right: 0.0,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 30),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                textUtils.bold24(widget.name, AppColors.whiteColor, TextAlign.center),
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Obx(() => otherUserJoined.value
                                      ? Obx(() => textUtils.normal16(
                                          hours.value.toString() + ":" + minutes.value.toString() + ":" + seconds.value.toString(),
                                          AppColors.whiteColor,
                                          TextAlign.center))
                                      : textUtils.normal16('Ringing', AppColors.whiteColor, TextAlign.center)),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    )),
              ),
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton(
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
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: Obx(() => enableSpeakerphone.value
                                ? const Icon(Icons.volume_up_rounded, size: 35)
                                : const Icon(Icons.volume_off_rounded, size: 35)),
                          ),
                        ),
                      ),
                      ElevatedButton(
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
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: Obx(
                                () => openMicrophone.value ? const Icon(Icons.mic_rounded, size: 35) : const Icon(Icons.mic_off_rounded, size: 35)),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          debugPrint("Firebase Node: " + firebaseNode);
                          if (otherUserJoined.value) {
                            databaseReference.child("Calls").child(firebaseNode).update({"status": "call_ended_by_caller"});
                            await _engine.leaveChannel();
                            Get.back();
                          } else {
                            _leaveChannel();
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
                            child: Icon(Icons.call_end_rounded, size: 35),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
