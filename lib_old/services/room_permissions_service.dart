class RoomPermissionsService {
  // 1. Limits & Roles Structure
  static const int maxAdmins = 25;
  // Max Members/Guests: Unlimited (1000+)

  // 2. Logic Handlers

  /// canGrantAdmin(currentUserRole, currentAdminCount):
  /// Return true ONLY if currentUserRole == 'owner' AND currentAdminCount < 25.
  static bool canGrantAdmin(String currentUserRole, int currentAdminCount) {
    return currentUserRole == 'owner' && currentAdminCount < maxAdmins;
  }

  /// canGrantMembership(currentUserRole):
  /// Return true for 'owner' or 'admin'.
  static bool canGrantMembership(String currentUserRole) {
    return currentUserRole == 'owner' || currentUserRole == 'admin';
  }

  /// Immunity & Kick Rules:
  /// - Owner has complete immunity (cannot be kicked, muted, or unseated by anyone).
  /// - Admin can only manage/kick members/guests.
  static bool canManageUser(String currentUserRole, String targetUserRole) {
    // Owner has complete immunity
    if (targetUserRole == 'owner') return false;

    // Owner can manage everyone else
    if (currentUserRole == 'owner') return true;

    // Admin can only manage members/guests
    if (currentUserRole == 'admin') {
      return targetUserRole == 'member' || targetUserRole == 'guest';
    }

    // Members/Guests have no management permissions
    return false;
  }
}
