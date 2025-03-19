import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key});

  @override
  _SelectLocationPageState createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  LatLng? _currentLocation;
  LatLng? _mapTapLocation;
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

    _currentLocation = LatLng(position.latitude, position.longitude);
    _mapTapLocation ??= _currentLocation; // Initialize mapTapLocation with current location

    setState(() => _isLoading = false);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation!, 15),
    );
  }

  void _goToCurrentUserLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final currentLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = currentLatLng;
        _isLoading = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 15),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error getting current location: $e");
      // Optionally show an error message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {};
    if (_mapTapLocation != null) {
      markers.add(Marker(markerId: const MarkerId("selected"), position: _mapTapLocation!));
    }
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("currentUser"),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue), // Changed back to default blue marker
          infoWindow: const InfoWindow(title: "Your Location"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation ?? const LatLng(20.5937, 78.9629),
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                if (_currentLocation != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentLocation!, 15),
                  );
                }
              },
              onTap: (LatLng latLng) {
                setState(() => _mapTapLocation = latLng);
              },
              markers: markers,
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "currentLocation",
            onPressed: _goToCurrentUserLocation,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "confirmLocation",
            label: const Text("Confirm"),
            icon: const Icon(Icons.check),
            onPressed: () async {
              if (_mapTapLocation != null) {
                try {
                  List<Placemark> placemarks = await placemarkFromCoordinates(
                    _mapTapLocation!.latitude,
                    _mapTapLocation!.longitude,
                  );

                  if (placemarks.isNotEmpty) {
                    Placemark place = placemarks.first;
                    String address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}, ${place.country ?? ''}';

                    Navigator.pop(context, {
                      'latitude': _mapTapLocation!.latitude,
                      'longitude': _mapTapLocation!.longitude,
                      'address': address,
                    });
                  } else {
                    Navigator.pop(context, {
                      'latitude': _mapTapLocation!.latitude,
                      'longitude': _mapTapLocation!.longitude,
                      'address': 'No address found for this location',
                    });
                  }
                } catch (e) {
                  print("Error fetching address: $e");
                  Navigator.pop(context, {
                    'latitude': _mapTapLocation!.latitude,
                    'longitude': _mapTapLocation!.longitude,
                    'address': 'Error fetching address',
                  });
                }
              }
            },
          ),
        ],
      ),
    );
  }
}