import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';

class AdminRBACController extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;
  
  List<UserModel> _allAdmins = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get allAdmins => List.unmodifiable(_allAdmins);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Role hierarchy with financial access flags
  static final Map<UserRole, RBACPermissions> _rolePermissions = {
    UserRole.owner: RBACPermissions(
      canModifyFinancials: true,
      canGrantRoles: true,
      canRevokeRoles: true,
      canGrantTimedAccess: true,
      canManageAgencies: true,
      canBanUsers: true,
      canManageStore: true,
      canConfigureAI: true,
      canManageBanners: true,
      canAdjustRTP: true,
      canManageModerators: true,
    ),
    UserRole.regionalManager: RBACPermissions(
      canModifyFinancials: false,
      canGrantRoles: false,
      canRevokeRoles: false,
      canGrantTimedAccess: false,
      canManageAgencies: true,
      canBanUsers: true,
      canManageStore: false,
      canConfigureAI: false,
      canManageBanners: false,
      canAdjustRTP: false,
      canManageModerators: true,
    ),
    UserRole.appManager: RBACPermissions(
      canModifyFinancials: false,
      canGrantRoles: false,
      canRevokeRoles: false,
      canGrantTimedAccess: false,
      canManageAgencies: false,
      canBanUsers: true,
      canManageStore: false,
      canConfigureAI: false,
      canManageBanners: false,
      canAdjustRTP: false,
      canManageModerators: false,
    ),
    UserRole.superAdmin: RBACPermissions(
      canModifyFinancials: false,
      canGrantRoles: false,
      canRevokeRoles: false,
      canGrantTimedAccess: false,
      canManageAgencies: true,
      canBanUsers: true,
      canManageStore: true,
      canConfigureAI: false,
      canManageBanners: true,
      canAdjustRTP: false,
      canManageModerators: true,
    ),
    UserRole.agencyAdmin: RBACPermissions(
      canModifyFinancials: false,
      canGrantRoles: false,
      canRevokeRoles: false,
      canGrantTimedAccess: false,
      canManageAgencies: true,
      canBanUsers: false,
      canManageStore: false,
      canConfigureAI: false,
      canManageBanners: false,
      canAdjustRTP: false,
      canManageModerators: false,
    ),
    UserRole.bannerAdmin: RBACPermissions(
      canModifyFinancials: false,
      canGrantRoles: false,
      canRevokeRoles: false,
      canGrantTimedAccess: false,
      canManageAgencies: false,
      canBanUsers: false,
      canManageStore: true,
      canConfigureAI: false,
      canManageBanners: true,
      canAdjustRTP: false,
      canManageModerators: false,
    ),
    UserRole.moderator: RBACPermissions(
      canModifyFinancials: false,
      canGrantRoles: false,
      canRevokeRoles: false,
      canGrantTimedAccess: false,
      canManageAgencies: false,
      canBanUsers: true,
      canManageStore: false,
      canConfigureAI: false,
      canManageBanners: false,
      canAdjustRTP: false,
      canManageModerators: false,
    ),
    UserRole.user: RBACPermissions(
      canModifyFinancials: false,
      canGrantRoles: false,
      canRevokeRoles: false,
      canGrantTimedAccess: false,
      canManageAgencies: false,
      canBanUsers: false,
      canManageStore: false,
      canConfigureAI: false,
      canManageBanners: false,
      canAdjustRTP: false,
      canManageModerators: false,
    ),
  };

  Future<void> loadAllAdmins() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _client
          .from('users')
          .select()
          .inFilter('role', [
            'owner',
            'regional_manager',
            'app_manager',
            'super_admin',
            'agency_admin',
            'banner_admin',
            'moderator',
          ]);

      _allAdmins = rows
          .map((row) => UserModel.fromSupabase(row))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading admins: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  RBACPermissions getPermissions(UserRole role) {
    return _rolePermissions[role] ?? _rolePermissions[UserRole.user]!;
  }

  bool hasPermission(UserRole role, RBACAction action) {
    final permissions = getPermissions(role);
    switch (action) {
      case RBACAction.modifyFinancials:
        return permissions.canModifyFinancials;
      case RBACAction.grantRoles:
        return permissions.canGrantRoles;
      case RBACAction.revokeRoles:
        return permissions.canRevokeRoles;
      case RBACAction.grantTimedAccess:
        return permissions.canGrantTimedAccess;
      case RBACAction.manageAgencies:
        return permissions.canManageAgencies;
      case RBACAction.banUsers:
        return permissions.canBanUsers;
      case RBACAction.manageStore:
        return permissions.canManageStore;
      case RBACAction.configureAI:
        return permissions.canConfigureAI;
      case RBACAction.manageBanners:
        return permissions.canManageBanners;
      case RBACAction.adjustRTP:
        return permissions.canAdjustRTP;
      case RBACAction.manageModerators:
        return permissions.canManageModerators;
    }
  }

  Future<bool> grantRole(String userId, UserRole newRole, UserRole currentAdminRole) async {
    if (!hasPermission(currentAdminRole, RBACAction.grantRoles)) {
      _errorMessage = 'Insufficient permissions to grant roles';
      notifyListeners();
      return false;
    }

    // Owner role cannot be granted by non-owners
    if (newRole == UserRole.owner && currentAdminRole != UserRole.owner) {
      _errorMessage = 'Only Owner can grant Owner role';
      notifyListeners();
      return false;
    }

    try {
      await _client.from('users').update({
        'role': newRole.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('auth_uid', userId);

      await loadAllAdmins();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to grant role: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> grantTimedAccess(
    String userId,
    UserRole role,
    Duration duration,
    UserRole currentAdminRole,
  ) async {
    if (!hasPermission(currentAdminRole, RBACAction.grantTimedAccess)) {
      _errorMessage = 'Insufficient permissions to grant timed access';
      notifyListeners();
      return false;
    }

    // Owner role cannot be granted as timed access
    if (role == UserRole.owner) {
      _errorMessage = 'Owner role cannot be granted as timed access';
      notifyListeners();
      return false;
    }

    try {
      final expiresAt = DateTime.now().add(duration);
      await _client.from('users').update({
        'role': role.name,
        'admin_access_expires_at': expiresAt.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('auth_uid', userId);

      await loadAllAdmins();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to grant timed access: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> revokeAccess(String userId, UserRole currentAdminRole) async {
    if (!hasPermission(currentAdminRole, RBACAction.revokeRoles)) {
      _errorMessage = 'Insufficient permissions to revoke access';
      notifyListeners();
      return false;
    }

    try {
      await _client.from('users').update({
        'role': UserRole.user.name,
        'admin_access_expires_at': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('auth_uid', userId);

      await loadAllAdmins();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to revoke access: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkTimedAccessExpiry() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final rows = await _client
          .from('users')
          .select()
          .lt('admin_access_expires_at', now)
          .inFilter('role', [
            'super_admin',
            'agency_admin',
            'banner_admin',
            'moderator',
          ]);

      for (var row in rows) {
        await _client.from('users').update({
          'role': UserRole.user.name,
          'admin_access_expires_at': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('auth_uid', row['auth_uid']);
      }

      return true;
    } catch (e) {
      debugPrint('Error checking timed access expiry: $e');
      return false;
    }
  }
}

class RBACPermissions {
  final bool canModifyFinancials;
  final bool canGrantRoles;
  final bool canRevokeRoles;
  final bool canGrantTimedAccess;
  final bool canManageAgencies;
  final bool canBanUsers;
  final bool canManageStore;
  final bool canConfigureAI;
  final bool canManageBanners;
  final bool canAdjustRTP;
  final bool canManageModerators;

  const RBACPermissions({
    required this.canModifyFinancials,
    required this.canGrantRoles,
    required this.canRevokeRoles,
    required this.canGrantTimedAccess,
    required this.canManageAgencies,
    required this.canBanUsers,
    required this.canManageStore,
    required this.canConfigureAI,
    required this.canManageBanners,
    required this.canAdjustRTP,
    required this.canManageModerators,
  });
}

enum RBACAction {
  modifyFinancials,
  grantRoles,
  revokeRoles,
  grantTimedAccess,
  manageAgencies,
  banUsers,
  manageStore,
  configureAI,
  manageBanners,
  adjustRTP,
  manageModerators,
}
