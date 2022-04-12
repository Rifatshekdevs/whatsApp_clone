import 'package:firebase_database/firebase_database.dart';

class ChatListModel {
  String? uid, sender, receiver, message, userName, userImage, type,time;

  ChatListModel({this.uid, this.sender, this.receiver, this.message, this.time, this.userName, this.userImage, this.type});

  ChatListModel.fromSnapshot(DataSnapshot snapshot)
      : uid = snapshot.value["uid"],
        message = snapshot.value["message"],
        userName = snapshot.value["userName"],
        userImage = snapshot.value["userImage"],
        time = snapshot.value["time"],
        type = snapshot.value["type"],
        sender = snapshot.value["sender"],
        receiver = snapshot.value["receiver"];

  toJson() {
    return {
      "uid": uid,
      "message": message,
      "userName": userName,
      "userImage": userImage,
      "time": time,
      "type": type,
      "sender": sender,
      "receiver": receiver,
    };
  }

  ChatListModel.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    message = json['message'];
    time = json['time'];
    userName = json['userName'];
    userImage = json['userImage'];
    type = json['type'];
    sender = json['sender'];
    receiver = json['receiver'];
  }
}
