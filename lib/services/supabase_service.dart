import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String projectUrl = 'https://dhabrfnfirhhcrdbvzdi.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRoYWJyZm5maXJoaGNyZGJ2emRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY2NDU1MjcsImV4cCI6MjEwMjIyMTUyN30.Mjv1YJh2TM9js8qXmlru0Jzbqoi9GJ1qzx-GQ2o3GeM';

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => Supabase.instance.client.auth.currentUser;

  static String? get currentUserId => currentUser?.id;

  static bool get isLoggedIn => currentUser != null;

  static Timer? _refreshTimer;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: projectUrl,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _startSessionRefresh();
  }

  static void _startSessionRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
      try {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return;
        final expiresAtMs = session.expiresAt;
        if (expiresAtMs == null) return;
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMs * 1000);
        if (expiresAt.difference(DateTime.now()).inMinutes < 5) {
          await Supabase.instance.client.auth.refreshSession();
          debugPrint('SupabaseService: Session refreshed');
        }
      } catch (e) {
        debugPrint('SupabaseService: Session refresh failed: $e');
      }
    });
  }

  static Future<bool> ensureValidSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return false;
      final expiresAtMs = session.expiresAt;
      if (expiresAtMs == null) return true;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMs * 1000);
      if (expiresAt.difference(DateTime.now()).inMinutes < 5) {
        await Supabase.instance.client.auth.refreshSession();
      }
      return true;
    } catch (e) {
      debugPrint('SupabaseService: ensureValidSession failed: $e');
      return false;
    }
  }

  static Stream<AuthState> authStateChanges() =>
      Supabase.instance.client.auth.onAuthStateChange;

  static Future<void> signOut() async {
    _refreshTimer?.cancel();
    await Supabase.instance.client.auth.signOut();
  }

  /// Parses a timestamp returned from Supabase (may be [DateTime] or ISO [String]).
  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String? toIso(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is String) return value;
    return value.toString();
  }
}
