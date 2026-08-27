import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';

class AdminAuthController extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;
  
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
    SupabaseService.authStateChanges().listen((event) async {
      final user = event.session?.user;
      if (user != null) {
        await _checkAdminAccess(user.id);
      } else {
        _clearAdminSession();
      }
    });
  }

  Future<bool> _checkAdminAccess(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final row = await _client
          .from('users')
          .select()
          .eq('auth_uid', userId)
          .maybeSingle();
      
      if (row == null) {
        _errorMessage = 'User not found';
        _clearAdminSession();
        return false;
      }

      final role = UserRole.values.firstWhere(
        (e) => e.name == row['role'],
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
      _currentUserName = row['name'];
      _currentUserPermissions = (row['permissions'] as List?)?.cast<String>() ?? [];
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

  // Fallback for admin email when user document doesn't exist in Supabase
  Future<bool> _checkAdminFallback(String email, String userId) async {
    // Allow admin@ayam-chat.com to login even without Supabase user document
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
    // HARDCODE BYPASS: Allow admin@ayamchat.com or admin@ayam-chat.com to login without Supabase Auth
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

      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final hasAccess = await _checkAdminAccess(res.user!.id);
      
      if (!hasAccess) {
        // Try fallback for admin email
        final hasFallbackAccess = await _checkAdminFallback(email, res.user!.id);
        
        if (!hasFallbackAccess) {
          await _client.auth.signOut();
        } else {
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _isLoading = false;
      notifyListeners();
      return hasAccess;
    } on AuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.message);
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
      await SupabaseService.signOut();
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

  String _getAuthErrorMessage(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid email') || msg.contains('email not confirmed')) {
      return 'Invalid email or password';
    }
    if (msg.contains('user') && msg.contains('found')) {
      return 'No user found with this email';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many attempts. Please try again later';
    }
    if (msg.contains('disabled')) {
      return 'This account has been disabled';
    }
    return 'Authentication failed: $message';
  }
}
