import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyController extends ChangeNotifier {
  static final PrivacyController _instance = PrivacyController._internal();
  factory PrivacyController() => _instance;

  PrivacyController._internal() {
    debugPrint('Initializing: PrivacyController');
    _loadSettings();
  }

  bool _profileVisible = true;
  bool _showOnlineStatus = true;
  bool _allowDirectMessages = true;
  bool _showLastSeen = false;
  bool _allowFriendRequests = true;

  bool get profileVisible => _profileVisible;
  bool get showOnlineStatus => _showOnlineStatus;
  bool get allowDirectMessages => _allowDirectMessages;
  bool get showLastSeen => _showLastSeen;
  bool get allowFriendRequests => _allowFriendRequests;

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 5));
      _profileVisible = prefs.getBool('profile_visible') ?? true;
      _showOnlineStatus = prefs.getBool('show_online_status') ?? true;
      _allowDirectMessages = prefs.getBool('allow_direct_messages') ?? true;
      _showLastSeen = prefs.getBool('show_last_seen') ?? false;
      _allowFriendRequests = prefs.getBool('allow_friend_requests') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      await prefs.setBool('profile_visible', _profileVisible);
      await prefs.setBool('show_online_status', _showOnlineStatus);
      await prefs.setBool('allow_direct_messages', _allowDirectMessages);
      await prefs.setBool('show_last_seen', _showLastSeen);
      await prefs.setBool('allow_friend_requests', _allowFriendRequests);
    } catch (e) {
      debugPrint('Error saving privacy settings: $e');
    }
  }

  void setProfileVisible(bool value) {
    _profileVisible = value;
    _saveSettings();
    notifyListeners();
  }

  void setShowOnlineStatus(bool value) {
    _showOnlineStatus = value;
    _saveSettings();
    notifyListeners();
  }

  void setAllowDirectMessages(bool value) {
    _allowDirectMessages = value;
    _saveSettings();
    notifyListeners();
  }

  void setShowLastSeen(bool value) {
    _showLastSeen = value;
    _saveSettings();
    notifyListeners();
  }

  void setAllowFriendRequests(bool value) {
    _allowFriendRequests = value;
    _saveSettings();
    notifyListeners();
  }
}
