import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityController extends ChangeNotifier {
  static final SecurityController _instance = SecurityController._internal();
  factory SecurityController() => _instance;

  SecurityController._internal() {
    debugPrint('Initializing: SecurityController');
    _loadSettings();
  }

  bool _twoFactorEnabled = false;
  bool _biometricEnabled = false;
  bool _loginAlerts = true;
  bool _passwordChangeAlert = true;

  bool get twoFactorEnabled => _twoFactorEnabled;
  bool get biometricEnabled => _biometricEnabled;
  bool get loginAlerts => _loginAlerts;
  bool get passwordChangeAlert => _passwordChangeAlert;

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 5));
      _twoFactorEnabled = prefs.getBool('two_factor_enabled') ?? false;
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _loginAlerts = prefs.getBool('login_alerts') ?? true;
      _passwordChangeAlert = prefs.getBool('password_change_alert') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading security settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      await prefs.setBool('two_factor_enabled', _twoFactorEnabled);
      await prefs.setBool('biometric_enabled', _biometricEnabled);
      await prefs.setBool('login_alerts', _loginAlerts);
      await prefs.setBool('password_change_alert', _passwordChangeAlert);
    } catch (e) {
      debugPrint('Error saving security settings: $e');
    }
  }

  void setTwoFactorEnabled(bool value) {
    _twoFactorEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  void setBiometricEnabled(bool value) {
    _biometricEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  void setLoginAlerts(bool value) {
    _loginAlerts = value;
    _saveSettings();
    notifyListeners();
  }

  void setPasswordChangeAlert(bool value) {
    _passwordChangeAlert = value;
    _saveSettings();
    notifyListeners();
  }
}
