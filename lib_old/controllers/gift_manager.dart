import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'gift_controller.dart';
import '../widgets/alpha_gift_player.dart';

class ActiveGiftInfo {
  final GiftItem item;
  final String senderName;
  final String? recipientName;
  final String uniqueId;
  int comboCount;

  ActiveGiftInfo({
    required this.item,
    required this.senderName,
    this.recipientName,
    required this.uniqueId,
    this.comboCount = 1,
  });
}

class LuckyGiftWinInfo {
  final String userName;
  final String giftName;
  final String multiplier;
  final String roomId;
  final String uniqueId;

  LuckyGiftWinInfo({
    required this.userName,
    required this.giftName,
    required this.multiplier,
    required this.roomId,
    required this.uniqueId,
  });
}

class GiftManager extends ChangeNotifier {
  static final GiftManager _instance = GiftManager._internal();
  
  factory GiftManager({List? gifList, dynamic item, VoidCallback? onFinished}) {
    return _instance;
  }

  GiftManager._internal() {
    debugPrint('Initializing: GiftManager');
  }

  final List<ActiveGiftInfo> activeGifts = [];
  final List<LuckyGiftWinInfo> luckyGiftWins = [];
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void safeNotify() {
    if (_isDisposed) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  /// Handles lucky_gift_win or global_broadcast socket events.
  void broadcastLuckyGiftWin({
    required String userName,
    required String giftName,
    required String multiplier,
    required String roomId,
  }) {
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
    final winInfo = LuckyGiftWinInfo(
      userName: userName,
      giftName: giftName,
      multiplier: multiplier,
      roomId: roomId,
      uniqueId: uniqueId,
    );
    
    luckyGiftWins.add(winInfo);
    safeNotify();

    // Auto-remove after 4 seconds
    Timer(const Duration(seconds: 4), () {
      removeLuckyGiftWin(uniqueId);
    });
  }

  void removeLuckyGiftWin(String uniqueId) {
    luckyGiftWins.removeWhere((w) => w.uniqueId == uniqueId);
    safeNotify();
  }

  OverlayEntry createGiftOverlay(String svgaPath, VoidCallback onComplete) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => AlphaGiftPlayer(
        svgaPath: svgaPath,
        onFinished: () {
          if (entry.mounted) {
            entry.remove();
          }
          onComplete();
        },
      ),
    );
    return entry;
  }

  /// Displays a gift animation using an isolated OverlayEntry.
  /// This prevents room UI freezes and ensures buttons remain clickable.
  void triggerAnimation(BuildContext context, GiftItem item, {String? senderName, String? recipientName, int comboCount = 1}) {
    if (!item.animated || item.svgaPath == null) return;

    // Use the root overlay to ensure it's above everything and non-blocking
    final overlayState = Overlay.of(context, rootOverlay: true);
    
    final entry = createGiftOverlay(item.svgaPath!, () {
      // Animation complete
    });

    overlayState.insert(entry);
  }

  void playGiftAnimation(String giftMessage, BuildContext context) {
    final controller = GiftController();
    for (var gift in controller.gifts) {
      if (giftMessage.contains(gift.name) && gift.animated) {
        triggerAnimation(context, gift);
        break;
      }
    }
  }

  void clearAnimation() {
    // Animations in OverlayEntry will finish and remove themselves.
    activeGifts.clear();
    safeNotify();
  }
}
