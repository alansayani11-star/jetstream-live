import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jetstream_live/services/api_service.dart';
import 'package:jetstream_live/services/location_service.dart';
import 'package:jetstream_live/services/notification_service.dart';
import 'package:jetstream_live/views/map_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService.initialize();
  
  runApp(const JetStreamLiveApp());
}

class JetStreamLiveApp extends StatelessWidget {
  const JetStreamLiveApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'JetStream Live',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF1A1A2E),
          scaffoldBackgroundColor: const Color(0xFF0F0F1E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A2E),
            elevation: 0,
          ),
        ),
        home: const MapView(),
      ),
    );
  }
}