import 'package:flutter/material.dart';
import 'user_controller.dart';
import 'wallet_controller.dart';

class SvipController extends ChangeNotifier {
  static final SvipController _instance = SvipController._internal();
  factory SvipController() => _instance;

  SvipController._internal() {
    debugPrint('Initializing: SvipController');
  }

  UserController get _userController => UserController();
  WalletController get _walletController => WalletController();

  final List<Map<String, dynamic>> levels = [
    {
      'level': 1,
      'name': 'SVIP BRONZE',
      'cost': 10000,
      'color': const Color(0xFFCD7F32),
      'perks': ['تميز في قائمة الغرفة', 'دخولية برونزية', 'إطار برونزي'],
    },
    {
      'level': 2,
      'name': 'SVIP SILVER',
      'cost': 50000,
      'color': const Color(0xFFC0C0C0),
      'perks': ['جميع مزايا برونز', 'دخولية فضية', 'إطار فضي', 'تخطي حظر المايك'],
    },
    {
      'level': 3,
      'name': 'SVIP GOLD',
      'cost': 100000,
      'color': const Color(0xFFFFD700),
      'perks': ['جميع مزايا سيلفر', 'دخولية ذهبية', 'إطار ذهبي', 'إخفاء الموقع'],
    },
    {
      'level': 4,
      'name': 'SVIP PLATINUM',
      'cost': 250000,
      'color': const Color(0xFFE5E4E2),
      'perks': ['جميع مزايا جولد', 'دخولية بلاتينيوم', 'إطار بلاتينيوم', 'رقم مميز 6 أرقام'],
    },
    {
      'level': 5,
      'name': 'SVIP ROYAL',
      'cost': 500000,
      'color': const Color(0xFF800080),
      'perks': ['جميع مزايا بلاتينيوم', 'دخولية ملكية', 'إطار ملكي', 'رقم مميز 5 أرقام', 'دخول غرف مقفلة'],
    },
  ];

  int _svipLevel = 0;
  int get svipLevel => _svipLevel;

  bool isUnlocked(int level) => _svipLevel >= level;

  Color getSvipColor([int? level]) {
    final targetLevel = level ?? _svipLevel;
    if (targetLevel <= 0) return const Color(0xFF2D2D5F);
    
    final levelData = levels.firstWhere(
      (l) => l['level'] == targetLevel,
      orElse: () => levels.first,
    );
    return levelData['color'] as Color;
  }

  int getSvipCost(int level) {
    if (level <= 0 || level > levels.length) return 0;
    
    final levelData = levels.firstWhere(
      (l) => l['level'] == level,
      orElse: () => levels.first,
    );
    return levelData['cost'] as int;
  }

  Widget buildSvipBadge([int? level]) {
    final targetLevel = level ?? _svipLevel;
    if (targetLevel <= 0) return const SizedBox.shrink();
    
    final levelData = levels.firstWhere(
      (l) => l['level'] == targetLevel,
      orElse: () => levels.first,
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            levelData['color'] as Color,
            (levelData['color'] as Color).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        levelData['name'] as String,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  String buySvip(int level) {
    if (level <= _svipLevel) return 'أنت تمتلك هذه الرتبة بالفعل أو رتبة أعلى.';
    
    final cost = levels.firstWhere((l) => l['level'] == level)['cost'] as int;
    final wallet = _walletController;

    if (wallet.diamonds.value < cost) {
      return 'رصيدك غير كافٍ. تحتاج إلى $cost ماسة.';
    }

    if (!wallet.spendDiamonds(cost)) {
      return 'فشل في خصم الماسات.';
    }

    _svipLevel = level;
    _userController.addGlobalScore(cost);
    notifyListeners();
    return 'تم تفعيل ${levels[level - 1]['name']} بنجاح!';
  }
}
