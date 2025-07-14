import 'package:flutter/material.dart';
// import 'package:mapbox_gl/mapbox_gl.dart'; // TODO: Fix mapbox dependency
import '../config/app_config.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // MapboxMapController? mapController; // TODO: Fix mapbox dependency

  // void _onMapCreated(MapboxMapController controller) { // TODO: Fix mapbox dependency
  //   mapController = controller;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: const Center(
        child: Text(
          'Map functionality is temporarily disabled.\nMapbox integration needs to be configured.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
      // body: MapboxMap( // TODO: Fix mapbox dependency
      //   accessToken: AppConfig.mapboxAccessToken,
      //   onMapCreated: _onMapCreated,
      //   initialCameraPosition: const CameraPosition(
      //     target: LatLng(0, 0),
      //     zoom: 14.0,
      //   ),
      // ),
    );
  }
}
