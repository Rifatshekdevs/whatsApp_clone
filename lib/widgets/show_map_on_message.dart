import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShowMapOnMessage extends StatefulWidget {
  final double? lat, lng;

  const ShowMapOnMessage({Key? key, this.lat, this.lng}) : super(key: key);

  @override
  _ShowMapOnMessageState createState() => _ShowMapOnMessageState();
}

class _ShowMapOnMessageState extends State<ShowMapOnMessage> {
  late GoogleMapController mapController;

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  MarkerId? selectedMarker;
  int markerIdCounter = 1;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _add();
  }

  void _add() {
    markers.clear();

    final int markerCount = markers.length;

    if (markerCount == 12) {
      return;
    }

    final String markerIdVal = 'marker_id_$markerIdCounter';
    markerIdCounter++;
    final MarkerId markerId = MarkerId(markerIdVal);

    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(widget.lat!, widget.lng!),
      // infoWindow: InfoWindow(title: markerIdVal, snippet: '*'),
    );

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(widget.lat!, widget.lng!), zoom: 17.0),
      ),
    );

    setState(() {
      markers[markerId] = marker;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: 200,
      child: AbsorbPointer(
        absorbing: true,
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          zoomControlsEnabled: false,
          compassEnabled: false,
          myLocationEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          markers: Set<Marker>.of(markers.values),
          initialCameraPosition: CameraPosition(target: LatLng(widget.lat!, widget.lng!), zoom: 17),
        ),
      ),
    );
  }

}
