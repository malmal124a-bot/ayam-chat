import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AdminAuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isAdminLoggedIn = false;
  UserRole? _currentUserRole;
  List<String> _currentUserPermissions = [];
  String? _currentUserId;
  String? _currentUserName;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAdminLoggedIn => _isAdminLoggedIn;
  UserRole? get currentUserRole => _currentUserRole;
  List<String> get currentUserPermissions => List.unmodifiable(_currentUserPermissions);
  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Allowed admin roles (hierarchical)
  static const List<UserRole> _allowedAdminRoles = [
    UserRole.owner,
    UserRole.regionalManager,
    UserRole.appManager,
    UserRole.superAdmin,
    UserRole.agencyAdmin,
    UserRole.bannerAdmin,
    UserRole.moderator,
  ];

  Future<void> init() async {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _checkAdminAccess(user.uid);
      } else {
        _clearAdminSession();
      }
    });
  }

  Future<bool> _checkAdminAccess(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        _errorMessage = 'User not found';
        _clearAdminSession();
        return false;
      }

      final data = doc.data();
      if (data == null) {
        _errorMessage = 'User data not available';
        _clearAdminSession();
        return false;
      }

      final role = UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.user,
      );

      if (!_allowedAdminRoles.contains(role)) {
        _errorMessage = 'Access denied: Insufficient permissions';
        _clearAdminSession();
        return false;
      }

      _isAdminLoggedIn = true;
      _currentUserRole = role;
      _currentUserId = userId;
      _currentUserName = data['name'];
      _currentUserPermissions = (data['permissions'] as List?)?.cast<String>() ?? [];
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      
      debugPrint('Admin access granted: $userId with role: ${role.name}');
      return true;
    } catch (e) {
      _errorMessage = 'Error checking admin access: $e';
      _clearAdminSession();
      return false;
    }
  }

  // Fallback for admin email when Firestore document doesn't exist
  Future<bool> _checkAdminFallback(String email, String userId) async {
    // Allow admin@ayam-chat.com to login even without Firestore document
    if (email == 'admin@ayam-chat.com') {
      debugPrint('Admin fallback: Granting access to admin@ayam-chat.com');
      
      _isAdminLoggedIn = true;
      _currentUserRole = UserRole.owner;
      _currentUserId = userId;
      _currentUserName = 'Admin';
      _currentUserPermissions = [
        'all',
        'manage_users',
        'manage_rooms',
        'manage_agencies',
        'manage_store',
        'manage_banners',
        'manage_moderation',
        'manage_financial',
        'view_analytics',
        'system_config'
      ];
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      
      return true;
    }
    
    return false;
  }

  Future<bool> login(String email, String password) async {
    // HARDCODE BYPASS: Allow admin@ayamchat.com or admin@ayam-chat.com to login without Firebase Auth
    if (email == 'admin@ayamchat.com' || email == 'admin@ayam-chat.com') {
      debugPrint('HARDCODE BYPASS: Granting admin access to $email');
      
      _isAdminLoggedIn = true;
      _currentUserRole = UserRole.owner;
      _currentUserId = 'admin_bypass_uid';
      _currentUserName = 'Admin';
      _currentUserPermissions = [
        'all',
        'manage_users',
        'manage_rooms',
        'manage_agencies',
        'manage_store',
        'manage_banners',
        'manage_moderation',
        'manage_financial',
        'view_analytics',
        'system_config'
      ];
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      
      return true;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final hasAccess = await _checkAdminAccess(credential.user!.uid);
      
      if (!hasAccess) {
        // Try fallback for admin email
        final hasFallbackAccess = await _checkAdminFallback(email, credential.user!.uid);
        
        if (!hasFallbackAccess) {
          await _auth.signOut();
        } else {
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _isLoading = false;
      notifyListeners();
      return hasAccess;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      _clearAdminSession();
      debugPrint('Admin logged out');
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  void _clearAdminSession() {
    _isAdminLoggedIn = false;
    _currentUserRole = null;
    _currentUserPermissions = [];
    _currentUserId = null;
    _currentUserName = null;
    _isLoading = false;
    notifyListeners();
  }

  bool hasPermission(String permission) {
    return _currentUserPermissions.contains(permission) || 
           _currentUserRole == UserRole.superAdmin;
  }

  bool hasRole(UserRole role) {
    return _currentUserRole == role || _currentUserRole == UserRole.superAdmin;
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return 'Authentication failed';
    }
  }
}
