import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MyMapPage extends StatefulWidget {
  @override
  _MyMapPageState createState() => _MyMapPageState();
}

class _MyMapPageState extends State<MyMapPage> {
  late GoogleMapController mapController;
  LatLng _center = LatLng(13.7563, 100.5018); // Bangkok
  final Set<Marker> _markers = {};
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = position;
      _center = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: MarkerId('me'),
          position: _center,
          infoWindow: InfoWindow(title: 'You are here'),
        ),
      );
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onMarkerTapped(LatLng position) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'สถานที่: (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})',
              style: TextStyle(fontSize: 16),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Health Places'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed:
                () => mapController.animateCamera(
                  CameraUpdate.newLatLng(_center),
                ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 14.0),
            markers:
                _markers
                    .map(
                      (m) => m.copyWith(
                        onTapParam: () => _onMarkerTapped(m.position),
                      ),
                    )
                    .toSet(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'All',
                  items:
                      ['All', 'Pharmacy', 'Clinic', 'Hospital']
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    // TODO: implement filter logic
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
