import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  final Future<void> Function()? onLogout;

  const SettingsScreen({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Logged in as:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              authProvider.user?.email ?? 'Not logged in',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<SettingsProvider>(
                      builder: (context, settings, _) {
                        return Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Push Notifications'),
                              subtitle:
                                  const Text('Receive class reminders and alerts'),
                              value: settings.pushNotifications,
                              onChanged: (value) async {
                                final messenger = ScaffoldMessenger.of(context);
                                await settings.setPushNotifications(value);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Notifications setting updated'),
                                  ),
                                );
                              },
                            ),
                            SwitchListTile(
                              title: const Text('Offline Mode'),
                              subtitle: const Text('Cache data for offline access'),
                              value: settings.offlineMode,
                              onChanged: (value) async {
                                final messenger = ScaffoldMessenger.of(context);
                                await settings.setOfflineMode(value);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Offline mode setting updated'),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'App Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Version'),
                      subtitle: const Text('1.0.0'),
                    ),
                    ListTile(
                      title: const Text('About'),
                      subtitle: const Text('SmartCampus Companion'),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'SmartCampus Companion',
                          applicationVersion: '1.0.0',
                          applicationLegalese:
                              'A mobile app for navigating campus life.',
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                          onPressed: () {
                          _showLogoutDialog(context, authProvider);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pop(context);
                await onLogout?.call();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
