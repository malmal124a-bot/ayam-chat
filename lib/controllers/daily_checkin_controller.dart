import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wallet_controller.dart';
import '../services/supabase_service.dart';

class DailyCheckinController extends GetxController {
  final _client = SupabaseService.client;

  RxList<bool> claims = List.generate(7, (_) => false).obs;
  RxInt streak = 0.obs;
  RxBool canClaimToday = false.obs;
  RxBool isLoading = false.obs;

  /// True once the user has ever claimed the check-in reward.
  /// The daily check-in screen auto-shows only until this becomes true.
  RxBool hasClaimedOnce = false.obs;

  String get _claimedKey =>
      'daily_checkin_claimed_once_${SupabaseService.currentUserId ?? 'anon'}';

  @override
  void onInit() {
    super.onInit();
    _loadLocalClaimedFlag();
    _loadCheckinData();
  }

  Future<void> _loadLocalClaimedFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      hasClaimedOnce.value = prefs.getBool(_claimedKey) ?? false;
    } catch (e) {
      print('Error loading claimed flag: $e');
    }
  }

  Future<void> _saveClaimedFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_claimedKey, hasClaimedOnce.value);
    } catch (e) {
      print('Error saving claimed flag: $e');
    }
  }

  Future<void> _loadCheckinData() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;

    isLoading.value = true;
    try {
      final row = await _client
          .from('daily_claims')
          .select()
          .eq('auth_uid', uid)
          .maybeSingle();

      if (row != null) {
        streak.value = (row['streak'] ?? 0) as int;

        final DateTime? lastClaim = SupabaseService.parseDate(row['last_claim']);
        if (lastClaim != null) {
          final lastDate = lastClaim.toLocal();
          final now = DateTime.now();
          final isSameDay = lastDate.year == now.year && lastDate.month == now.month && lastDate.day == now.day;
          canClaimToday.value = !isSameDay;

          final difference = DateTime(now.year, now.month, now.day).difference(DateTime(lastDate.year, lastDate.month, lastDate.day)).inDays;
          if (difference > 1) {
            streak.value = 0;
            await _client.from('daily_claims').update({'streak': 0}).eq('auth_uid', uid);
          }
        } else {
          canClaimToday.value = true;
        }

        final List<dynamic> claimHistory = row['weekly_claims'] ?? List.generate(7, (_) => false);
        claims.assignAll(claimHistory.cast<bool>());

        final bool anyClaimed = claims.any((c) => c) || ((row['streak'] ?? 0) as int) > 0;
        if (anyClaimed && !hasClaimedOnce.value) {
          hasClaimedOnce.value = true;
          await _saveClaimedFlag();
        }
      } else {
        canClaimToday.value = true;
        streak.value = 0;
      }
    } catch (e) {
      print('Error loading checkin data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> claimReward() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null || !canClaimToday.value) return false;

    isLoading.value = true;
    try {
      final nextDayIndex = streak.value % 7;
      final rewardAmount = (nextDayIndex + 1) * 100; // Example reward

      List<bool> newClaims = List.from(claims);
      newClaims[nextDayIndex] = true;

      await _client.from('daily_claims').upsert({
        'auth_uid': uid,
        'streak': streak.value + 1,
        'last_claim': DateTime.now().toUtc().toIso8601String(),
        'weekly_claims': newClaims,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'auth_uid');

      // Real-time coin reward increment to WalletController
      WalletController().addCoins(rewardAmount);
      
      streak.value++;
      claims[nextDayIndex] = true;
      canClaimToday.value = false;
      hasClaimedOnce.value = true;
      await _saveClaimedFlag();
      
      return true;
    } catch (e) {
      print('Error claiming reward: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
