import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

extension RxNumFix on RxNum {
  bool get isNegative => value.isNegative;
}

extension RxDoubleFix on RxDouble {
  bool get isNegative => value < 0;
}

extension RxIntFix on RxInt {
  bool get isNegative => value < 0;
}

class WalletController extends ChangeNotifier {
  RxNum balance = RxNum(0);
  RxNum diamonds = RxNum(0);
  RxNum coins = RxNum(0);
  RxNum agencyBalance = RxNum(0);
  RxList<dynamic> transactions = <dynamic>[].obs;

  WalletController() {
    _listenToWallet();
  }

  void _listenToWallet() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          balance.value = data['balance'] ?? 0;
          diamonds.value = data['diamonds'] ?? data['gems'] ?? 0;
          coins.value = data['coins'] ?? 0;
          agencyBalance.value = data['agencyBalance'] ?? 0;
          notifyListeners();
        }
      });
    }
  }

  // FIX FOR RED SCREEN: Direct getter for isNegative
  bool get isNegative => balance.value < 0;

  // Additional getters for compatibility
  num get userBalance => balance.value;
  num get userGems => diamonds.value;
  num get userCoins => coins.value;

  void addDiamonds(dynamic amount) {
    final num val = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    diamonds.value += val;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'gems': FieldValue.increment(val),
        'diamonds': FieldValue.increment(val),
      }).catchError((_) {});
    }
    notifyListeners();
  }

  void addGems(dynamic amount) {
    addDiamonds(amount);
  }

  bool spendBalance(dynamic amount) {
    final num val = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    if (balance.value >= val) {
      balance.value -= val;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        FirebaseFirestore.instance.collection('users').doc(uid).update({
          'balance': FieldValue.increment(-val),
        }).catchError((_) {});
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  bool spendDiamonds(dynamic amount) {
    final num val = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    if (diamonds.value >= val) {
      diamonds.value -= val;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        FirebaseFirestore.instance.collection('users').doc(uid).update({
          'gems': FieldValue.increment(-val),
          'diamonds': FieldValue.increment(-val),
        }).catchError((_) {});
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  bool spendGems(dynamic amount) {
    return spendDiamonds(amount);
  }

  Future<bool> deductDiamonds(dynamic amount) async {
    return spendDiamonds(amount);
  }

  void addCoins(dynamic amount) {
    final num val = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    coins.value += val;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'coins': FieldValue.increment(val),
      }).catchError((_) {});
    }
    notifyListeners();
  }

  void addBalance(dynamic amount, {String? description, String? method}) {
    final num val = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    balance.value += val;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'balance': FieldValue.increment(val),
      }).catchError((_) {});
    }
    notifyListeners();
  }

  void addAgencyBalance(dynamic amount) {
    final num val = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    agencyBalance.value += val;
    notifyListeners();
  }

  Future<void> addDiamondsToUser(String userId, dynamic amount, [dynamic costUsd]) async {
    final num val = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'gems': FieldValue.increment(val),
        'diamonds': FieldValue.increment(val),
      });
    } catch (_) {}
  }

  void addTransaction(dynamic data) {
    transactions.add(data);
    notifyListeners();
  }

  bool buyItem(dynamic item) {
    return true;
  }

  double getTotalRecharged() => balance.value.toDouble();
}
