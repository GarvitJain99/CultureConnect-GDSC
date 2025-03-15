import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key});

  @override
  _SelectLocationPageState createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  LatLng? _selectedLatLng;
  GoogleMapController? _mapController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _selectedLatLng = LatLng(position.latitude, position.longitude);

    setState(() => _isLoading = false);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_selectedLatLng!, 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLatLng ?? const LatLng(20.5937, 78.9629), // Default to India if location not found
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                if (_selectedLatLng != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(_selectedLatLng!, 15),
                  );
                }
              },
              onTap: (LatLng latLng) {
                setState(() => _selectedLatLng = latLng);
              },
              markers: _selectedLatLng != null
                  ? {Marker(markerId: const MarkerId("selected"), position: _selectedLatLng!)}
                  : {},
            ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("Confirm"),
        icon: const Icon(Icons.check),
        onPressed: () {
          if (_selectedLatLng != null) {
            Navigator.pop(context, _selectedLatLng);
          }
        },
      ),
    );
  }
}