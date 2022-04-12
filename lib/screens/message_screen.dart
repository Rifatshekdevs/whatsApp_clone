import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zapp_app/colors.dart';
import 'package:zapp_app/controller/common_controller.dart';
import 'package:zapp_app/model/chat_list_model.dart';
import 'package:zapp_app/model/user_model.dart';
import 'package:zapp_app/screens/call_screens/video_call/outgoing_video_call_screen.dart';
import 'package:zapp_app/screens/choose_contact_screen.dart';
import 'package:zapp_app/screens/send_location_screen.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/utils/audio_encoder_type.dart';
import 'package:zapp_app/utils/send_notification_interface.dart';
import 'package:zapp_app/utils/text_utils.dart';
import 'package:zapp_app/widgets/message_widget.dart';
import 'package:zapp_app/voice_recording_widgets/social_media_recorder.dart';

import 'call_screens/audio_call/outgoing_audio_call_screen.dart';

class MessageScreen extends StatefulWidget {
  final String? uid, name, image;

  const MessageScreen({Key? key, this.uid, this.name, this.image})
      : super(key: key);

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  AppUtils utils = AppUtils();
  TextUtils textUtils = TextUtils();

  late FocusNode focusNode = FocusNode();

  CommonController commonController = Get.find<CommonController>();

  late Rx<TextEditingController> messageController =
      TextEditingController().obs;

  ScrollController _scrollController = ScrollController();

  FirebaseStorage storage = FirebaseStorage.instance;
  var databaseReference = FirebaseDatabase.instance.reference();

  late StreamSubscription _onChildAdded;
  late StreamSubscription _onChildUpdate;
  late StreamSubscription _onChildRemoved;

  RxBool emojiShowing = false.obs;
  RxBool showMic = true.obs;

  Rx<File> filePath = File("").obs;
  List<String> imageExtensions = ['jpg', 'png', 'jpeg', 'gif'];
  List<String> videosExtensions = ['mp4', 'mov', 'wmv', 'avi'];
  List<String> docExtensions = [
    'dif',
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'xls',
    'xlsx'
  ];

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(() => _scrollListener());
    commonController.messageListModel.clear();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        emojiShowing.value = false;
      }
    });
    microPhonePermission();
    readMessages();
    super.initState();
  }

  microPhonePermission() async {
    var microPhonePermissionStatus = await Permission.microphone.request();

    if (microPhonePermissionStatus == PermissionStatus.granted) {
      print("Granted");
    } else {
      utils.showToast(
          "You need to allow microphone permission in order to continue");
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {}
  }

  @override
  void dispose() {
    focusNode.dispose();
    _scrollController.dispose();
    messageController.value.dispose();
    _onChildAdded.cancel();
    _onChildUpdate.cancel();
    _onChildRemoved.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (emojiShowing.value) {
          emojiShowing.value = false;
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 80,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.primaryColor),
          title: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(30)),
                child: widget.image != null && widget.image != 'default'
                    ? CachedNetworkImage(
                        fit: BoxFit.cover,
                        imageUrl: widget.image!,
                        height: 40,
                        width: 40,
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
                            height: 40,
                            width: 40),
                      )
                    : Image.asset("assets/images/profile_placeholder.png",
                        height: 40, width: 40),
              ),
              Container(
                margin: const EdgeInsets.only(left: 10),
                child: textUtils.bold16(
                    widget.name!, AppColors.primaryColor, TextAlign.center),
              )
            ],
          ),
          actions: [
            IconButton(
              onPressed: () async {
                var microPhonePermissionStatus =
                    await Permission.microphone.request();

                if (microPhonePermissionStatus == PermissionStatus.granted) {
                  var cameraPermissionStatus =
                      await Permission.camera.request();

                  if (cameraPermissionStatus == PermissionStatus.granted) {
                    Get.to(() => OutgoingVideoCallScreen(
                        name: widget.name,
                        id: widget.uid,
                        image: widget.image));
                  } else {
                    utils.showToast(
                        "You need to allow camera permission in order to continue");
                  }
                } else {
                  utils.showToast(
                      "You need to allow microphone permission in order to continue");
                }
              },
              icon: const Icon(Icons.videocam, color: AppColors.primaryColor),
            ),
            IconButton(
              onPressed: () async {
                var status = await Permission.microphone.request();

                if (status == PermissionStatus.granted) {
                  Get.to(() => OutgoingAudioCallScreen(
                      profilePicture: widget.image,
                      name: widget.name,
                      id: widget.uid));
                } else {
                  utils.showToast(
                      "You need to allow this permission in order to continue");
                }
              },
              icon: const Icon(Icons.call, color: AppColors.primaryColor),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                    flex: 1,
                    child: Obx(() {
                      return SingleChildScrollView(
                        controller: _scrollController,
                        reverse: true,
                        child: Column(
                          children: [
                            for (int i = 0;
                                i < commonController.messageListModel.length;
                                i++)
                              Container(
                                margin:
                                    const EdgeInsets.only(left: 15, right: 15),
                                child: MessageWidget(
                                    messageModel:
                                        commonController.messageListModel[i],
                                    image: widget.image),
                              ),
                          ],
                        ),
                      );
                    })),
                Obx(() => SizedBox(height: emojiShowing.value ? 280 : 80))
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Obx(() {
                return Container(
                  margin: EdgeInsets.only(
                      left: commonController.isShow.value ? 0 : 10,
                      right: commonController.isShow.value ? 0 : 10,
                      bottom: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Card(
                              elevation: 1,
                              color: AppColors.whiteColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.0)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Obx(() {
                                    return InkWell(
                                      onTap: () {
                                        if (emojiShowing.value) {
                                          focusNode.requestFocus();
                                        } else {
                                          focusNode.unfocus();
                                        }
                                        emojiShowing.value =
                                            !emojiShowing.value;
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: Icon(
                                            !emojiShowing.value
                                                ? Icons.sentiment_satisfied_alt
                                                : Icons.keyboard,
                                            color: AppColors.lightGreyColor,
                                            size: 25),
                                      ),
                                    );
                                  }),
                                  Expanded(
                                    child: TextField(
                                      focusNode: focusNode,
                                      controller: messageController.value,
                                      minLines: 1,
                                      maxLines: 6,
                                      onChanged: (value) {
                                        if (value.length > 0) {
                                          showMic.value = false;
                                        } else {
                                          showMic.value = true;
                                        }
                                      },
                                      decoration: utils.messageInputDecoration(
                                          'Message', AppColors.primaryColor),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      showBottomSheet();
                                    },
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 5),
                                      child: Transform.rotate(
                                        angle: 180,
                                        child: Icon(Icons.attachment,
                                            color: AppColors.lightGreyColor,
                                            size: 25),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      cameraPermission('camera');
                                    },
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.only(left: 5, right: 10),
                                      child: Icon(Icons.camera_alt,
                                          color: AppColors.lightGreyColor,
                                          size: 25),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Obx(() {
                            if (!showMic.value) {
                              return InkWell(
                                onTap: () {
                                  if (messageController.value.text.isNotEmpty) {
                                    sendMessage();
                                  }
                                },
                                child: Container(
                                  height: 42,
                                  width: 42,
                                  margin: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                      color: AppColors.primaryColor,
                                      shape: BoxShape.circle),
                                  child: Icon(Icons.send,
                                      size: 16, color: AppColors.whiteColor),
                                ),
                              );
                            } else {
                              return SocialMediaRecorder(
                                backGroundColor: Colors.transparent,
                                sendRequestFunction: (soundFile, duration) {
                                  print(
                                      "the current path is ${soundFile.path} , duration : $duration}");
                                  sendFile(
                                      "audio",
                                      soundFile.path,
                                      soundFile.path.split(".").last,
                                      duration,
                                      "ChatsAudios/");
                                },
                                encode: AudioEncoderType.AAC,
                              );
                            }
                          }),
                        ],
                      ),
                      Obx(() {
                        if (emojiShowing.value) {
                          return SizedBox(
                            height: 200.0,
                            child: pickEmoji(),
                          );
                        } else {
                          return Container();
                        }
                      }),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  pickEmoji() {
    return EmojiPicker(
      onEmojiSelected: (Category category, Emoji emoji) {
        onEmojiSelected(emoji);
      },
      onBackspacePressed: onBackspacePressed,
      config: Config(
        columns: 7,
        emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
        verticalSpacing: 0,
        horizontalSpacing: 0,
        initCategory: Category.RECENT,
        bgColor: Color(0xFFF2F2F2),
        indicatorColor: AppColors.primaryColor,
        iconColor: Colors.grey,
        iconColorSelected: AppColors.primaryColor,
        progressIndicatorColor: AppColors.primaryColor,
        backspaceColor: AppColors.primaryColor,
        skinToneDialogBgColor: Colors.white,
        skinToneIndicatorColor: Colors.grey,
        enableSkinTones: true,
        showRecentsTab: true,
        recentsLimit: 28,
        noRecentsText: "No Recents",
        noRecentsStyle: const TextStyle(fontSize: 20, color: Colors.black26),
        tabIndicatorAnimDuration: kTabScrollDuration,
        categoryIcons: const CategoryIcons(),
        buttonMode: ButtonMode.MATERIAL,
      ),
    );
  }

  onEmojiSelected(Emoji emoji) {
    messageController.value
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: messageController.value.text.length));
    showMic.value = false;
  }

  onBackspacePressed() {
    messageController.value
      ..text = messageController.value.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: messageController.value.text.length));

    if (messageController.value.text.characters.isEmpty) {
      showMic.value = true;
    } else {
      showMic.value = false;
    }
  }

  void showBottomSheet() {
    Get.bottomSheet(
      Container(
        height: 200,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          children: [
            InkWell(
              onTap: () {
                Get.back();
                storagePermission("image");
              },
              child: cardWidget(Icons.image, 'Images', Colors.deepPurpleAccent),
            ),
            InkWell(
              onTap: () {
                Get.back();
                storagePermission("video");
              },
              child: cardWidget(Icons.videocam, 'Videos', Colors.deepOrange),
            ),
            InkWell(
              onTap: () {
                Get.back();
                storagePermission("docs");
              },
              child: cardWidget(Icons.description, 'Documents', Colors.blue),
            ),
            InkWell(
              onTap: () {
                Get.back();
                selectLocationOnMap();
              },
              child: cardWidget(
                  Icons.location_on_outlined, 'Location', Colors.teal),
            ),
            InkWell(
              onTap: () {
                Get.back();
                contactsPermission();
              },
              child: cardWidget(
                  Icons.contact_page_outlined, 'Contacts', Colors.orange),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(35.0), topRight: Radius.circular(35.0)),
      ),
    );
  }

  cardWidget(image, text, color) {
    return Container(
      margin: EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(image, size: 25, color: AppColors.whiteColor),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: textUtils.normal14(
                text, AppColors.primaryColor, TextAlign.center),
          )
        ],
      ),
    );
  }

  sendMessage() {
    int myUid = int.parse(utils.getUserId().toString().numericOnly());
    int otherUid = int.parse(widget.uid.toString().numericOnly());
    if (myUid < otherUid) {
      sentMessageWithType(myUid.toString() + otherUid.toString(), 'text',
          messageController.value.text);
    } else if (otherUid < myUid) {
      sentMessageWithType(otherUid.toString() + myUid.toString(), 'text',
          messageController.value.text);
    }
    messageController.value.text = '';
  }

  sentMessageWithType(uid, type, message) {
    databaseReference.child('Chats').child(uid).push().set({
      'sender': utils.getUserId(),
      'receiver': widget.uid,
      'message': message,
      'type': type,
      'userName': widget.name,
      'userImage': widget.image,
      'time': DateTime.now().millisecondsSinceEpoch.toString()
    });

    Query query = databaseReference
        .child('Chats_List')
        .child(utils.getUserId())
        .orderByChild("uid")
        .equalTo(widget.uid);

    query.once().then((DataSnapshot snapshot) {
      if (snapshot.value == null) {
        addInChatList(utils.getUserId(), message, type);
        addInChatList(widget.uid!, message, type);
      }
      updateLastMessage(message, type);
    });

    if (type == "text") {
      String title = commonController.myData.firstName! +
          " " +
          commonController.myData.lastName! +
          'sent you a message';
      getUserToken(title, message);
    } else if (type == "location" || type == "contact" || type == "audio") {
      String title = "ZappApp";
      String body = commonController.myData.firstName! +
          " " +
          commonController.myData.lastName! +
          'sent you a $type';
      getUserToken(title, body);
    } else {
      String title = commonController.myData.firstName! +
          " " +
          commonController.myData.lastName! +
          'sent you a $type';
      getUserToken(title, message);
    }
  }

  addInChatList(uid, message, type) {
    databaseReference.child('Chats_List').child(uid).push().set({
      'uid': uid == utils.getUserId() ? widget.uid : utils.getUserId(),
      'message': message,
      'type': type,
      'sender': utils.getUserId(),
      'receiver': widget.uid,
      'time': DateTime.now().millisecondsSinceEpoch.toString(),
      'userName': uid != utils.getUserId()
          ? commonController.myData.firstName! +
              " " +
              commonController.myData.lastName!
          : widget.name,
      'userImage': uid != utils.getUserId()
          ? commonController.myData.profilePicture!
          : widget.image,
    });
  }

  updateLastMessage(message, type) async {
    Query query = databaseReference
        .child('Chats_List')
        .child(utils.getUserId())
        .orderByChild("uid")
        .equalTo(widget.uid);
    await query.once().then((DataSnapshot snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> mapOfMaps = Map.from(snapshot.value);
        for (var value in mapOfMaps.keys) {
          databaseReference
              .child('Chats_List')
              .child(utils.getUserId())
              .child(value)
              .update({
            'sender': utils.getUserId(),
            'receiver': widget.uid,
            'message': message,
            'type': type,
            'time': DateTime.now().millisecondsSinceEpoch.toString(),
          });
        }
      }
    });

    Query query1 = databaseReference
        .child('Chats_List')
        .child(widget.uid!)
        .orderByChild("uid")
        .equalTo(utils.getUserId());
    await query1.once().then((DataSnapshot snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> mapOfMaps = Map.from(snapshot.value);
        for (var value in mapOfMaps.keys) {
          databaseReference
              .child('Chats_List')
              .child(widget.uid!)
              .child(value)
              .update({
            'sender': utils.getUserId(),
            'receiver': widget.uid,
            'message': message,
            'type': type,
            'time': DateTime.now().millisecondsSinceEpoch.toString(),
          });
        }
      }
    });
  }

  readMessages() {
    int myUid = int.parse(utils.getUserId().toString().numericOnly());
    int otherUid = int.parse(widget.uid.toString().numericOnly());
    if (myUid < otherUid) {
      readAllMessage(myUid.toString() + otherUid.toString());
    } else if (otherUid < myUid) {
      readAllMessage(otherUid.toString() + myUid.toString());
    }
  }

  readAllMessage(uid) {
    _onChildAdded = databaseReference
        .child("Chats")
        .child(uid)
        .onChildAdded
        .listen((event) {
      if (event.snapshot.value != null) {
        commonController.messageListModel
            .add(ChatListModel.fromJson(Map.from(event.snapshot.value)));
      }
    });

    _onChildRemoved = databaseReference
        .child("Chats")
        .child(uid)
        .onChildRemoved
        .listen((event) {
      if (event.snapshot.value != null) {
        ChatListModel chatListModels =
            ChatListModel.fromJson(Map.from(event.snapshot.value));
        commonController.messageListModel
            .removeWhere((element) => element.uid == chatListModels.uid);
      }
    });

    _onChildUpdate = databaseReference
        .child("Chats")
        .child(uid)
        .onChildChanged
        .listen((event) {
      if (event.snapshot.value != null) {
        ChatListModel chatListModels =
            ChatListModel.fromJson(Map.from(event.snapshot.value));
        var index = commonController.messageListModel
            .indexWhere((item) => item.uid == chatListModels.uid);
        commonController.messageListModel[index] = chatListModels;
      }
    });
  }

  openFile(List<String> extensions, String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: extensions);
    if (result != null) {
      if (extensions.contains(result.files.single.extension)) {
        File file = File(result.files.single.path!);
        filePath.value = File(file.path);
        sendFile(type, result.files.single.path!,
            result.files.single.extension!, "", "ChatsDocuments/");
      } else {
        utils.showToast('This file is not supported');
      }
    }
  }

  sendFile(String type, String path, String extension, String duration,
      String storagePath) async {
    utils.showLoadingDialog();
    Reference ref = storage.ref().child(storagePath).child(
        DateTime.now().millisecondsSinceEpoch.toString() + "." + extension);
    UploadTask uploadTask = ref.putFile(File(path));
    final TaskSnapshot downloadUrlIcon = (await uploadTask);
    String url = await downloadUrlIcon.ref.getDownloadURL();
    // ignore: unnecessary_brace_in_string_interps
    url = duration != "" ? url + "(${duration}" : url;
    int myUid = int.parse(utils.getUserId().toString().numericOnly());
    int otherUid = int.parse(widget.uid.toString().numericOnly());
    Get.back();
    if (myUid < otherUid) {
      sentMessageWithType(myUid.toString() + otherUid.toString(), type, url);
    } else if (otherUid < myUid) {
      sentMessageWithType(otherUid.toString() + myUid.toString(), type, url);
    }
  }

  storagePermission(String type) async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      if (type == 'image') {
        openFile(imageExtensions, type);
      } else if (type == 'video') {
        openFile(videosExtensions, type);
      } else if (type == 'docs') {
        openFile(docExtensions, type);
      }
    } else {
      utils.showToast('You need to allow this permission in order to continue');
    }
  }

  Future pickImageFromCamera(type) async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 30);
    if (pickedFile != null) {
      filePath.value = File(pickedFile.path);
      sendFile(type, pickedFile.path, pickedFile.path.split('.').last, "",
          "ChatsDocuments/");
    }
  }

  cameraPermission(type) async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      pickImageFromCamera(type);
    } else {
      utils.showToast('You need to allow this permission in order to continue');
    }
  }

  void selectLocationOnMap() async {
    var result = await Get.to(() => const SendLocationScreen());
    if (result != null) {
      int myUid = int.parse(utils.getUserId().toString().numericOnly());
      int otherUid = int.parse(widget.uid.toString().numericOnly());
      if (myUid < otherUid) {
        sentMessageWithType(myUid.toString() + otherUid.toString(), 'location',
            '${result[1]},${result[2]}');
      } else if (otherUid < myUid) {
        sentMessageWithType(otherUid.toString() + myUid.toString(), 'location',
            '${result[1]},${result[2]}');
      }
      debugPrint("Selected " + result.toString());
    }
  }

  void contactsPermission() async {
    var status = await Permission.contacts.request();

    if (status == PermissionStatus.granted) {
      Contact? contact = await Get.to(() => const ChooseContactScreen());
      if (contact != null) {
        debugPrint(
            'Selected :  ${contact.displayName},${contact.phones![0].value},${contact.avatar}');
        int myUid = int.parse(utils.getUserId().toString().numericOnly());
        int otherUid = int.parse(widget.uid.toString().numericOnly());
        String imageEncoded = '';
        if (contact.avatar != null && contact.avatar!.isNotEmpty) {
          imageEncoded = base64Encode(contact.avatar!);
        }
        if (myUid < otherUid) {
          sentMessageWithType(myUid.toString() + otherUid.toString(), 'contact',
              '${contact.displayName},${contact.phones![0].value},$imageEncoded');
        } else if (otherUid < myUid) {
          sentMessageWithType(otherUid.toString() + myUid.toString(), 'contact',
              '${contact.displayName},${contact.phones![0].value},$imageEncoded');
        }
      }
    } else {
      utils.showToast('You need to allow permission in order to continue');
    }
  }

  getUserToken(String title, String body) async {
    await databaseReference
        .child('Users')
        .child(widget.uid!)
        .once()
        .then((DataSnapshot snapshot) {
      if (snapshot.exists) {
        UserModel userModel = UserModel.fromJson(Map.from(snapshot.value));
        if (userModel.token != null) {
          SendNotificationInterface()
              .sendNotification(title, body, userModel.token!, 'Message');
        }
      }
    });
  }
}
