import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LocationDataModel {
  final LatLng latLng;
  final String address;
  final String hindiAddress;

  LocationDataModel({
    required this.latLng,
    required this.address,
    required this.hindiAddress,
  });
}

class LocationService {
  static const String googleMapsApiKey = 'YOUR_API_KEY_HERE';

  static Future<LocationDataModel> getLocationWithAddress() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        "User denied permissions to access the device's location.",
      );
    }

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );

    final String address = await _reverseGeocode(position);
    final String hindiAddress = await _getHindiAddress(
      position.latitude,
      position.longitude,
    );

    return LocationDataModel(
      latLng: LatLng(position.latitude, position.longitude),
      address: address,
      hindiAddress: hindiAddress,
    );
  }

  static Future<String> _reverseGeocode(Position position) async {
    try {
      List<Placemark> placeMarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placeMarks.isNotEmpty) {
        final Placemark place = placeMarks.first;
        return '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      } else {
        return 'Unknown address';
      }
    } catch (e) {
      return 'Address not available';
    }
  }

  static Future<String> _getHindiAddress(double lat, double lng) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&language=hi&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
      return 'Hindi address not available';
    } catch (e) {
      return 'Hindi address not available';
    }
  }
}
