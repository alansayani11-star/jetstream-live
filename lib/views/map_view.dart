import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:jetstream_live/services/api_service.dart';
import 'package:jetstream_live/services/location_service.dart';
import 'package:jetstream_live/services/notification_service.dart';
import 'package:jetstream_live/views/ar_scanner.dart';
import 'package:jetstream_live/views/flight_detail_card.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late MapController _mapController;
  Set<String> _emergencyAircraft = {};

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationService = context.read<LocationService>();
      locationService.initialize();

      _startAircraftRefresh();
    });
  }

  void _startAircraftRefresh() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        final locationService = context.read<LocationService>();
        final apiService = context.read<ApiService>();

        if (locationService.latitude != null &&
            locationService.longitude != null) {
          await apiService.fetchAircraft(
            locationService.latitude!,
            locationService.longitude!,
            50,
          );

          _checkEmergencies(apiService);
          _startAircraftRefresh();
        }
      }
    });
  }

  void _checkEmergencies(ApiService apiService) {
    for (var aircraft in apiService.aircraft) {
      if (aircraft.emergency && !_emergencyAircraft.contains(aircraft.icao24)) {
        _emergencyAircraft.add(aircraft.icao24);
        NotificationService.showEmergencyAlert(
          aircraft.callsign ?? aircraft.icao24,
          '${aircraft.latitude.toStringAsFixed(2)}, ${aircraft.longitude.toStringAsFixed(2)}',
          aircraft.latitude,
          aircraft.longitude,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JetStream Live'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ARScanner()),
              );
            },
            tooltip: 'AR Scanner',
          ),
        ],
      ),
      body: Consumer2<LocationService, ApiService>(
        builder: (context, locationService, apiService, _) {
          final userLat = locationService.latitude ?? 37.7749;
          final userLon = locationService.longitude ?? -122.4194;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(userLat, userLon),
                  initialZoom: 10,
                  minZoom: 2,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c'],
                    attributionBuilder: (_) {
                      return const Text('© CartoDB');
                    },
                  ),
                  MarkerLayer(
                    markers: [
                      // User location
                      Marker(
                        point: LatLng(userLat, userLon),
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF4488FF).withOpacity(0.3),
                            border: Border.all(
                              color: const Color(0xFF4488FF),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Color(0xFF4488FF),
                            size: 20,
                          ),
                        ),
                      ),
                      // Aircraft markers
                      ...apiService.aircraft.map((aircraft) {
                        return Marker(
                          point: LatLng(aircraft.latitude, aircraft.longitude),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (_) =>
                                    FlightDetailCard(aircraft: aircraft),
                              );
                            },
                            child: Transform.rotate(
                              angle: (aircraft.track ?? 0) * 3.14159 / 180,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: aircraft.color,
                                  boxShadow: [
                                    BoxShadow(
                                      color: aircraft.color.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.airplanemode_active,
                                  color: Colors.black,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
              // Error message
              if (apiService.error != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      apiService.error!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              // Loading indicator
              if (apiService.isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}