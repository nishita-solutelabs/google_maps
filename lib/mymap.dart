import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MyMap extends StatefulWidget {
  @override
  _MyMapState createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  StreamSubscription<LocationData> _locationSubscription;
  final Location _locationTracker = Location();
  GoogleMapController _controller;
  Marker marker;
  Circle circle;

  final CameraPosition _initiallocation = const CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 16,
  );

  Future<Uint8List> getCarMarker() async {
    final ByteData byteData =
        await DefaultAssetBundle.of(context).load("assets/car_icon.png");
    return byteData.buffer.asUint8List();
  }

  void updateCircleAndMarker(LocationData newLocation, Uint8List imageData) {
    final LatLng latLng = LatLng(newLocation.latitude, newLocation.longitude);

    setState(() {
      marker = Marker(
        markerId: MarkerId('car'),
        position: latLng,
        rotation: newLocation.heading,
        anchor: const Offset(0.5, 0.5),
        zIndex: 2,
        flat: true,
        icon: BitmapDescriptor.fromBytes(imageData),
      );
      circle = Circle(
        circleId: CircleId('Circle'),
        radius: newLocation.accuracy,
        zIndex: 1,
        strokeColor: Colors.blue,
        center: latLng,
      );
    });
  }

  Future<void> getCurrentLocation() async {
    try {
      final Uint8List imagedata = await getCarMarker();
      final LocationData location = await _locationTracker.getLocation();

      updateCircleAndMarker(location, imagedata);

      if (_locationSubscription != null) {
        _locationSubscription.cancel();
      }

      _locationSubscription =
          _locationTracker.onLocationChanged.listen((LocationData newLocaion) {
        if (_controller != null) {
          _controller
              .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
            target: LatLng(newLocaion.latitude, newLocaion.longitude),
            zoom: 16.0,
            bearing: 180.0,
            tilt: 1.0,
          )));
          updateCircleAndMarker(newLocaion, imagedata);
        }
      });
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: _initiallocation,
        // ignore: always_specify_types
        markers: Set<Marker>.of((marker != null) ? [marker] : []),
        // ignore: always_specify_types
        circles: Set<Circle>.of((circle != null) ? [circle] : []),
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          getCurrentLocation();
        },
        tooltip: 'Current Location',
        child: const Icon(
          Icons.location_searching,
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_locationSubscription != null) {
      _locationSubscription.cancel();
    }
    super.dispose();
  }
}
