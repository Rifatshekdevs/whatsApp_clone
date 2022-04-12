import 'dart:convert';

import 'package:get/get.dart';

class SendNotificationInterface extends GetConnect {
  sendNotification(String? title, String? body, String deviceId, String key) async {
    try {
      Map<String, String> headers = {
        "Authorization": "Bearer " +
            "AAAAKgJ6rH4:APA91bGdXrcbUYTryalTNdn3kYRrisrj3HP4TV4v0JhG81ptGfSNrh_iqCviW8CcppwLsxLL6I82PT4qyRlE0SZPLVEGt1g5L1xDSsWNUfTemB9VtPjKyMjJ7WreV8DJaHAa3wO-Tva9",
        "Content-Type": "application/json"
      };
      Map<dynamic, dynamic> data = {
        "to": deviceId,
        "collapse_key": key,
        "priority": "high",
        "sound": "default",
        "notification": {"title": title, "body": body}
      };
      print(jsonEncode(data));
      var response = await post("https://fcm.googleapis.com/fcm/send", jsonEncode(data), headers: headers);
      print("Status Code : " + response.statusCode.toString() + " body : " + response.bodyString!);
    } catch (e) {
      print(e);
    }
  }
}
