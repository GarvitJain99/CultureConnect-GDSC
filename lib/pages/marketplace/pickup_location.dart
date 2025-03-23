import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PickupLocationPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const PickupLocationPage(
      {super.key, this.initialLatitude, this.initialLongitude});

  @override
  _PickupLocationPageState createState() => _PickupLocationPageState();
}

class _PickupLocationPageState extends State<PickupLocationPage> {
  LatLng? _currentLocation;
  LatLng? _mapTapLocation;
  GoogleMapController? _mapController;
  bool _isLoading = true;
  String? _currentAddress;

  @override
  void initState() {
    super.initState();
    _getUserLocation().then((_) {
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        _mapTapLocation =
            LatLng(widget.initialLatitude!, widget.initialLongitude!);
        _getAddressFromLatLng(_mapTapLocation!)
            .then((_) => setState(() => _isLoading = false));
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_mapTapLocation!, 15),
        );
      } else {
        _mapTapLocation = _currentLocation;
        _getAddressFromLatLng(_currentLocation!)
            .then((_) => setState(() => _isLoading = false));
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15),
        );
      }
    });
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
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _currentAddress =
              '${place.name ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}, ${place.country ?? ''}';
        });
      } else {
        setState(() {
          _currentAddress = 'No address found for this location';
        });
      }
    } catch (e) {
      print("Error fetching address: $e");
      setState(() {
        _currentAddress = 'Error fetching address';
      });
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {};
    if (_mapTapLocation != null) {
      markers.add(Marker(
          markerId: const MarkerId("selected"), position: _mapTapLocation!));
    }

    Set<Circle> circles = {};
    if (_currentLocation != null) {
      circles.add(
        Circle(
          circleId: const CircleId('currentUserCircle'),
          center: _currentLocation!,
          radius: 50,
          fillColor: Colors.blue.withOpacity(0.3),
          strokeColor: Colors.blue.withOpacity(0.8),
          strokeWidth: 1,
        ),
      );
    }

    LatLng initialMapCenter;
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      initialMapCenter =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
    } else {
      initialMapCenter = _currentLocation ?? const LatLng(20.5937, 78.9629);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _currentAddress ?? 'Fetching Address...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialMapCenter,
                      zoom: 15,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onTap: (LatLng latLng) async {
                      setState(() => _mapTapLocation = latLng);
                      await _getAddressFromLatLng(latLng);
                    },
                    markers: markers,
                    circles: circles,
                    padding: const EdgeInsets.only(bottom: 80.0, right: 16.0),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
                String address =
                    '${place.name ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}, ${place.country ?? ''}';

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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
