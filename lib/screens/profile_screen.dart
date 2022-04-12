import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';
import 'package:zapp_app/colors.dart';
import 'package:zapp_app/controller/common_controller.dart';
import 'package:zapp_app/model/user_model.dart';
import 'package:zapp_app/screens/home_screen.dart';
import 'package:zapp_app/screens/select_location_on_map_screen.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/utils/text_utils.dart';

class ProfileScreen extends StatefulWidget {
  final String? origin;

  const ProfileScreen({Key? key, this.origin}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TextUtils textUtils = TextUtils();
  AppUtils appUtils = AppUtils();
  var screenWidth = Get.width;
  String? lat;
  String? lng;
  var firstNameController = TextEditingController();
  var lastNameController = TextEditingController();
  var countryController = TextEditingController();
  var regionController = TextEditingController();
  var addressController = TextEditingController().obs;
  var emailController = TextEditingController();
  var dobController = TextEditingController().obs;

  CommonController commonController = Get.find<CommonController>();

  var formKey = GlobalKey<FormState>();
  RxBool checked = false.obs;
  Rx<File> profileImage = File('').obs;
  FirebaseStorage storage = FirebaseStorage.instance;
  var databaseReference = FirebaseDatabase.instance.reference();
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    if (widget.origin == 'Edit') {
      firstNameController.text = commonController.myData.firstName!;
      lastNameController.text = commonController.myData.lastName!;
      countryController.text = commonController.myData.country!;
      regionController.text = commonController.myData.region!;
      addressController.value.text = commonController.myData.address!;
      emailController.text = commonController.myData.email!;
      dobController.value.text = commonController.myData.dateOfBirth!;
      lat = commonController.myData.latitude!;
      lng = commonController.myData.longitude!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        centerTitle: true,
        title:
            textUtils.bold20('Profile', AppColors.whiteColor, TextAlign.center),
        elevation: 0.0,
      ),
      body: Container(
        color: AppColors.whiteColor,
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  ClipPath(
                    clipper: ProsteBezierCurve(
                      position: ClipPosition.bottom,
                      reclip: true,
                      list: [
                        BezierCurveSection(
                            start: const Offset(0, 90),
                            top: Offset(100, screenWidth / 5),
                            end: Offset(screenWidth / 2, 180)),
                        BezierCurveSection(
                            start: Offset(screenWidth / 2, 150),
                            top: Offset(screenWidth / 4 * 3, 55),
                            end: Offset(screenWidth, 90)),
                      ],
                    ),
                    child:
                        Container(height: 150, color: AppColors.primaryColor),
                  ),
                  Obx(() {
                    return InkWell(
                      onTap: storagePermission,
                      child: Align(
                        alignment: Alignment.center,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  color: AppColors.whiteColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.primaryColor)),
                              height: 125,
                              width: 125,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: profileImage.value.path != '' ||
                                        commonController
                                                    .myData.profilePicture !=
                                                null &&
                                            commonController
                                                    .myData.profilePicture !=
                                                'default'
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: profileImage.value.path == '' ||
                                                commonController.myData
                                                            .profilePicture !=
                                                        null &&
                                                    commonController.myData
                                                            .profilePicture !=
                                                        'default'
                                            ? CachedNetworkImage(
                                                fit: BoxFit.cover,
                                                imageUrl: commonController
                                                    .myData.profilePicture!,
                                                height: 125,
                                                width: 125,
                                                progressIndicatorBuilder:
                                                    (context, url,
                                                            downloadProgress) =>
                                                        SizedBox(
                                                  height: 50,
                                                  width: 50,
                                                  child: Center(
                                                      child: CircularProgressIndicator(
                                                          value:
                                                              downloadProgress
                                                                  .progress)),
                                                ),
                                                errorWidget: (context, url,
                                                        error) =>
                                                    SvgPicture.asset(
                                                        "assets/images/profile_placeholder.svg",
                                                        fit: BoxFit.cover),
                                              )
                                            : Image.file(profileImage.value,
                                                width: 125,
                                                height: 125,
                                                fit: BoxFit.cover),
                                      )
                                    : SvgPicture.asset(
                                        "assets/images/profile_placeholder.svg",
                                        fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: SvgPicture.asset(
                                  'assets/images/add_icon.svg'),
                            )
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextFormField(
                          controller: firstNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: appUtils.inputDecoration(
                              'First Name', AppColors.primaryColor),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Please Enter First Name";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextFormField(
                          controller: lastNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: appUtils.inputDecoration(
                              'Last Name', AppColors.primaryColor),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Please Enter Last Name";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: appUtils.inputDecoration(
                              'Email', AppColors.primaryColor),
                          // validator: (value) {
                          //   if (value!.isEmpty) {
                          //     return "Please Enter Email";
                          //   }
                          //   if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                          //     return 'Please Enter Correct Email';
                          //   }
                          //   return null;
                          // },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Obx(() {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          child: TextFormField(
                            controller: addressController.value,
                            keyboardType: TextInputType.multiline,
                            minLines: 1,
                            maxLines: 5,
                            onTap: selectLocationOnMap,
                            readOnly: true,
                            decoration: appUtils.inputDecoration(
                                'Address', AppColors.primaryColor),
                            // validator: (value) {
                            //   if (value!.isEmpty) {
                            //     return "Please Choose Address";
                            //   }
                            //   return null;
                            // },
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextFormField(
                          controller: countryController,
                          textCapitalization: TextCapitalization.words,
                          decoration: appUtils.inputDecoration(
                              'Country', AppColors.primaryColor),
                          // validator: (value) {
                          //   if (value!.isEmpty) {
                          //     return "Please Enter Country";
                          //   }
                          //   return null;
                          // },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextFormField(
                          controller: regionController,
                          textCapitalization: TextCapitalization.words,
                          decoration: appUtils.inputDecoration(
                              'Region', AppColors.primaryColor),
                          // validator: (value) {
                          //   if (value!.isEmpty) {
                          //     return "Please Enter Region";
                          //   }
                          //   return null;
                          // },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Obx(() {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          child: TextFormField(
                            controller: dobController.value,
                            readOnly: true,
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: AppColors.primaryColor,
                                        onPrimary: AppColors.whiteColor,
                                        surface: AppColors.whiteColor,
                                        onSurface: AppColors.primaryColor,
                                      ),
                                      dialogBackgroundColor:
                                          AppColors.whiteColor,
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              dobController.value.text =
                                  DateFormat("dd-MMM-yyyy").format(pickedDate!);
                            },
                            decoration: appUtils.inputDecoration(
                                'Date of Birth', AppColors.primaryColor),
                            // validator: (value) {
                            //   if (value!.isEmpty) {
                            //     return "Please Choose Date of Birth";
                            //   }
                            //   return null;
                            // },
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      if (widget.origin != "Edit")
                        Container(
                            margin: const EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    unselectedWidgetColor:
                                        AppColors.primaryColor,
                                  ),
                                  child: Obx(() {
                                    return Checkbox(
                                      value: checked.value,
                                      activeColor: AppColors.primaryColor,
                                      onChanged: (value) {
                                        checked.value = value!;
                                      },
                                    );
                                  }),
                                ),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: 'Terms & Conditions',
                                            style: const TextStyle(
                                                color: AppColors.primaryColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                decoration:
                                                    TextDecoration.underline),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {}),
                                        const TextSpan(text: '  '),
                                        TextSpan(
                                            text: 'Privacy Policy',
                                            style: const TextStyle(
                                                color: AppColors.primaryColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                decoration:
                                                    TextDecoration.underline),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {}),
                                      ],
                                      text: 'Agree to the ',
                                      style: const TextStyle(
                                          color: AppColors.primaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                      const SizedBox(height: 30),
                      InkWell(
                        onTap: () {
                          if (formKey.currentState!.validate()) {
                            if (widget.origin == "Edit" || checked.value) {
                              if (profileImage.value.path.isNotEmpty) {
                                appUtils.showLoadingDialog();
                                uploadImage();
                              } else {
                                appUtils.showLoadingDialog();
                                uploadUserData();
                              }
                            } else {
                              appUtils.showToast(
                                  'Please Accept our terms & condition and priacy policy');
                            }
                          }
                        },
                        child: Container(
                          height: 45,
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            border: Border.all(color: AppColors.primaryColor),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(30.0)),
                          ),
                          child: Center(
                              child: textUtils.bold16(
                                  widget.origin != "Edit" ? 'Update' : 'Save',
                                  AppColors.whiteColor,
                                  TextAlign.center)),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void selectLocationOnMap() async {
    var result = await Get.to(() => const SelectLocationOnMapScreen());
    if (result != null) {
      addressController.value.text = result[0];
      lat = result[1];
      lng = result[2];
      debugPrint("Selected " + result.toString());
    }
  }

  Future pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg']);
    if (result != null) profileImage.value = File(result.files.single.path!);
  }

  storagePermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      pickImage();
    } else {
      appUtils.showToast('You need to allow permission in order to continue');
    }
  }

  uploadImage() async {
    debugPrint(p.extension(profileImage.value.path));
    Reference ref = storage.ref().child("UsersProfilePicture/").child(
        DateTime.now().millisecondsSinceEpoch.toString() +
            p.extension(profileImage.value.path));
    UploadTask uploadTask = ref.putFile(File(profileImage.value.path));
    final TaskSnapshot downloadUrl = (await uploadTask);
    String url = await downloadUrl.ref.getDownloadURL();

    Map<String, dynamic> value = {'profilePicture': url};

    databaseReference
        .child('Users')
        .child(appUtils.getUserId())
        .update(value)
        .whenComplete(() {
      uploadUserData();
    }).onError((error, stackTrace) {
      Get.back();
      appUtils.showToast(error.toString());
    });
  }

  uploadUserData() {
    Map<String, dynamic> value = {
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'date_of_birth': dobController.value.text,
      'country': countryController.text,
      'region': regionController.text,
      'address': addressController.value.text,
      'latitude': lat ?? "",
      'longitude': lng ?? "",
      'phoneNumber': auth.currentUser!.phoneNumber!,
      'email': emailController.text,
    };
    databaseReference
        .child('Users')
        .child(appUtils.getUserId())
        .update(value)
        .whenComplete(() async {
      saveUser(appUtils.getUserId());
    }).onError((error, stackTrace) {
      Get.back();
      appUtils.showToast(error.toString());
    });
  }

  saveUser(String uid) {
    Query query = databaseReference.child('Users').child(uid);
    query.once().then((DataSnapshot snapshot) {
      if (snapshot.exists) {
        commonController.myData = UserModel.fromJson(Map.from(snapshot.value));
        appUtils.showToast('Profile Updated Successfully');
        if (widget.origin == "Add") {
          Get.offAll(() => const HomeScreen());
        } else {
          Get.back();
        }
      } else {
        Get.back();
        appUtils.showToast('No user found for that id');
      }
    });
  }
}
