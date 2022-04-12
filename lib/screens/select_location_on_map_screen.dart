import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zapp_app/colors.dart';
import 'package:zapp_app/common/common.dart';
import 'package:zapp_app/utils/app_utils.dart';
import 'package:zapp_app/utils/text_utils.dart';

class SelectLocationOnMapScreen extends StatefulWidget {
  const SelectLocationOnMapScreen({Key? key}) : super(key: key);

  @override
  _SelectLocationOnMapScreenState createState() =>
      _SelectLocationOnMapScreenState();
}

final homeScaffoldKey = GlobalKey<ScaffoldState>();

class _SelectLocationOnMapScreenState extends State<SelectLocationOnMapScreen> {
  AppUtils utils = AppUtils();
  TextUtils textUtils = TextUtils();
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
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        title: textUtils.normal16(
            'Select Location', AppColors.blackColor, TextAlign.center),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryColor),
      ),
      key: homeScaffoldKey,
      body: Stack(
        children: [
          GoogleMap(
            compassEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: onMapCreated,
            initialCameraPosition:
                const CameraPosition(target: LatLng(0.0, 0.0), zoom: 17),
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: markers,
            onTap: (LatLng pos) {
              setState(() {
                lat = pos.latitude;
                lng = pos.longitude;
                markers.add(Marker(
                  markerId: const MarkerId("newLocation"),
                  position: pos,
                ));
              });
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: AppColors.primaryColor,
                    textStyle: const TextStyle(
                        color: AppColors.accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                  onPressed: () {
                    _handlePressButton();
                  },
                  child: const Text("Search"),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 60, right: 10),
              child: SizedBox(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: AppColors.primaryColor,
                    textStyle: const TextStyle(
                        color: AppColors.accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                  onPressed: () {
                    getUserCurrentLocation();
                  },
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: AppColors.primaryColor,
                    textStyle: const TextStyle(
                        color: AppColors.accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                  onPressed: () {
                    getAddress();
                  },
                  child: const Text("Confirm"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void getAddress() async {
    FetchGeocoder fetchGeocoder = await Geocoder2.getAddressFromCoordinates(
        latitude: lat!, longitude: lng!, googleMapApiKey: Common.apiKey!);
    var first = fetchGeocoder.results.first;
    Get.back(result: [first.formattedAddress, lat.toString(), lng.toString()]);
  }

  void onMapCreated(GoogleMapController controller) async {
    setState(() {
      mapController.complete(controller);
    });
  }

  Future<void> _handlePressButton() async {
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: Common.apiKey!,
      onError: onError,
      mode: Mode.overlay,
      language: "en-us",
      types: [""],
      strictbounds: false,
      decoration: InputDecoration(
        hintText: 'Search',
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Colors.white,
          ),
        ),
      ),
      components: [
        Component(Component.country, "pk"),
        Component(Component.country, "in")
      ],
    );

    displayPrediction(p!, homeScaffoldKey.currentState!);
  }

  Future<void> displayPrediction(Prediction p, ScaffoldState scaffold) async {
    GoogleMapsPlaces _places = GoogleMapsPlaces(
      apiKey: Common.apiKey!,
      apiHeaders: await const GoogleApiHeaders().getHeaders(),
    );
    PlacesDetailsResponse detail =
        await _places.getDetailsByPlaceId(p.placeId.toString());
    lat = detail.result.geometry!.location.lat;
    lng = detail.result.geometry!.location.lng;
    final GoogleMapController controller = await mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat!, lng!), zoom: 17)));
    setState(() {
      markers.add(Marker(
          markerId: const MarkerId("newLocation"),
          position: LatLng(lat!, lng!)));
    });
  }

  void onError(PlacesAutocompleteResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.errorMessage.toString())),
    );
  }

  void getUserCurrentLocation() async {
    var status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      await Geolocator.getCurrentPosition().then((value) async {
        final GoogleMapController controller = await mapController.future;
        setState(() {
          controller.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(value.latitude, value.longitude), zoom: 17)));
          markers.add(Marker(
              markerId: const MarkerId("newLocation"),
              position: LatLng(value.latitude, value.longitude)));
          lat = value.latitude;
          lng = value.longitude;
        });
      });
    } else {
      utils.showToast(
          'You need to allow location permission in order to continue');
    }
  }
}
