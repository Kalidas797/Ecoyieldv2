// ignore_for_file: unused_element

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class WeatherService {
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  String get apiKey {
    try {
      return dotenv.env['Weather'] ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      if (apiKey.isEmpty) {
        throw Exception('Weather API key is missing. Add Weather to .env');
      }

      // Get current location
      Position position = await _determinePosition();

      print(
        "Position: ${position.latitude}, ${position.longitude}",
      ); // Debug log

      // Make API request to OpenWeather
      final response = await http.get(
        Uri.parse(
          '$baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric',
        ),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        print("OpenWeather response: $data"); // Debug log

        // Get the actual city name from the API response
        String cityName = data['name'] ?? "Unknown Location";

        // Format the data to match our app's structure
        Map<String, dynamic> formattedData = {
          'location': {'name': cityName},
          'data': {
            'values': {
              'temperature': data['main']['temp'],
              'humidity': data['main']['humidity'],
              'windSpeed': data['wind']['speed'],
              'weatherCode': data['weather'][0]['id'],
              'weatherDescription': data['weather'][0]['description'],
            },
          },
        };

        return formattedData;
      } else {
        print('Error status code: ${response.statusCode}');
        print('Error response: ${response.body}');
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception caught: $e');
      throw Exception('Error connecting to weather API: $e');
    }
  }

  // Get location name from coordinates - improved version
  Future<String> _getLocationName(Position position) async {
    try {
      // First try with OpenWeather Geocoding API
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/geo/1.0/reverse?lat=${position.latitude}&lon=${position.longitude}&limit=1&appid=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && data[0]['name'] != null) {
          return data[0]['name'];
        }
      }

      // Fallback to local geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (place.locality != null && place.locality!.isNotEmpty) {
          return place.locality!;
        } else if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          return place.subAdministrativeArea!;
        } else if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          return place.administrativeArea!;
        }
      }

      // Last resort
      return "Your Location";
    } catch (e) {
      print('Error getting location name: $e');
      return "Your Location";
    }
  }

  // Get formatted current date
  String getCurrentDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, d MMMM');
    return formatter.format(now);
  }

  // Location permission handling
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }
}
