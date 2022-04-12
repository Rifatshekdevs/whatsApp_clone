import 'package:firebase_database/firebase_database.dart';

class UserModel {
  String? uid, email, firstName, lastName, profilePicture, phoneNumber, dateOfBirth, token;
  String? address, latitude, longitude, region, country;

  UserModel({
    this.uid,
    this.email,
    this.firstName,
    this.lastName,
    this.profilePicture,
    this.phoneNumber,
    this.address,
    this.country,
    this.region,
    this.latitude,
    this.dateOfBirth,
    this.token,
    this.longitude,
  });

  UserModel.fromSnapshot(DataSnapshot snapshot)
      : uid = snapshot.value["uid"],
        email = snapshot.value["email"],
        firstName = snapshot.value["firstName"],
        lastName = snapshot.value["lastName"],
        profilePicture = snapshot.value["profilePicture"],
        phoneNumber = snapshot.value["phoneNumber"],
        address = snapshot.value["address"],
        country = snapshot.value["country"],
        region = snapshot.value["region"],
        latitude = snapshot.value["latitude"],
        longitude = snapshot.value["longitude"],
        dateOfBirth = snapshot.value["date_of_birth"],
        token = snapshot.value["token"];

  UserModel.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    email = json['email'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    profilePicture = json['profilePicture'];
    phoneNumber = json['phoneNumber'];
    address = json['address'];
    country = json['country'];
    region = json['region'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    dateOfBirth = json['date_of_birth'];
    token = json['token'];
  }
}
