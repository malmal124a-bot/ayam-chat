import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'user_controller.dart';

class DmMessage {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromName;
  final String toName;
  final String text;
  final bool isRead;
  final DateTime? createdAt;

  DmMessage({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromName,
    required this.toName,
    required this.text,
    this.isRead = false,
    this.createdAt,
  });

  factory DmMessage.fromRow(Map<String, dynamic> row) {
    return DmMessage(
      id: row['id'].toString(),
      fromUserId: (row['from_user_id'] ?? '').toString(),
      toUserId: (row['to_user_id'] ?? '').toString(),
      fromName: (row['from_name'] ?? '').toString(),
      toName: (row['to_name'] ?? '').toString(),
      text: (row['text'] ?? '').toString(),
      isRead: row['is_read'] == true,
      createdAt: SupabaseService.parseDate(row['created_at']),
    );
  }
}

class ConversationInfo {
  final String otherUserId;
  final String otherName;
  final String lastText;
  final DateTime? lastTime;
  final int unreadCount;

  ConversationInfo({
    required this.otherUserId,
    required this.otherName,
    required this.lastText,
    this.lastTime,
    this.unreadCount = 0,
  });
}

class DmController extends ChangeNotifier {
  static final DmController _instance = DmController._internal();
  factory DmController() => _instance;

  final SupabaseClient _client = SupabaseService.client;
  final List<StreamSubscription<List<Map<String, dynamic>>>> _dmSubscriptions = [];

  List<DmMessage> _all = [];
  List<DmMessage> get all => List.unmodifiable(_all);

  bool _isDisposed = false;
  bool _inited = false;

  DmController._internal() {
    debugPrint('Initializing: DmController');
  }

  void init() {
    if (_inited) return;
    _inited = true;
    _listenToDm();
  }

  void _listenToDm() {
    final me = SupabaseService.currentUserId;
    final myNumericId = UserController().numericId;
    if (me == null) return;

    for (final sub in _dmSubscriptions) {
      sub.cancel();
    }
    _dmSubscriptions.clear();

    final map = <String, DmMessage>{};

    void onRows(List<Map<String, dynamic>> rows) {
      for (final r in rows) {
        map[r['id'].toString()] = DmMessage.fromRow(r);
      }
      final list = map.values.toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      _all = list;
      safeNotify();
    }

    _dmSubscriptions.add(
      _client
          .from('dm_messages')
          .stream(primaryKey: ['id'])
          .eq('from_user_id', me)
          .order('created_at', ascending: false)
          .limit(300)
          .listen(onRows),
    );
    _dmSubscriptions.add(
      _client
          .from('dm_messages')
          .stream(primaryKey: ['id'])
          .eq('to_user_id', me)
          .order('created_at', ascending: false)
          .limit(300)
          .listen(onRows),
    );

    if (myNumericId.isNotEmpty && myNumericId != me) {
      _dmSubscriptions.add(
        _client
            .from('dm_messages')
            .stream(primaryKey: ['id'])
            .eq('from_user_id', myNumericId)
            .order('created_at', ascending: false)
            .limit(300)
            .listen(onRows),
      );
      _dmSubscriptions.add(
        _client
            .from('dm_messages')
            .stream(primaryKey: ['id'])
            .eq('to_user_id', myNumericId)
            .order('created_at', ascending: false)
            .limit(300)
            .listen(onRows),
      );
    }
  }

  String get _myId => UserController().numericId;

  List<ConversationInfo> get conversations {
    final map = <String, ConversationInfo>{};
    for (final m in _all) {
      final isMine = m.fromUserId == _myId;
      final otherId = isMine ? m.toUserId : m.fromUserId;
      final otherName = isMine ? m.toName : m.fromName;
      if (otherId.isEmpty || otherId == _myId) continue;

      final existing = map[otherId];
      final isUnread = !isMine && !m.isRead;
      if (existing == null) {
        map[otherId] = ConversationInfo(
          otherUserId: otherId,
          otherName: otherName,
          lastText: m.text,
          lastTime: m.createdAt,
          unreadCount: isUnread ? 1 : 0,
        );
      } else {
        map[otherId] = ConversationInfo(
          otherUserId: existing.otherUserId,
          otherName: existing.otherName,
          lastText: m.text,
          lastTime: existing.lastTime,
          unreadCount: existing.unreadCount + (isUnread ? 1 : 0),
        );
      }
    }
    final list = map.values.toList();
    list.sort((a, b) {
      final ta = a.lastTime;
      final tb = b.lastTime;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    return list;
  }

  List<DmMessage> messagesWith(String otherUserId) {
    final list = _all
        .where((m) =>
            (m.fromUserId == otherUserId && m.toUserId == _myId) ||
            (m.toUserId == otherUserId && m.fromUserId == _myId))
        .toList()
        .reversed
        .toList();
    return list;
  }

  Future<void> sendMessage(String toUserId, String toName, String text) async {
    if (text.trim().isEmpty) return;
    final user = UserController();
    await _client.from('dm_messages').insert({
      'from_user_id': _myId,
      'to_user_id': toUserId,
      'from_name': user.name,
      'to_name': toName,
      'text': text.trim(),
      'is_read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    safeNotify();
  }

  Future<void> markRead(String otherUserId) async {
    await _client
        .from('dm_messages')
        .update({'is_read': true})
        .eq('to_user_id', _myId)
        .eq('from_user_id', otherUserId)
        .eq('is_read', false);
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final sub in _dmSubscriptions) {
      sub.cancel();
    }
    _dmSubscriptions.clear();
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
}
