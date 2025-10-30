import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class MyMapPage extends StatefulWidget {
  @override
  _MyMapPageState createState() => _MyMapPageState();
}

class _MyMapPageState extends State<MyMapPage> {
  late GoogleMapController mapController;
  LatLng? _center;
  String _selectedFilter = 'All';
  final _apiKey = 'AIzaSyDK3IOOywb04xIxp68vgpsuMf5L89uiiVI'; // 🔑

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print('❌ Permission denied');
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _center = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _onMapTapped(LatLng latLng) async {
    final placeInfo = await _getPlaceDetails(latLng);
    if (placeInfo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ไม่พบข้อมูลสถานที่')));
      return;
    }
    _showPlaceBottomSheet(latLng, placeInfo);
  }

  Future<Map<String, dynamic>?> _getPlaceDetails(LatLng latLng) async {
    try {
      final geoUrl =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$_apiKey';
      print('🔍 geoUrl: $geoUrl');
      final geoRes = await http.get(Uri.parse(geoUrl));
      final geoData = jsonDecode(geoRes.body);
      if (geoData['status'] != 'OK' || geoData['results'].isEmpty) return null;

      final result = geoData['results'].firstWhere(
        (r) =>
            (r['types'] as List).contains('establishment') ||
            (r['types'] as List).contains('point_of_interest') ||
            (r['types'] as List).contains('premise') ||
            (r['types'] as List).contains('route') ||
            (r['types'] as List).contains('street_address'),
        orElse: () => geoData['results'][0],
      );

      final address = result['formatted_address'];
      final placeId = result['place_id'];

      final detailUrl =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,formatted_phone_number,rating,opening_hours&key=$_apiKey';
      final detailRes = await http.get(Uri.parse(detailUrl));
      final detailData = jsonDecode(detailRes.body);

      if (detailData['status'] != 'OK') {
        print('⚠️ ไม่มี Place Details สำหรับ: $placeId');
        return {
          'name': '(ไม่ทราบชื่อ)',
          'address': address,
          'phone': '',
          'rating': '-',
          'opening_hours': '',
        };
      }

      final place = detailData['result'];

      return {
        'name': place['name'] ?? '(ไม่ทราบชื่อ)',
        'address': address,
        'phone': place['formatted_phone_number'] ?? '',
        'rating': place['rating']?.toString() ?? '-',
        'opening_hours':
            (place['opening_hours']?['weekday_text'] as List?)?.join('\n') ??
            '',
      };
    } catch (e) {
      print('❌ Error in _getPlaceDetails: $e');
      return null;
    }
  }

  void _showPlaceBottomSheet(LatLng latLng, Map data) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'], style: TextStyle(fontSize: 18)),
                Text(data['address']),
                if (data['phone'] != '') Text('โทร: ${data['phone']}'),
                if (data['rating'] != '-') Text('⭐ ${data['rating']}'),
                if (data['opening_hours'] != '')
                  Text(data['opening_hours'], style: TextStyle(fontSize: 12)),
                ElevatedButton.icon(
                  icon: Icon(Icons.navigation),
                  label: Text("นำทางด้วย Google Maps"),
                  onPressed: () async {
                    final url =
                        'https://www.google.com/maps/dir/?api=1&destination=${latLng.latitude},${latLng.longitude}';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _searchNearbyByType(String type) async {
    if (_center == null || type == 'All') return;

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_center!.latitude},${_center!.longitude}&radius=3000&type=$type&key=$_apiKey';
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);
    if (data['status'] != 'OK' || data['results'].isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ไม่พบสถานที่ในประเภทที่เลือก')));
      return;
    }

    final result = data['results'][0];
    final pos = LatLng(
      result['geometry']['location']['lat'],
      result['geometry']['location']['lng'],
    );
    mapController.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
    await _onMapTapped(pos);
  }

  @override
  Widget build(BuildContext context) {
    if (_center == null) {
      return Scaffold(
        appBar: AppBar(title: Text('แผนที่')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Map'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilter,
              icon: Icon(Icons.filter_list, color: Colors.white),
              dropdownColor: Colors.white,
              items: [
                DropdownMenuItem(value: 'All', child: Text('ทั้งหมด')),
                DropdownMenuItem(value: 'pharmacy', child: Text('ร้านขายยา')),
                DropdownMenuItem(value: 'hospital', child: Text('โรงพยาบาล')),
                DropdownMenuItem(value: 'doctor', child: Text('คลินิก')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFilter = value);
                  _searchNearbyByType(value);
                }
              },
            ),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _center!, zoom: 15),
        onMapCreated: (controller) => mapController = controller,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onTap: _onMapTapped,
      ),
    );
  }
}
