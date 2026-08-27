import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_controller.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });
}

class NotificationController extends ChangeNotifier {
  static final NotificationController _instance = NotificationController._internal();
  factory NotificationController() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  NotificationController._internal() {
    debugPrint('Initializing: NotificationController');
    _loadSettings();
    _listenToFirestore();
  }

  void _listenToFirestore() {
    final userId = UserController().id;
    if (userId.isEmpty) return;
    
    // Listen to user's notifications collection
    _firestore.collection('users').doc(userId).collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      _notifications.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _notifications.add(NotificationItem(
          id: doc.id,
          type: data['type'] ?? 'system',
          title: data['title'] ?? '',
          message: data['message'] ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] as bool? ?? false,
          data: data['data'] as Map<String, dynamic>?,
        ));
      }
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    });
  }

  bool _pushNotifications = true;
  bool _messageNotifications = true;
  bool _roomNotifications = true;
  bool _giftNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  final List<NotificationItem> _notifications = [];
  int _unreadCount = 0;

  bool get pushNotifications => _pushNotifications;
  bool get messageNotifications => _messageNotifications;
  bool get roomNotifications => _roomNotifications;
  bool get giftNotifications => _giftNotifications;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 5));
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _messageNotifications = prefs.getBool('message_notifications') ?? true;
      _roomNotifications = prefs.getBool('room_notifications') ?? true;
      _giftNotifications = prefs.getBool('gift_notifications') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      await prefs.setBool('push_notifications', _pushNotifications);
      await prefs.setBool('message_notifications', _messageNotifications);
      await prefs.setBool('room_notifications', _roomNotifications);
      await prefs.setBool('gift_notifications', _giftNotifications);
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('vibration_enabled', _vibrationEnabled);
      
      // Save to Firestore
      final userId = UserController().id;
      if (userId.isNotEmpty) {
        await _firestore.collection('users').doc(userId).collection('settings')
            .doc('notifications')
            .set({
          'pushNotifications': _pushNotifications,
          'messageNotifications': _messageNotifications,
          'roomNotifications': _roomNotifications,
          'giftNotifications': _giftNotifications,
          'soundEnabled': _soundEnabled,
          'vibrationEnabled': _vibrationEnabled,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = UserController().id;
      await _firestore.collection('users').doc(userId).collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final userId = UserController().id;
      final batch = _firestore.batch();
      for (var notification in _notifications.where((n) => !n.isRead)) {
        final ref = _firestore.collection('users').doc(userId).collection('notifications').doc(notification.id);
        batch.update(ref, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> addNotification({
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userId = UserController().id;
      await _firestore.collection('users').doc(userId).collection('notifications')
          .add({
        'type': type,
        'title': title,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'data': data,
      });
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  void setPushNotifications(bool value) {
    _pushNotifications = value;
    _saveSettings();
    notifyListeners();
  }

  void setMessageNotifications(bool value) {
    _messageNotifications = value;
    _saveSettings();
    notifyListeners();
  }

  void setRoomNotifications(bool value) {
    _roomNotifications = value;
    _saveSettings();
    notifyListeners();
  }

  void setGiftNotifications(bool value) {
    _giftNotifications = value;
    _saveSettings();
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  void setVibrationEnabled(bool value) {
    _vibrationEnabled = value;
    _saveSettings();
    notifyListeners();
  }
}
