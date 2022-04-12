// ignore_for_file: unnecessary_statements

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zapp_app/controller/common_controller.dart';
import 'package:zapp_app/model/chat_list_model.dart';
import 'package:zapp_app/screens/message_screen.dart';
import 'package:zapp_app/screens/search_user_screen.dart';
import 'package:zapp_app/screens/webview_screen.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/utils/text_utils.dart';

import '../../colors.dart';
import '../app_seetings_screen.dart';

class ChatFragment extends StatefulWidget {
  const ChatFragment({Key? key}) : super(key: key);

  @override
  _ChatFragmentState createState() => _ChatFragmentState();
}

class _ChatFragmentState extends State<ChatFragment> {
  TextUtils textUtils = TextUtils();
  AppUtils appUtils = AppUtils();
  final databaseReference = FirebaseDatabase.instance.reference();
  CommonController commonController = Get.find<CommonController>();
  late StreamSubscription onChildAdded;
  late StreamSubscription onChildRemoved;
  late StreamSubscription onChildUpdate;
  int count = 0;
  RxBool isLoading = true.obs;

  List<ChatListModel> searchedData = <ChatListModel>[].obs;
  Rx<TextEditingController> searchController = TextEditingController().obs;
  RxBool search = false.obs;

  @override
  void initState() {
    super.initState();
    commonController.chatListModel.clear();
    getChatsList();
  }

  getChatsList() async {
    await getChatCount();
    getChats();
  }

  getChatCount() async {
    await databaseReference
        .child("Chats_List")
        .child(appUtils.getUserId())
        .once()
        .then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        count = snapshot.value.length;
      } else {
        isLoading.value = false;
      }
    });
  }

  getChats() async {
    onChildAdded = databaseReference
        .child("Chats_List")
        .child(appUtils.getUserId())
        .onChildAdded
        .listen((event) {
      if (event.snapshot.value != null) {
        commonController.chatListModel
            .add(ChatListModel.fromJson(Map.from(event.snapshot.value)));
      }
      if (count <= commonController.chatListModel.length) {
        isLoading.value = false;
      }
    });

    onChildRemoved = databaseReference
        .child("Chats_List")
        .child(appUtils.getUserId())
        .onChildRemoved
        .listen((event) {
      if (event.snapshot.value != null) {
        ChatListModel chatListModels =
            ChatListModel.fromJson(Map.from(event.snapshot.value));
        commonController.chatListModel
            .removeWhere((element) => element.uid == chatListModels.uid);
      }
    });

    onChildUpdate = databaseReference
        .child("Chats_List")
        .child(appUtils.getUserId())
        .onChildChanged
        .listen((event) {
      if (event.snapshot.value != null) {
        ChatListModel chatListModels =
            ChatListModel.fromJson(Map.from(event.snapshot.value));
        var index = commonController.chatListModel
            .indexWhere((item) => item.uid == chatListModels.uid);
        commonController.chatListModel[index] = chatListModels;
      }
    });
  }

  void contactsPermission() async {
    var status = await Permission.contacts.request();
    if (status == PermissionStatus.granted) {
      Get.to(() => const SearchUserScreen());
    } else {
      appUtils.showToast('You need to allow permission in order to continue');
    }
  }

  @override
  void dispose() {
    super.dispose();
    onChildAdded.cancel();
    onChildRemoved.cancel();
    onChildUpdate.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: AppColors.whiteColor,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            contactsPermission();
          },
          child: Icon(Icons.message, color: AppColors.whiteColor),
        ),
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          centerTitle: false,
          automaticallyImplyLeading: false,
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
                  'Chat', AppColors.whiteColor, TextAlign.center),
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
            if (!search.value)
              PopupMenuButton(
                color: AppColors.whiteColor,
                icon: const Icon(Icons.more_vert, color: AppColors.whiteColor),
                onSelected: (value) {
                  if (value == 1) {
                    Get.to(() => const WebViewScreen(
                        url: "https://www.zappkingmedia.com/mobile.php/about/",
                        name: "About"));
                  } else if (value == 4) {
                    Get.to(() => const AppSettingsScreen());
                  } else if (value == 5) {
                    Get.to(() => const WebViewScreen(
                        url: "https://www.zappkingmedia.com/mobile.php/help/",
                        name: "Help"));
                  }
                  debugPrint(value.toString());
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Image.asset('assets/images/about.png',
                            height: 25, width: 25),
                        const SizedBox(width: 20),
                        textUtils.bold16(
                            'About', AppColors.blackColor, TextAlign.center),
                      ],
                    ),
                    value: 1,
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Image.asset('assets/images/review.png',
                            height: 25, width: 25),
                        const SizedBox(width: 20),
                        textUtils.bold16(
                            'Reviews', AppColors.blackColor, TextAlign.center),
                      ],
                    ),
                    value: 2,
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Image.asset('assets/images/language.png',
                            height: 25, width: 25),
                        const SizedBox(width: 20),
                        textUtils.bold16('Translation', AppColors.blackColor,
                            TextAlign.center),
                      ],
                    ),
                    value: 3,
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Image.asset('assets/images/settings.png',
                            height: 25, width: 25),
                        const SizedBox(width: 20),
                        textUtils.bold16(
                            'Settings', AppColors.blackColor, TextAlign.center),
                      ],
                    ),
                    value: 4,
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Image.asset('assets/images/help.png',
                            height: 25, width: 25),
                        const SizedBox(width: 20),
                        textUtils.bold16(
                            'Help', AppColors.blackColor, TextAlign.center),
                      ],
                    ),
                    value: 5,
                  )
                ],
              ),
          ],
        ),
        body: Obx(() {
          if (!isLoading.value) {
            if (commonController.chatListModel.isNotEmpty) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    if (searchController.value.text.isEmpty)
                      for (int i = 0;
                          i < commonController.chatListModel.length;
                          i++)
                        showMessages(commonController.chatListModel[i]),
                    if (searchController.value.text.isNotEmpty)
                      for (int i = 0; i < searchedData.length; i++)
                        showMessages(searchedData[i]),
                    SizedBox(height: 80),
                  ],
                ),
              );
            } else {
              return Center(
                  child: textUtils.bold20('No Chats Found',
                      AppColors.primaryColor, TextAlign.center));
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(
                backgroundColor: AppColors.whiteColor,
                color: AppColors.primaryColor,
              ),
            );
          }
        }),
      );
    });
  }

  showMessages(ChatListModel chatListModel) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            Get.to(() => MessageScreen(
                uid: chatListModel.uid!,
                image: chatListModel.userImage,
                name: chatListModel.userName));
          },
          child: ListTile(
            title: textUtils.normal16(
                chatListModel.userName, AppColors.blackColor, TextAlign.start),
            subtitle: textUtils.normal14(
                setText(chatListModel), AppColors.greyColor, TextAlign.start),
            trailing: textUtils.normal12(
                appUtils.timeAgoSinceDate('', int.parse(chatListModel.time!)),
                Colors.grey,
                TextAlign.start),
            leading: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(30)),
              child: chatListModel.userImage != null &&
                      chatListModel.userImage != 'default'
                  ? CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: chatListModel.userImage!,
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

  setText(ChatListModel chatListModel) {
    chatListModel.sender == appUtils.getUserId()
        ? "Me: " + chatListModel.message!
        : chatListModel.message;

    if (chatListModel.type == 'text') {
      if (chatListModel.sender == appUtils.getUserId()) {
        return "Me: " + chatListModel.message!;
      } else {
        return chatListModel.message!;
      }
    } else if (chatListModel.type == 'image' ||
        chatListModel.type == 'camera') {
      if (chatListModel.sender == appUtils.getUserId()) {
        return "Me: Sent a photo";
      } else {
        return "Sent you a photo";
      }
    } else if (chatListModel.type == 'audio') {
      if (chatListModel.sender == appUtils.getUserId()) {
        return "Me: Sent an audio";
      } else {
        return "Sent you an audio";
      }
    } else if (chatListModel.type == 'video') {
      if (chatListModel.sender == appUtils.getUserId()) {
        return "Me: Sent a video";
      } else {
        return "Sent you a video";
      }
    } else if (chatListModel.type == 'docs') {
      if (chatListModel.sender == appUtils.getUserId()) {
        return "Me: Sent a file";
      } else {
        return "Sent you a file";
      }
    } else if (chatListModel.type == 'location') {
      if (chatListModel.sender == appUtils.getUserId()) {
        return "Me: Sent a location";
      } else {
        return "Sent you a location";
      }
    } else if (chatListModel.type == 'contact') {
      if (chatListModel.sender == appUtils.getUserId()) {
        return "Me: Sent a contact";
      } else {
        return "Sent you a contact";
      }
    }
  }

  onSearchTextChanged(String text) {
    searchedData.clear();
    if (text.isEmpty) {
      return;
    }

    for (var chats in commonController.chatListModel) {
      if (chats.userName!.toLowerCase().contains(text.toLowerCase())) {
        setState(() {
          searchedData.add(chats);
        });
      }
    }
  }
}
