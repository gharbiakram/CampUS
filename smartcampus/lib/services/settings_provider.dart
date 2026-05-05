import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _pushKey = 'pref_push_notifications';
  static const _offlineKey = 'pref_offline_mode';

  bool _pushNotifications = true;
  bool _offlineMode = true;

  bool get pushNotifications => _pushNotifications;
  bool get offlineMode => _offlineMode;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _pushNotifications = prefs.getBool(_pushKey) ?? true;
    _offlineMode = prefs.getBool(_offlineKey) ?? true;
    notifyListeners();
  }

  Future<void> setPushNotifications(bool value) async {
    _pushNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushKey, value);
    notifyListeners();
  }

  Future<void> setOfflineMode(bool value) async {
    _offlineMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineKey, value);
    notifyListeners();
  }
}
