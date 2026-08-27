import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class AgencyIdGenerator {
  static const String _usedIdsKey = 'used_agency_ids';
  static final Random _random = Random();
  
  static Future<String> generateUniqueId() async {
    return await _generate4DigitId();
  }

  static Future<String> _generate4DigitId() async {
    String id;
    int attempts = 0;
    const maxAttempts = 100;

    final prefs = await SharedPreferences.getInstance();
    final usedIds = prefs.getStringList(_usedIdsKey) ?? [];

    do {
      id = (_random.nextInt(9000) + 1000).toString();
      attempts++;
      if (attempts >= maxAttempts) break;
    } while (usedIds.contains(id));

    if (attempts >= maxAttempts) {
      id = await _generateSequentialId();
    }

    await _markIdAsUsed(id);
    return id;
  }

  static Future<String> _generateSequentialId() async {
    final prefs = await SharedPreferences.getInstance();
    int lastId = prefs.getInt('last_sequential_id') ?? 999;
    lastId = (lastId + 1) % 10000;
    if (lastId < 1000) lastId = 1000;
    await prefs.setInt('last_sequential_id', lastId);
    return lastId.toString();
  }

  static Future<void> _markIdAsUsed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final usedIds = prefs.getStringList(_usedIdsKey) ?? [];
    if (!usedIds.contains(id)) {
      usedIds.add(id);
      await prefs.setStringList(_usedIdsKey, usedIds);
    }
  }

  static Future<void> clearUsedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usedIdsKey);
    await prefs.remove('last_sequential_id');
  }
}
