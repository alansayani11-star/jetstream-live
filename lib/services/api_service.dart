import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:jetstream_live/models/aircraft_model.dart';

class ApiService with ChangeNotifier {
  static const String _baseUrl = 'https://api.adsbexchange.com/v2';
  static const String _rapidApiKey = 'YOUR_KEY_HERE'; // Replace with your RapidAPI key
  static const String _rapidApiHost = 'adsbexchange-com1.p.rapidapi.com';

  List<Aircraft> _aircraft = [];
  bool _isLoading = false;
  String? _error;

  List<Aircraft> get aircraft => _aircraft;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAircraft(double lat, double lon, double range) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/lat/$lat/lon/$lon/dist/$range',
        ),
        headers: {
          'X-RapidAPI-Key': _rapidApiKey,
          'X-RapidAPI-Host': _rapidApiHost,
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map && data.containsKey('ac')) {
          final aircraftList = (data['ac'] as List).map((json) {
            return Aircraft.fromJson(json);
          }).toList();
          
          _aircraft = aircraftList;
          _error = null;
        } else {
          _error = 'Invalid response format';
        }
      } else if (response.statusCode == 401) {
        _error = 'Unauthorized: Invalid API Key. Update YOUR_KEY_HERE in api_service.dart';
      } else if (response.statusCode == 429) {
        _error = 'Rate limit exceeded. Please wait before retrying.';
      } else {
        _error = 'Error: ${response.statusCode}';
      }
    } on TimeoutException {
      _error = 'Request timeout. Check your connection.';
    } catch (e) {
      _error = 'Error fetching aircraft: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Aircraft? findClosestAircraft(double userLat, double userLon) {
    if (_aircraft.isEmpty) return null;

    Aircraft closest = _aircraft.first;
    double minDistance = _calculateDistance(
      userLat,
      userLon,
      closest.latitude,
      closest.longitude,
    );

    for (var aircraft in _aircraft) {
      double distance = _calculateDistance(
        userLat,
        userLon,
        aircraft.latitude,
        aircraft.longitude,
      );
      if (distance < minDistance) {
        closest = aircraft;
        minDistance = distance;
      }
    }

    return closest;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}