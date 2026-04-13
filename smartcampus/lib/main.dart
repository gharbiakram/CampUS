import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_provider.dart';
import 'utils/router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return FutureBuilder(
            future: authProvider.initialize(),
            builder: (context, snapshot) {
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
          );
        },
      ),
    );
  }
}
