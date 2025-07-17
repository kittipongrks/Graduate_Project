import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyMapPage extends StatefulWidget {
  @override
  _MyMapPageState createState() => _MyMapPageState();
}

class _MyMapPageState extends State<MyMapPage> {
  late GoogleMapController mapController;
  LatLng? _center;
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _getCurrentLocation();
      await loadMarkersFromFirestore();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location permission denied')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission permanently denied')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng userLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = position;
        _center = userLatLng;
        _markers
          ..removeWhere((m) => m.markerId == MarkerId('me'))
          ..add(
            Marker(
              markerId: MarkerId('me'),
              position: userLatLng,
              infoWindow: InfoWindow(title: 'You are here'),
            ),
          );
      });

      if (mapController != null) {
        mapController.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 16));
      }
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ไม่สามารถดึงตำแหน่งได้')));
    }
  }

  Future<void> loadMarkersFromFirestore([String? category]) async {
    final query = FirebaseFirestore.instance.collection('places');
    final snapshot =
        category == null || category == 'All'
            ? await query.get()
            : await query.where('category', isEqualTo: category).get();

    final newMarkers =
        snapshot.docs.map((doc) {
          final data = doc.data();
          final LatLng position = LatLng(data['latitude'], data['longitude']);
          return Marker(
            markerId: MarkerId(doc.id),
            position: position,
            infoWindow: InfoWindow(title: data['name']),
            onTap: () => _onMarkerTapped(position),
          );
        }).toSet();

    setState(() {
      _markers.removeWhere((m) => m.markerId != MarkerId('me'));
      _markers.addAll(newMarkers);
    });
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
    if (_center == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Nearby Health Places')),
        body: Center(child: CircularProgressIndicator()), // ✅ โหลดตำแหน่ง
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Health Places'),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center!, zoom: 14.0),
            markers: _markers,
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
                  value: _selectedCategory,
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
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                      loadMarkersFromFirestore(value);
                    }
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
