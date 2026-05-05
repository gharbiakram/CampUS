import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/announcement_provider.dart';
import 'services/auth_provider.dart';
import 'services/campus_sync_service.dart';
import 'services/event_provider.dart';
import 'services/timetable_provider.dart';
import 'services/settings_provider.dart';
import 'services/notification_service.dart';
import 'utils/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  unawaited(NotificationService.instance.initialize());
  unawaited(CampusSyncService.instance.start());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (context) => EventProvider()),
        ChangeNotifierProvider(create: (context) => TimetableProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'SmartCampus Companion',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
              ),
              useMaterial3: true,
            ),
            routerConfig: createGoRouter(authProvider),
          );
        },
      ),
    );
  }
}
