import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:jetstream_live/services/api_service.dart';
import 'package:jetstream_live/services/location_service.dart';
import 'package:jetstream_live/views/flight_detail_card.dart';

class ARScanner extends StatefulWidget {
  const ARScanner({Key? key}) : super(key: key);

  @override
  State<ARScanner> createState() => _ARScannerState();
}

class _ARScannerState extends State<ARScanner> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No camera available')),
          );
        }
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
      );

      await _cameraController.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Aircraft Scanner'),
      ),
      body: Consumer2<LocationService, ApiService>(
        builder: (context, locationService, apiService, _) {
          if (!_isCameraInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          final closestAircraft = locationService.latitude != null &&
                  locationService.longitude != null
              ? apiService.findClosestAircraft(
                  locationService.latitude!,
                  locationService.longitude!,
                )
              : null;

          return Stack(
            children: [
              CameraPreview(_cameraController),
              // Scanning reticle
              Center(
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: ScanningReticlePainter(),
                ),
              ),
              // HUD Information
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (closestAircraft != null) ...[{
                        Text(
                          'Closest Aircraft',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    closestAircraft.callsign ??
                                        closestAircraft.icao24,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Alt: ${closestAircraft.altitude?.toStringAsFixed(0) ?? "N/A"} ft',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'Spd: ${closestAircraft.velocity?.toStringAsFixed(0) ?? "N/A"} kt',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (_) => FlightDetailCard(
                                      aircraft: closestAircraft),
                                );
                              },
                              icon: const Icon(Icons.info),
                              label: const Text('Details'),
                            ),
                          ],
                        ),
                      }] else
                        const Text('No aircraft detected'),
                      if (locationService.heading != null) ...[{
                        const SizedBox(height: 12),
                        Text(
                          'Heading: ${locationService.heading!.toStringAsFixed(0)}°',
                          style: const TextStyle(fontSize: 12),
                        ),
                      }],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
}

class ScanningReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF00).withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const radius = 80.0;

    // Outer circle
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      paint,
    );

    // Corner brackets
    const bracketSize = 20.0;
    const bracketWidth = 3.0;

    // Top-left
    canvas.drawLine(
      Offset(centerX - radius, centerY - radius),
      Offset(centerX - radius + bracketSize, centerY - radius),
      paint..strokeWidth = bracketWidth,
    );
    canvas.drawLine(
      Offset(centerX - radius, centerY - radius),
      Offset(centerX - radius, centerY - radius + bracketSize),
      paint..strokeWidth = bracketWidth,
    );

    // Top-right
    canvas.drawLine(
      Offset(centerX + radius, centerY - radius),
      Offset(centerX + radius - bracketSize, centerY - radius),
      paint..strokeWidth = bracketWidth,
    );
    canvas.drawLine(
      Offset(centerX + radius, centerY - radius),
      Offset(centerX + radius, centerY - radius + bracketSize),
      paint..strokeWidth = bracketWidth,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(centerX - radius, centerY + radius),
      Offset(centerX - radius + bracketSize, centerY + radius),
      paint..strokeWidth = bracketWidth,
    );
    canvas.drawLine(
      Offset(centerX - radius, centerY + radius),
      Offset(centerX - radius, centerY + radius - bracketSize),
      paint..strokeWidth = bracketWidth,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(centerX + radius, centerY + radius),
      Offset(centerX + radius - bracketSize, centerY + radius),
      paint..strokeWidth = bracketWidth,
    );
    canvas.drawLine(
      Offset(centerX + radius, centerY + radius),
      Offset(centerX + radius, centerY + radius - bracketSize),
      paint..strokeWidth = bracketWidth,
    );

    // Center crosshair
    canvas.drawLine(
      Offset(centerX - 10, centerY),
      Offset(centerX + 10, centerY),
      paint..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(centerX, centerY - 10),
      Offset(centerX, centerY + 10),
      paint..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}