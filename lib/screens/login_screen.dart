// import 'package:country_code_picker/country_code_picker.dart';
// import 'package:dart_ipify/dart_ipify.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:zapp_app/colors.dart';
// import 'package:zapp_app/common/common.dart';
// import 'package:zapp_app/screens/otp_screen.dart';
// import 'package:zapp_app/utils/app_utils.dart';
// import 'package:zapp_app/utils/text_utils.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({Key? key}) : super(key: key);

//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   TextUtils textUtils = TextUtils();
//   AppUtils appUtils = AppUtils();
//   RxString phoneCode = "".obs;
//   RxString countryName = "".obs;
//   var myController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     getIpV4();
//   }

//   void getIpV4() async {
//     final ipv4 = await Ipify.ipv4();
//     final someGeo =
//         await Ipify.geo('at_Xw2eH6VlTYmwDR8ZDodbQsgV6jJHW', ip: ipv4);
//     countryName.value = someGeo.location!.country!;
//     debugPrint(someGeo.toString());
//     debugPrint("IP : " + ipv4);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.whiteColor,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(15),
//           child: Column(
//             children: [
//               const SizedBox(height: 50),
//               Align(
//                 alignment: Alignment.center,
//                 child: Image.asset("assets/images/logo.png",
//                     color: AppColors.primaryColor, height: 150, width: 150),
//               ),
//               Container(
//                 margin: const EdgeInsets.only(top: 30),
//                 child: textUtils.normal16(
//                   'ZappApp will send an SMS message (Carrier charges may apply) to verify your phone number.'
//                   'Enter your phone number.',
//                   AppColors.blackColor,
//                   TextAlign.center,
//                 ),
//               ),
//               Container(
//                 margin: const EdgeInsets.only(top: 20),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Obx(() {
//                       return Container(
//                         decoration: appUtils.boxDecoration(
//                             AppColors.whiteColor, AppColors.primaryColor),
//                         margin: const EdgeInsets.symmetric(horizontal: 5),
//                         height: 50,
//                         child: countryName.value == ''
//                             ? const Padding(
//                                 padding: EdgeInsets.symmetric(horizontal: 20),
//                                 child: CupertinoActivityIndicator())
//                             : CountryCodePicker(
//                                 onChanged: (value) {
//                                   phoneCode.value = value.dialCode!;
//                                   debugPrint(value.dialCode);
//                                 },
//                                 onInit: (value) {
//                                   phoneCode.value = value!.dialCode!;
//                                   debugPrint(value.dialCode);
//                                 },
//                                 initialSelection: countryName.value,
//                                 showCountryOnly: false,
//                                 showOnlyCountryWhenClosed: false,
//                                 alignLeft: false,
//                               ),
//                       );
//                     }),
//                     Expanded(
//                       flex: 8,
//                       child: Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 5),
//                         child: TextFormField(
//                           controller: myController,
//                           keyboardType: TextInputType.number,
//                           decoration: appUtils.inputDecoration(
//                               'Enter Phone Number', AppColors.primaryColor),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               InkWell(
//                 onTap: () {
//                   if (myController.text.isNotEmpty) {
//                     verifyNumber();
//                   } else {
//                     appUtils.showToast('Please Enter Phone');
//                   }
//                 },
//                 child: Container(
//                   height: 45,
//                   margin: const EdgeInsets.only(top: 30),
//                   padding: const EdgeInsets.symmetric(horizontal: 10),
//                   decoration: BoxDecoration(
//                     color: AppColors.primaryColor,
//                     border: Border.all(color: AppColors.primaryColor),
//                     borderRadius: const BorderRadius.all(Radius.circular(30.0)),
//                   ),
//                   child: Center(
//                       child: textUtils.bold16(
//                           'Next', AppColors.whiteColor, TextAlign.center)),
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   verifyNumber() async {
//     appUtils.showLoadingDialog();
//     await FirebaseAuth.instance.verifyPhoneNumber(
//       phoneNumber: phoneCode + myController.value.text,
//       verificationCompleted: (PhoneAuthCredential credential) {
//         Common.credential = credential;
//       },
//       verificationFailed: (FirebaseAuthException e) {
//         Get.back();
//         appUtils.showToast(e.message.toString());
//         debugPrint(e.message.toString());
//       },
//       codeSent: (String? verificationId, int? resendToken) {
//         Common.codeSent = verificationId;
//         Common.resendToken = resendToken;
//         Get.back();
//         Get.to(() => OtpScreen(number: phoneCode + myController.value.text));
//       },
//       codeAutoRetrievalTimeout: (String verificationId) {},
//     );
//   }
// }
