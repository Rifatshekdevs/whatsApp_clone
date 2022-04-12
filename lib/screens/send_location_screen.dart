import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zapp_app/common/common.dart';
import 'package:zapp_app/model/nearby_places.dart';
import 'package:zapp_app/screens/select_location_on_map_screen.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/utils/text_utils.dart';
import 'package:http/http.dart' as http;

import '../colors.dart';

class SendLocationScreen extends StatefulWidget {
  const SendLocationScreen({Key? key}) : super(key: key);

  @override
  _SendLocationScreenState createState() => _SendLocationScreenState();
}

class _SendLocationScreenState extends State<SendLocationScreen> {
  TextUtils textUtils = TextUtils();
  AppUtils appUtils = AppUtils();
  Rx<NearByPlaces> nearByPlaces = NearByPlaces().obs;
  Completer<GoogleMapController> mapController = Completer();
  Set<Marker> markers = {};
  double? lat, lng;
  String? address, city;

  @override
  void initState() {
    super.initState();
    getUserCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPrimaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkPrimaryColor,
        centerTitle: false,
        title: textUtils.bold20('Send Location', AppColors.whiteColor, TextAlign.center),
        elevation: 0.0,
        actions: [
          IconButton(
            onPressed: selectLocationOnMap,
            icon: const Icon(Icons.search, color: AppColors.whiteColor),
          ),
          IconButton(
            onPressed: () {
              getUserCurrentLocation();
              nearByPlaces.value = NearByPlaces();
            },
            icon: const Icon(Icons.refresh, color: AppColors.whiteColor),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 300,
            width: Get.width,
            child: GoogleMap(
              compassEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: onMapCreated,
              initialCameraPosition: const CameraPosition(target: LatLng(0.0, 0.0), zoom: 17),
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: markers,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      Get.back(result: ['', lat.toString(), lng.toString()]);
                    },
                    child: Container(
                      height: 100,
                      width: Get.width,
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        children: [
                          const FloatingActionButton(
                            backgroundColor: AppColors.whiteColor,
                            onPressed: null,
                            child: Icon(Icons.my_location, color: AppColors.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: textUtils.normal18('Send your current location', AppColors.whiteColor, TextAlign.start))
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: textUtils.normal18('NearBy places', AppColors.whiteColor, TextAlign.start),
                  ),
                  const SizedBox(height: 20),
                  Obx(() {
                    if (nearByPlaces.value.results != null) {
                      if (nearByPlaces.value.results!.isNotEmpty) {
                        return Column(
                          children: [
                            for (int i = 0; i < nearByPlaces.value.results!.length; i++)
                              InkWell(
                                onTap: () {
                                  Get.back(result: [
                                    '',
                                    nearByPlaces.value.results![i].geometry!.location!.lat.toString(),
                                    nearByPlaces.value.results![i].geometry!.location!.lng.toString()
                                  ]);
                                },
                                child: ListTile(
                                  title: textUtils.normal16(nearByPlaces.value.results![i].name, AppColors.whiteColor, TextAlign.start),
                                  subtitle: textUtils.normal14(nearByPlaces.value.results![i].vicinity, AppColors.whiteColor, TextAlign.start),
                                  leading: ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(30)),
                                    child: FloatingActionButton(
                                      backgroundColor: AppColors.whiteColor,
                                      onPressed: null,
                                      child: Image.network(nearByPlaces.value.results![i].icon!, height: 25, width: 25),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      } else {
                        return SizedBox(
                          height: 150,
                          child: Center(child: textUtils.bold20('No Places Found', AppColors.primaryColor, TextAlign.center)),
                        );
                      }
                    } else {
                      return const SizedBox(
                        height: 150,
                        child: Center(
                          child: CircularProgressIndicator(backgroundColor: AppColors.whiteColor, color: AppColors.primaryColor),
                        ),
                      );
                    }
                  })
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void onMapCreated(GoogleMapController controller) async {
    setState(() {
      mapController.complete(controller);
    });
  }

  void getUserCurrentLocation() async {
    var status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      await Geolocator.getCurrentPosition().then((value) async {
        final GoogleMapController controller = await mapController.future;
        setState(() {
          controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(value.latitude, value.longitude), zoom: 17)));
          markers.add(Marker(markerId: const MarkerId("newLocation"), position: LatLng(value.latitude, value.longitude)));
          lat = value.latitude;
          lng = value.longitude;
          getNearByLocations();
        });
      });
    } else {
      appUtils.showToast('You need to allow location permission in order to continue');
    }
  }

  getNearByLocations() async {
    http.Response response = await http.get(Uri.parse("https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng"
        "&radius=100&key=${Common.apiKey}"));
    if (response.statusCode == 200) {
      nearByPlaces.value = NearByPlaces.fromJson(jsonDecode(response.body));
    }
  }

  void selectLocationOnMap() async {
    var result = await Get.to(() => const SelectLocationOnMapScreen());
    if (result != null) {
      Get.back(result: ['', result[1], result[2]]);
      debugPrint("Selected " + result.toString());
    }
  }
}
