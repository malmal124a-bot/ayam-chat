import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BroadcastMessage {
  final String id;
  final String message;
  final DateTime createdAt;
  final String type; // 'relationship', 'level_up', 'vip_upgrade', 'gift', 'custom'

  BroadcastMessage({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
    };
  }

  factory BroadcastMessage.fromJson(Map<String, dynamic> json) {
    return BroadcastMessage(
      id: json['id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      type: json['type'] as String? ?? 'custom',
    );
  }
}

class BroadcastController extends ChangeNotifier {
  List<BroadcastMessage> _broadcasts = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentIndex = 0;

  List<BroadcastMessage> get broadcasts => _broadcasts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentIndex => _currentIndex;
  BroadcastMessage? get currentBroadcast => _broadcasts.isNotEmpty ? _broadcasts[_currentIndex] : null;

  BroadcastController() {
    _loadData();
    _startAutoScroll();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load broadcasts
      final broadcastsJson = prefs.getStringList('broadcasts') ?? [];
      _broadcasts = broadcastsJson.map((json) {
        final parts = json.split('|');
        return BroadcastMessage(
          id: parts[0],
          message: parts[1],
          createdAt: DateTime.parse(parts[2]),
          type: parts.length > 3 ? parts[3] : 'custom',
        );
      }).toList();
      
      // Add some default broadcasts if empty
      if (_broadcasts.isEmpty) {
        _addDefaultBroadcasts();
      }
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _addDefaultBroadcasts() {
    final now = DateTime.now();
    _broadcasts = [
      BroadcastMessage(
        id: '1',
        message: '🎉 مرحباً بك في تطبيق الدردشة!',
        createdAt: now,
        type: 'custom',
      ),
      BroadcastMessage(
        id: '2',
        message: '💎 اشحن الآن واحصل على مكافآت خاصة',
        createdAt: now,
        type: 'custom',
      ),
      BroadcastMessage(
        id: '3',
        message: '⭐ ارتبط بأصدقائك واكسب مستويات جديدة',
        createdAt: now,
        type: 'custom',
      ),
    ];
  }

  Future<void> addBroadcast({
    required String message,
    required String type,
  }) async {
    try {
      final broadcast = BroadcastMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: message,
        createdAt: DateTime.now(),
        type: type,
      );
      
      _broadcasts.insert(0, broadcast);
      
      // Keep only last 50 broadcasts
      if (_broadcasts.length > 50) {
        _broadcasts = _broadcasts.sublist(0, 50);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final broadcastsJson = _broadcasts.map((b) => 
        '${b.id}|${b.message}|${b.createdAt.toIso8601String()}|${b.type}'
      ).toList();
      await prefs.setStringList('broadcasts', broadcastsJson);
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> addRelationshipBroadcast(String userName1, String userName2) async {
    final message = '💕 $userName1 ارتبط بـ $userName2';
    await addBroadcast(message: message, type: 'relationship');
  }

  Future<void> addLevelUpBroadcast(String userName, int newLevel) async {
    final message = '🎊 $userName وصل للمستوى $newLevel';
    await addBroadcast(message: message, type: 'level_up');
  }

  Future<void> addVipUpgradeBroadcast(String userName, int newVipLevel) async {
    final message = '👑 $userName أصبح VIP $newVipLevel';
    await addBroadcast(message: message, type: 'vip_upgrade');
  }

  Future<void> addGiftBroadcast(String fromUser, String toUser, int amount) async {
    final message = '🎁 $fromUser أرسل هدية بقيمة $amount 💎 إلى $toUser';
    await addBroadcast(message: message, type: 'gift');
  }

  void _startAutoScroll() {
    // Auto-scroll every 5 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (_broadcasts.isNotEmpty) {
        _currentIndex = (_currentIndex + 1) % _broadcasts.length;
        notifyListeners();
      }
      return true;
    });
  }

  void nextBroadcast() {
    if (_broadcasts.isNotEmpty) {
      _currentIndex = (_currentIndex + 1) % _broadcasts.length;
      notifyListeners();
    }
  }

  void previousBroadcast() {
    if (_broadcasts.isNotEmpty) {
      _currentIndex = (_currentIndex - 1 + _broadcasts.length) % _broadcasts.length;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
