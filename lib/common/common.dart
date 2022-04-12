import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Common {
  static String? codeSent;
  static int? resendToken;
  static PhoneAuthCredential? credential;
  static String? apiKey = "AIzaSyBRT_eJWp83FyGvv9tWqvITAsV4uGkam6w";
  static const APP_ID = '8e3d8d5df82341f0834e57fdf018a094';
  static String token = '';
  static const APP_CERTIFICATE = "e163cdff09e642c6b41687b3b1f8359d";

  static List<CustomAudioModel> audioPlayersList = [];
  static bool isSongPlaying = false;

  static String discountUrl = "";
  static String helpUrl = "";
  static String aboutUrl = "";
  static String shopUrl = "";
  static String forumUrl = "";
  static String newsUrl = "";
}

class CustomAudioModel {
  String id;
  AudioPlayer audioPlayer;

  CustomAudioModel(this.id, this.audioPlayer);
}
