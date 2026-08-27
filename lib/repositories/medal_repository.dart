import '../models/medal_model.dart';

abstract class MedalRepository {
  Future<List<Medal>> getAllMedals();
  Future<List<String>> getOwnedMedalIds(String userId);
  Future<void> saveOwnedMedal(String userId, String medalId);
}
