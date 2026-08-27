import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:async';
import 'dart:math';
import 'user_controller.dart';
import 'wallet_controller.dart';
import 'agency_controller.dart';
import '../services/supabase_service.dart';
import '../services/cloudinary_service.dart';

class AuthController extends ChangeNotifier {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;

  final SupabaseClient _client = SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => _isLoggedIn;

  AuthController._internal() {
    debugPrint('Initializing: AuthController');
    _loadSession();
    SupabaseService.authStateChanges().listen((event) {
      _isLoggedIn = event.session != null;
      notifyListeners();
    });

    WalletController().addListener(() {
      updateSvipLevel(WalletController().getTotalRecharged());
    });
  }

  static const int standardRate = 10000;
  static const int wholesaleRate = 12000;

  int get currentDiamondRate => UserController().isAgent ? wholesaleRate : standardRate;

  bool _isLoggedIn = false;
  int _svipLevel = 0;
  int get svipLevel => _svipLevel;

  List<Color> get vipColors => [const Color(0xFFFFD700), const Color(0xFFFFA500)];

  Map<String, dynamic>? _agencyApplication;
  Map<String, dynamic>? get agencyApplication => _agencyApplication;

  void saveAgencyApplication(Map<String, dynamic> data) {
    _agencyApplication = data;
    notifyListeners();
  }

  Future<void> submitAgencyApplication() async {
    if (_agencyApplication == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_full_name', _agencyApplication!['name'] ?? '');
      await prefs.setString('profile_phone', _agencyApplication!['phone'] ?? '');
      await prefs.setString('profile_email', _agencyApplication!['email'] ?? '');

      final agencyController = AgencyController();
      await agencyController.submitAgencyRequest(
        agencyName: 'وكالة ${_agencyApplication!['name']}',
        personalName: _agencyApplication!['name'] ?? '',
        nationalId: 'PENDING_VERIFICATION',
        phoneNumber: _agencyApplication!['phone'] ?? '',
        whatsappLink: _agencyApplication!['phone'] ?? '',
        idCardFrontUrl: _agencyApplication!['frontId'] ?? '',
        idCardBackUrl: _agencyApplication!['backId'] ?? '',
        email: _agencyApplication!['email'] ?? '',
        description: 'Selected Tier: \$${_agencyApplication!['selectedTier']}',
        selectedTier: _agencyApplication!['selectedTier'] as int?,
      );

      debugPrint('Agency application successfully submitted.');
    } catch (e) {
      debugPrint('Error in submitAgencyApplication: $e');
    }
  }

  void updateSvipLevel(double totalChargedAmount) {
    int newLevel = (totalChargedAmount / 1000).floor();
    if (newLevel != _svipLevel) {
      _svipLevel = newLevel;
      notifyListeners();
    }
  }

  List<dynamic> get transactionHistory => WalletController().transactions.toList();

  Future<void> _loadSession() async {
    try {
      _isLoggedIn = _client.auth.currentUser != null;
      _svipLevel = (WalletController().getTotalRecharged() / 1000).floor();
      notifyListeners();
    } catch (e) {
      debugPrint('Auth Session Error: $e');
    }
  }

  /// Creates (or updates) the user profile row in Supabase for [authUid].
  Future<String> _ensureUserProfile(
    String authUid, {
    required String name,
    required String email,
    String? photoUrl,
    String? numericId,
  }) async {
    // Check if user already exists
    final existing = await _client
        .from('users')
        .select('numeric_id, diamonds, coins, level, vip_level')
        .eq('auth_uid', authUid)
        .maybeSingle();

    String effectiveNumericId;

    if (existing != null && existing['numeric_id'] != null && (existing['numeric_id'] as String).isNotEmpty) {
      // Existing user — preserve ALL their data, only update profile fields
      effectiveNumericId = existing['numeric_id'];
      await _client.from('users').update({
        'name': name,
        'email': email,
        'photo_url': photoUrl,
        'is_online': true,
      }).eq('auth_uid', authUid);
    } else {
      // Brand new user — create with full defaults
      effectiveNumericId = numericId ?? await _generateUnique6DigitId();
      final row = {
        'auth_uid': authUid,
        'numeric_id': effectiveNumericId,
        'name': name,
        'email': email,
        'photo_url': photoUrl,
        'diamonds': 0,
        'coins': 0,
        'level': 1,
        'vip_level': 0,
        'status': 'Active',
        'is_online': true,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      await _client.from('users').upsert(row, onConflict: 'auth_uid');
    }

    return effectiveNumericId;
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final supabaseUser = res.user;
      if (supabaseUser == null) return false;

      _isLoggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // Ensure a profile row exists for this account
      final existing = await _client
          .from('users')
          .select('auth_uid, numeric_id')
          .eq('auth_uid', supabaseUser.id)
          .maybeSingle();
      if (existing == null) {
        final numericId = await _ensureUserProfile(
          supabaseUser.id,
          name: supabaseUser.userMetadata?['name']?.toString() ?? 'User',
          email: supabaseUser.email ?? email,
          photoUrl: supabaseUser.userMetadata?['avatar_url']?.toString(),
        );
        await prefs.setString('user_id', numericId);
      } else {
        await prefs.setString('user_id', existing['numeric_id'] ?? '');
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('EMAIL_AUTH Error: $e');
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
      );

      final supabaseUser = res.user;
      if (supabaseUser == null) return false;

      final numericId = await _ensureUserProfile(
        supabaseUser.id,
        name: email.split('@').first,
        email: email,
      );

      _isLoggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('user_id', numericId);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('EMAIL_SIGNUP Error: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      // Hosted Supabase OAuth flow (works on web and mobile, no Firebase needed)

      if (!kIsWeb) {
        final completer = Completer<bool>();
        late final StreamSubscription<AuthState> sub;
        sub = _client.auth.onAuthStateChange.listen((event) {
          if (event.session != null) {
            if (!completer.isCompleted) completer.complete(true);
          } else if (event.event == AuthChangeEvent.signedOut) {
            if (!completer.isCompleted) completer.complete(false);
          }
        });

        try {
          await _client.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: 'ayamchat://callback',
          );
          final success = await completer.future
              .timeout(const Duration(minutes: 2), onTimeout: () => false);
          if (!success) return false;
        } finally {
          await sub.cancel();
        }

        final supabaseUser = _client.auth.currentUser;
        if (supabaseUser == null) return false;
        return _completeGoogleAuth(
          supabaseUser,
          googleEmail: supabaseUser.email,
        );
      }

      // Web: the browser redirects to Google, then back to this page with
      // `?code=...`. Handle that callback (or a leftover code from a previous
      // attempt) and otherwise start a fresh flow.
      final uri = Uri.base;

      final webError = uri.queryParameters['error_description'] ??
          uri.queryParameters['error'];
      if (webError != null) {
        debugPrint('WEB_GOOGLE_AUTH Error: $webError');
        return false;
      }

      final code = uri.queryParameters['code'];
      if (code != null) {
        try {
          if (_client.auth.currentSession == null) {
            await _client.auth.exchangeCodeForSession(code);
          }
        } catch (e) {
          debugPrint('WEB_GOOGLE_AUTH Code exchange failed (stale code?): $e');
        }
        final session = _client.auth.currentSession;
        if (session != null) {
          return _completeGoogleAuth(session.user, googleEmail: session.user.email);
        }
        // Fall through to start a fresh flow with a clean redirect URL.
      }

      final cleanRedirect = uri.replace(queryParameters: {}).toString();
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: cleanRedirect,
      );
      return false;
    } catch (e) {
      debugPrint('GOOGLE_AUTH Error: $e');
      return false;
    }
  }

  /// On web, completes the OAuth PKCE callback after the page reloads:
  /// exchanges the `code` returned by the provider (if the SDK did not do it
  /// automatically), ensures the user profile exists, and marks the user as
  /// logged in. Returns true on success.
  Future<bool> handleWebAuthCallback() async {
    if (!kIsWeb) return false;
    try {
      final uri = Uri.base;

      final webError = uri.queryParameters['error_description'] ??
          uri.queryParameters['error'];
      if (webError != null) {
        debugPrint('WEB_OAUTH_CALLBACK Error: $webError');
        return false;
      }

      final code = uri.queryParameters['code'];
      if (code != null && _client.auth.currentSession == null) {
        await _client.auth.exchangeCodeForSession(code);
      }

      final session = _client.auth.currentSession;
      if (session == null) return false;
      return _completeGoogleAuth(session.user, googleEmail: session.user.email);
    } catch (e) {
      debugPrint('WEB_OAUTH_CALLBACK Error: $e');
      return false;
    }
  }

  /// Whether the last auth resulted in a brand-new user (profile was just created).
  bool isNewUser = false;

  Future<bool> _completeGoogleAuth(User? supabaseUser, {String? googleEmail}) async {
    if (supabaseUser == null) return false;

    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    final userEmail = supabaseUser.email ?? googleEmail ?? '';

    // First check by auth_uid (direct match)
    var existing = await _client
        .from('users')
        .select('auth_uid, numeric_id')
        .eq('auth_uid', supabaseUser.id)
        .maybeSingle();

    // If not found by auth_uid, check by email (handles new OAuth token with different auth_uid)
    if (existing == null && userEmail.isNotEmpty) {
      final byEmail = await _client
          .from('users')
          .select('auth_uid, numeric_id')
          .eq('email', userEmail)
          .maybeSingle();
      if (byEmail != null) {
        // Same user, new auth token — update auth_uid to new one
        await _client.from('users').update({
          'auth_uid': supabaseUser.id,
          'is_online': true,
        }).eq('email', userEmail);

        // Also update agencies owner_id if they own one
        final agencyId = 'AG${byEmail['numeric_id']}';
        await _client.from('agencies').update({
          'owner_id': supabaseUser.id,
        }).eq('id', agencyId).eq('owner_id', byEmail['auth_uid']);

        existing = byEmail;
      }
    }

    String numericId;
    if (existing != null && existing['numeric_id'] != null && (existing['numeric_id'] as String).isNotEmpty) {
      numericId = existing['numeric_id'];
      isNewUser = false;
      await _client.from('users').update({
        'name': supabaseUser.userMetadata?['name']?.toString() ?? 'User',
        'email': userEmail,
        'photo_url': supabaseUser.userMetadata?['avatar_url']?.toString(),
        'is_online': true,
      }).eq('auth_uid', supabaseUser.id);
      
      // Check if profile is incomplete (no gender/country set = never went through setup)
      final profileCheck = await _client
          .from('users')
          .select('gender, country')
          .eq('auth_uid', supabaseUser.id)
          .maybeSingle();
      if (profileCheck != null && (profileCheck['gender'] == null || (profileCheck['gender'] as String).isEmpty)) {
        isNewUser = true;
      }
    } else {
      numericId = await _ensureUserProfile(
        supabaseUser.id,
        name: supabaseUser.userMetadata?['name']?.toString() ?? 'User',
        email: userEmail,
        photoUrl: supabaseUser.userMetadata?['avatar_url']?.toString(),
      );
      isNewUser = true;
    }
    await prefs.setString('user_id', numericId);

    notifyListeners();
    return true;
  }

  Future<void> signInWithFacebook() async {
    // Facebook login logic placeholder or fallback
    debugPrint('AuthController: signInWithFacebook called');
  }

  Future<String> _generateUnique6DigitId() async {
    final random = Random();
    while (true) {
      int generated = 100000 + random.nextInt(900000);
      String candidateId = generated.toString();
      final result = await _client
          .from('users')
          .select('numeric_id')
          .eq('numeric_id', candidateId)
          .limit(1);
      if (result.isEmpty) return candidateId;
    }
  }

  Future<void> logout() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid != null) {
        try {
          await _client.from('users').update({'is_online': false}).eq('auth_uid', uid);
        } catch (_) {}
      }
      await SupabaseService.signOut();
      _isLoggedIn = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      notifyListeners();
    } catch (e) {
      debugPrint('Logout Error: $e');
    }
  }

  /// UPLOAD TO CLOUDINARY: Profile photo uploaded and stored as a URL
  Future<void> pickAndUploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 300,
        maxHeight: 300,
      );
      
      if (image != null) {
        final String url = await CloudinaryService.uploadImage(image, folder: 'avatars');
        final uid = SupabaseService.currentUserId;
        if (uid != null) {
          await _client
              .from('users')
              .update({'photo_url': url})
              .eq('auth_uid', uid);
          UserController().updateProfile(newPic: url);
        }
      }
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
    }
  }

  /// Update user balance via WalletController
  void updateBalance(double amount, {String? description, String? method}) {
    WalletController().addBalance(amount, description: description, method: method);
    notifyListeners();
  }
}
