import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/announcement_provider.dart';
import 'services/auth_provider.dart';
import 'utils/router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => AnnouncementProvider()),
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
