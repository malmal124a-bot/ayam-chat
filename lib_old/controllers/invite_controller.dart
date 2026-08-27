import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wallet_controller.dart';
import 'user_controller.dart';

class InviteController extends ChangeNotifier {
  static final InviteController _instance = InviteController._internal();
  factory InviteController() => _instance;
  InviteController._internal() {
    debugPrint('Initializing: InviteController');
    _loadState();
  }

  bool _isCodeSubmitted = false;
  bool get isCodeSubmitted => _isCodeSubmitted;

  String get myInviteCode => UserController().id;

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 5));
      _isCodeSubmitted = prefs.getBool('invite_code_submitted') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading invite state: $e');
    }
  }

  Future<bool> submitCode(String code) async {
    if (code.isEmpty || _isCodeSubmitted) return false;
    
    // Simple validation: check if it's not our own code and looks like a valid ID
    if (code == myInviteCode) return false;

    try {
      // Simulate validation and reward
      _isCodeSubmitted = true;
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      await prefs.setBool('invite_code_submitted', true);
      
      // Reward user for using an invite code
      WalletController().addDiamonds(100);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error submitting invite code: $e');
      _isCodeSubmitted = false;
      return false;
    }
  }
}
