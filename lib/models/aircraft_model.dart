import 'package:flutter/material.dart';

enum AircraftType { commercial, military, emergency }

class Aircraft {
  final String icao24;
  final String? callsign;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? velocity;
  final double? track;
  final String? squawk;
  final String? origin;
  final String? destination;
  final AircraftType type;

  bool get emergency => squawk == '7700';

  Color get color {
    if (emergency) return const Color(0xFFFF4444); // Red
    return type == AircraftType.military
        ? const Color(0xFF4488FF) // Blue
        : const Color(0xFFFFDD00); // Yellow
  }

  Aircraft({
    required this.icao24,
    this.callsign,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.velocity,
    this.track,
    this.squawk,
    this.origin,
    this.destination,
    this.type = AircraftType.commercial,
  });

  factory Aircraft.fromJson(Map<String, dynamic> json) {
    final callsign = (json['call'] as String?)?.trim() ?? (json['Flight'] as String?)?.trim();
    final type = _detectAircraftType(json);

    return Aircraft(
      icao24: json['hex'] ?? json['Icao'] ?? 'UNKNOWN',
      callsign: callsign,
      latitude: (json['lat'] ?? json['Lat'] ?? 0.0).toDouble(),
      longitude: (json['lon'] ?? json['Long'] ?? 0.0).toDouble(),
      altitude: _parseDouble(json['alt_baro'] ?? json['Altitude']),
      velocity: _parseDouble(json['gs'] ?? json['Speed']),
      track: _parseDouble(json['track'] ?? json['Track']),
      squawk: json['squawk']?.toString() ?? json['Squawk']?.toString(),
      origin: json['origin'] ?? json['From'],
      destination: json['destination'] ?? json['To'],
      type: type,
    );
  }

  static AircraftType _detectAircraftType(Map<String, dynamic> json) {
    final squawk = json['squawk']?.toString() ?? '';
    if (squawk == '7700') return AircraftType.emergency;

    final category = json['category']?.toString().toLowerCase() ?? '';
    if (category.contains('military')) return AircraftType.military;

    return AircraftType.commercial;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}