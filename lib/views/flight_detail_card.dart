import 'package:flutter/material.dart';
import 'package:jetstream_live/models/aircraft_model.dart';
import 'package:url_launcher/url_launcher.dart';

class FlightDetailCard extends StatelessWidget {
  final Aircraft aircraft;

  const FlightDetailCard({
    Key? key,
    required this.aircraft,
  }) : super(key: key);

  void _launchLiveATC(String icao) async {
    final url = 'https://www.liveatc.net/search/?q=$icao';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        shrinkWrap: true,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aircraft.callsign ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      aircraft.icao24,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: aircraft.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getAircraftIcon(aircraft.type),
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Status
          if (aircraft.emergency)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4444).withOpacity(0.2),
                border: Border.all(color: const Color(0xFFFF4444)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Color(0xFFFF4444)),
                  SizedBox(width: 8),
                  Text(
                    'EMERGENCY: Squawk 7700',
                    style: TextStyle(
                      color: Color(0xFFFF4444),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Flight Information Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildInfoCard(
                'Altitude',
                aircraft.altitude != null
                    ? '${aircraft.altitude!.toStringAsFixed(0)} ft'
                    : 'N/A',
              ),
              _buildInfoCard(
                'Speed',
                aircraft.velocity != null
                    ? '${aircraft.velocity!.toStringAsFixed(0)} kt'
                    : 'N/A',
              ),
              _buildInfoCard(
                'Heading',
                aircraft.track != null
                    ? '${aircraft.track!.toStringAsFixed(0)}°'
                    : 'N/A',
              ),
              _buildInfoCard(
                'Squawk',
                aircraft.squawk?.toString() ?? 'N/A',
              ),
              _buildInfoCard(
                'Origin',
                aircraft.origin ?? 'N/A',
              ),
              _buildInfoCard(
                'Destination',
                aircraft.destination ?? 'N/A',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Location
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '${aircraft.latitude.toStringAsFixed(4)}, ${aircraft.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final destination = aircraft.destination ?? 'N/A';
                    _launchLiveATC(destination);
                  },
                  icon: const Icon(Icons.radio),
                  label: const Text('Listen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4488FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Open in Google Maps
                    final url =
                        'https://maps.google.com/?q=${aircraft.latitude},${aircraft.longitude}';
                    launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AA00),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAircraftIcon(AircraftType type) {
    switch (type) {
      case AircraftType.commercial:
        return Icons.airplanemode_active;
      case AircraftType.military:
        return Icons.airplanemode_active;
      case AircraftType.emergency:
        return Icons.warning;
    }
  }
}