import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:get/get.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zapp_app/colors.dart';
import 'package:zapp_app/controller/common_controller.dart';
import 'package:zapp_app/model/user_model.dart';
import 'package:zapp_app/screens/message_screen.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/utils/text_utils.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({Key? key}) : super(key: key);

  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  TextUtils textUtils = TextUtils();
  AppUtils appUtils = AppUtils();
  final databaseReference = FirebaseDatabase.instance.reference();
  CommonController commonController = Get.find<CommonController>();
  RxBool hasData = false.obs;
  RxBool search = false.obs;
  RxList<UserModel> searchedUsers = <UserModel>[].obs;
  Rx<TextEditingController> searchController = TextEditingController().obs;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    commonController.userModel.clear();
    await databaseReference.child('Users').once().then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        Map<String, dynamic> mapOfMaps = Map.from(snapshot.value);
        for (var value in mapOfMaps.values) {
          if (value['uid'] != appUtils.getUserId()) {
            commonController.userModel.add(UserModel.fromJson(Map.from(value)));
          }
        }
      }
    });

    // contactsPermission();
    hasData.value = true;
  }

  void contactsPermission() async {
    final PermissionStatus permissionStatus = await _getPermission();
    print(permissionStatus);
    if (permissionStatus == PermissionStatus.granted) {
      print("Getting contacts");
      commonController.contactsList.value = await ContactsService.getContacts();
      print("Success");
      for (int i = 0; i < commonController.userModel.length; i++) {
        commonController.contactsList.removeWhere((element) =>
            element.phones!.first.value ==
            commonController.userModel[i].phoneNumber);
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: Text('Permissions error'),
          content: Text(
              'Please enable contacts access permission in system settings'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
    }
  }

  Future<PermissionStatus> _getPermission() async {
    final PermissionStatus permission = await Permission.contacts.status;
    if (permission == PermissionStatus.denied ||
        permission == PermissionStatus.permanentlyDenied) {
      final Map<Permission, PermissionStatus> permissionStatus =
          await [Permission.contacts].request();
      return permissionStatus[Permission.contacts]!;
    } else {
      return permission;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: AppColors.whiteColor,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          centerTitle: false,
          title: search.value
              ? TextFormField(
                  controller: searchController.value,
                  cursorColor: AppColors.whiteColor,
                  keyboardType: TextInputType.text,
                  autofocus: true,
                  textAlign: TextAlign.start,
                  onChanged: onSearchTextChanged,
                  style: const TextStyle(
                      color: AppColors.whiteColor, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(
                        fontSize: 16,
                        color: AppColors.whiteColor,
                        fontFamily: 'SFPro',
                        fontWeight: FontWeight.w500),
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.whiteColor)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.whiteColor)),
                  ),
                )
              : textUtils.bold20(
                  'Select User', AppColors.whiteColor, TextAlign.center),
          elevation: 0.0,
          actions: [
            if (search.value)
              IconButton(
                onPressed: () {
                  search.value = false;
                  searchController.value.text = "";
                },
                icon: const Icon(Icons.close, color: AppColors.whiteColor),
              ),
            if (!search.value)
              IconButton(
                onPressed: () {
                  search.value = true;
                },
                icon: const Icon(Icons.search, color: AppColors.whiteColor),
              ),
          ],
        ),
        body: Obx(() {
          if (hasData.value) {
            if (commonController.userModel.isNotEmpty) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (searchController.value.text.isEmpty)
                      for (int i = 0;
                          i < commonController.userModel.length;
                          i++)
                        showUser(commonController.userModel[i]),
                    if (searchController.value.text.isNotEmpty)
                      for (int i = 0; i < searchedUsers.length; i++)
                        showUser(searchedUsers[i]),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.share,
                              color: AppColors.primaryColor, size: 20),
                          SizedBox(width: 10),
                          textUtils.bold18("Invite Friends",
                              AppColors.primaryColor, TextAlign.start),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    for (int i = 0;
                        i < commonController.contactsList.length;
                        i++)
                      showContact(commonController.contactsList[i]),
                    SizedBox(height: 20),
                  ],
                ),
              );
            } else {
              return Center(
                  child: textUtils.bold20('No Users Found',
                      AppColors.primaryColor, TextAlign.center));
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(
                  backgroundColor: AppColors.whiteColor,
                  color: AppColors.primaryColor),
            );
          }
        }),
      );
    });
  }

  showUser(UserModel userModel) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            Get.to(() => MessageScreen(
                  uid: userModel.uid!,
                  name: userModel.firstName! + ' ' + userModel.lastName!,
                  image: userModel.profilePicture!,
                ));
          },
          child: ListTile(
            title: textUtils.normal16(
                userModel.firstName! + " " + userModel.lastName!,
                AppColors.blackColor,
                TextAlign.start),
            leading: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(30)),
              child: userModel.profilePicture != null &&
                      userModel.profilePicture != 'default'
                  ? CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: userModel.profilePicture!,
                      height: 50,
                      width: 50,
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) => SizedBox(
                        height: 30,
                        width: 30,
                        child: Center(
                            child: CircularProgressIndicator(
                                value: downloadProgress.progress)),
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                          "assets/images/profile_placeholder.png",
                          height: 50,
                          width: 50),
                    )
                  : Image.asset("assets/images/profile_placeholder.png",
                      height: 50, width: 50),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Divider(color: Colors.grey),
        ),
      ],
    );
  }

  showContact(Contact contact) {
    return Column(
      children: [
        ListTile(
          title: textUtils.normal16(
              contact.displayName ?? '', AppColors.blackColor, TextAlign.start),
          leading: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(30)),
            child: contact.avatar != null && contact.avatar!.isNotEmpty
                ? CircleAvatar(backgroundImage: MemoryImage(contact.avatar!))
                : CircleAvatar(child: Text(contact.initials())),
          ),
          trailing: InkWell(
            onTap: share,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              height: 35,
              width: 80,
              decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: AppColors.primaryColor),
                  borderRadius: BorderRadius.circular(10)),
              child: textUtils.normal12(
                  "Invite", AppColors.primaryColor, TextAlign.center),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 30, right: 30),
          child: Divider(color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> share() async {
    await FlutterShare.share(
        title: 'ZappApp share',
        text: 'ZappApp share text',
        linkUrl: 'https://flutter.dev/',
        chooserTitle: '');
  }

  onSearchTextChanged(String text) {
    searchedUsers.clear();
    if (text.isEmpty) {
      return;
    }

    for (var users in commonController.userModel) {
      if (users.firstName!.toLowerCase().contains(text.toLowerCase()) ||
          users.lastName!.toLowerCase().contains(text.toLowerCase())) {
        setState(() {
          searchedUsers.add(users);
        });
      }
    }
  }
}
