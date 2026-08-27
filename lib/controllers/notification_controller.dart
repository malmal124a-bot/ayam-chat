import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationController extends ChangeNotifier {
  static final NotificationController _instance = NotificationController._internal();
  factory NotificationController() => _instance;

  NotificationController._internal() {
    debugPrint('Initializing: NotificationController');
    _loadSettings();
  }

  bool _pushNotifications = true;
  bool _messageNotifications = true;
  bool _roomNotifications = true;
  bool _giftNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  bool get pushNotifications => _pushNotifications;
  bool get messageNotifications => _messageNotifications;
  bool get roomNotifications => _roomNotifications;
  bool get giftNotifications => _giftNotifications;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 5));
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _messageNotifications = prefs.getBool('message_notifications') ?? true;
      _roomNotifications = prefs.getBool('room_notifications') ?? true;
      _giftNotifications = prefs.getBool('gift_notifications') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      await prefs.setBool('push_notifications', _pushNotifications);
      await prefs.setBool('message_notifications', _messageNotifications);
      await prefs.setBool('room_notifications', _roomNotifications);
      await prefs.setBool('gift_notifications', _giftNotifications);
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('vibration_enabled', _vibrationEnabled);
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  void setPushNotifications(bool value) {
    _pushNotifications = value;
    _saveSettings();
    notifyListeners();
  }

  void setMessageNotifications(bool value) {
    _messageNotifications = value;
    _saveSettings();
    notifyListeners();
  }

  void setRoomNotifications(bool value) {
    _roomNotifications = value;
    _saveSettings();
    notifyListeners();
  }

  void setGiftNotifications(bool value) {
    _giftNotifications = value;
    _saveSettings();
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  void setVibrationEnabled(bool value) {
    _vibrationEnabled = value;
    _saveSettings();
    notifyListeners();
  }
}
