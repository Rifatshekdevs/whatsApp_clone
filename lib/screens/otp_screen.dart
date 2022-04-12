import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:timer_count_down/timer_controller.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'package:zapp_app/colors.dart';
import 'package:zapp_app/common/common.dart';
import 'package:zapp_app/controller/common_controller.dart';
import 'package:zapp_app/model/user_model.dart';
import 'package:zapp_app/screens/home_screen.dart';
import 'package:zapp_app/screens/profile_screen.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/utils/text_utils.dart';

class OtpScreen extends StatefulWidget {
  final String? number;

  const OtpScreen({Key? key, this.number}) : super(key: key);

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  AppUtils utils = AppUtils();
  TextUtils textUtils = TextUtils();

  CommonController commonController = Get.find<CommonController>();

  TextEditingController otpController = TextEditingController();
  var isValidCode = true;
  bool loading = false;
  RxBool sendAgain = false.obs;
  RxBool hasError = false.obs;
  final CountdownController _controller = CountdownController(autoStart: true);
  final BoxDecoration pinPutDecoration = BoxDecoration(
    color: AppColors.primaryColor,
    borderRadius: BorderRadius.circular(10.0),
    border: Border.all(color: AppColors.primaryColor),
  );
  late StreamController<ErrorAnimationType> errorController;
  final databaseReference = FirebaseDatabase.instance.reference();
  RxString currentText = "".obs;

  @override
  void initState() {
    errorController = StreamController<ErrorAnimationType>();
    super.initState();
  }

  @override
  void dispose() {
    errorController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        iconTheme: const IconThemeData(color: AppColors.blackColor),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(15),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Image.asset("assets/images/logo.png", color: AppColors.primaryColor, height: 150, width: 150),
                ),
                const SizedBox(height: 20),
                textUtils.bold16('Enter code you will receive on', AppColors.blackColor, TextAlign.center),
                const SizedBox(height: 5),
                textUtils.bold16(widget.number, AppColors.blackColor, TextAlign.center),
                const SizedBox(height: 20),
                Obx(() {
                  return PinCodeTextField(
                    appContext: context,
                    pastedTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                    length: 6,
                    blinkWhenObscuring: true,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      disabledColor: Colors.red,
                      inactiveColor: Colors.grey,
                      selectedColor: Colors.blue,
                      shape: PinCodeFieldShape.underline,
                      fieldHeight: 50,
                      fieldWidth: 50,
                      activeFillColor: hasError.value ? Colors.blue.shade100 : Colors.white,
                    ),
                    cursorColor: AppColors.primaryColor,
                    animationDuration: const Duration(milliseconds: 300),
                    errorAnimationController: errorController,
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      currentText.value = value;
                    },
                    beforeTextPaste: (text) {
                      debugPrint("Allowing to paste $text");
                      return true;
                    },
                  );
                }),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.03,
                ),
                Obx(() {
                  return InkWell(
                    onTap: () {
                      if (sendAgain.value) {
                        verifyNumber();
                        _controller.restart();
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        textUtils.bold16('Did you don\'t get code ?', sendAgain.value ? Colors.black : Colors.grey, TextAlign.center),
                        textUtils.bold16("Resend ", sendAgain.value ? AppColors.primaryColor : Colors.grey, TextAlign.center),
                        Countdown(
                          controller: _controller,
                          seconds: 30,
                          build: (BuildContext context, double time) => textUtils.bold16(time.toString(), AppColors.primaryColor, TextAlign.center),
                          interval: const Duration(seconds: 1),
                          onFinished: () {
                            sendAgain.value = true;
                          },
                        ),
                      ],
                    ),
                  );
                }),
                InkWell(
                  onTap: () {
                    if (currentText.value.length != 6) {
                      errorController.add(ErrorAnimationType.shake);
                      setState(() {
                        hasError.value = true;
                      });
                    } else {
                      verifyOTP();
                    }
                  },
                  child: Container(
                    height: 45,
                    margin: const EdgeInsets.only(top: 30),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      border: Border.all(color: AppColors.primaryColor),
                      borderRadius: const BorderRadius.all(Radius.circular(30.0)),
                    ),
                    child: Center(child: textUtils.bold16('Verify', AppColors.whiteColor, TextAlign.center)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  verifyNumber() async {
    utils.showLoadingDialog();
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.number!,
      verificationCompleted: (PhoneAuthCredential credential) {
        Common.credential = credential;
      },
      verificationFailed: (FirebaseAuthException e) {
        Get.back();
        utils.showToast(e.message.toString());
        debugPrint(e.message.toString());
      },
      codeSent: (String? verificationId, int? resendToken) {
        Common.codeSent = verificationId;
        Common.resendToken = resendToken;
        Get.back();
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  void verifyOTP() async {
    utils.showLoadingDialog();
    FirebaseAuth auth = FirebaseAuth.instance;

    PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: Common.codeSent!, smsCode: currentText.value);

    await auth.signInWithCredential(credential).whenComplete(() {
      if (auth.currentUser != null) {
        checkUser(auth.currentUser!.uid, auth.currentUser!.phoneNumber!);
      } else {
        Get.back();
        hasError.value = true;
        utils.showToast('Error! Enter Correct Otp');
      }
    });
  }

  checkUser(String uid, String phoneNumber) async {
    await Hive.openBox('credentials');
    final box = Hive.box('credentials');
    databaseReference.child('Users').child(uid).once().then((DataSnapshot dataSnapshot) {
      if (dataSnapshot.exists) {
        box.put('uid', uid);
        commonController.myData = UserModel.fromJson(Map.from(dataSnapshot.value));
        if (commonController.myData.firstName == 'default') {
          Get.offAll(() => const ProfileScreen(origin: 'Add'));
        } else {
          Get.offAll(() => const HomeScreen());
        }
      } else {
        box.put('uid', uid);
        createUser(uid, phoneNumber);
      }
    });
  }

  createUser(String uid, String phoneNumber) {
    databaseReference.child('Users').child(uid).set({
      'uid': uid,
      'email': 'default',
      'firstName': 'default',
      'lastName': 'default',
      'profilePicture': 'default',
      'country': 'default',
      'region': 'default',
      'address': 'default',
      'latitude': 'default',
      'longitude': 'default',
      'phoneNumber': phoneNumber,
      'date_of_birth': 'default',
    }).whenComplete(() {
      Get.offAll(() => const ProfileScreen(origin: 'Add'));
    }).onError((error, stackTrace) {
      Get.back();
      debugPrint(error.toString());
      utils.showToast(error.toString());
    });
  }
}
