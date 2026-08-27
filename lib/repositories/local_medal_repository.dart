import '../models/medal_model.dart';
import 'medal_repository.dart';

class LocalMedalRepository implements MedalRepository {
  final List<Medal> _allMedals = [
    Medal(
      id: 'vip_1',
      nameKey: 'vip_bronze',
      iconPath: 'assets/Asad/medal_vip_1.png',
      type: MedalType.vip,
      descriptionKey: 'vip_bronze_desc',
    ),
    Medal(
      id: 'vip_10',
      nameKey: 'vip_gold',
      iconPath: 'assets/Asad/medal_vip_10.png',
      type: MedalType.vip,
      descriptionKey: 'vip_gold_desc',
    ),
    Medal(
      id: 'medal_100m',
      nameKey: 'diamond_charger',
      iconPath: 'assets/Asad/medal_spender.png',
      type: MedalType.milestone,
      descriptionKey: 'diamond_charger_desc',
    ),
    Medal(
      id: 'medal_110m',
      nameKey: 'legendary_charger',
      iconPath: 'assets/Asad/medal_charity.png',
      type: MedalType.milestone,
      descriptionKey: 'legendary_charger_desc',
    ),
    Medal(
      id: 'ramadan_2024',
      nameKey: 'ramadan_2024',
      iconPath: 'assets/Asad/medal_event_1.png',
      type: MedalType.event,
      descriptionKey: 'ramadan_2024_desc',
    ),
  ];

  final Map<String, Set<String>> _userMedals = {};

  @override
  Future<List<Medal>> getAllMedals() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _allMedals;
  }

  @override
  Future<List<String>> getOwnedMedalIds(String userId) async {
    return _userMedals[userId]?.toList() ?? ['vip_1'];
  }

  @override
  Future<void> saveOwnedMedal(String userId, String medalId) async {
    _userMedals.putIfAbsent(userId, () => {}).add(medalId);
  }
}
