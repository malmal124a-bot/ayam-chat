import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayam_chat/controllers/user_controller.dart';
import 'package:ayam_chat/controllers/wallet_controller.dart';
import 'package:ayam_chat/services/supabase_service.dart';

class FamilyMember {
  final String id;
  final String userUid;
  final String numericId;
  final String name;
  final String role;
  final String avatar;
  final int contribution;

  FamilyMember({
    required this.id,
    required this.userUid,
    required this.numericId,
    required this.name,
    this.role = 'member',
    this.avatar = '',
    this.contribution = 0,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> m) => FamilyMember(
    id: m['id'] ?? '',
    userUid: m['user_uid'] ?? '',
    numericId: m['user_numeric_id'] ?? '',
    name: m['user_name'] ?? '',
    role: m['role'] ?? 'member',
    avatar: m['user_avatar'] ?? '',
    contribution: m['contribution'] ?? 0,
  );
}

class FamilyInvite {
  final String id;
  final String familyId;
  final String familyName;
  final String senderUid;
  final String senderName;
  final String targetUid;
  final String targetName;
  final String status;

  FamilyInvite({
    required this.id,
    required this.familyId,
    required this.familyName,
    required this.senderUid,
    required this.senderName,
    required this.targetUid,
    required this.targetName,
    required this.status,
  });

  factory FamilyInvite.fromMap(Map<String, dynamic> m) => FamilyInvite(
    id: m['id'] ?? '',
    familyId: m['family_id'] ?? '',
    familyName: m['family_name'] ?? '',
    senderUid: m['sender_uid'] ?? '',
    senderName: m['sender_name'] ?? '',
    targetUid: m['target_uid'] ?? '',
    targetName: m['target_name'] ?? '',
    status: m['status'] ?? 'pending',
  );
}

class FamilyController extends ChangeNotifier {
  static final FamilyController _instance = FamilyController._internal();
  factory FamilyController() => _instance;

  final SupabaseClient _client = SupabaseService.client;
  StreamSubscription? _membersSub;
  StreamSubscription? _invitesSub;

  FamilyController._internal() {
    debugPrint('Initializing: FamilyController');
  }

  String? _familyId;
  String? _familyCode;
  String? _familyName;
  String? _description;
  String? _rules;
  String? _imageUrl;
  String? _role;
  bool _isInFamily = false;
  int _familyLevel = 1;
  int _familyDiamonds = 0;
  String _ownerUid = '';
  String _ownerName = '';
  int _memberCount = 0;

  List<FamilyMember> _members = [];
  List<FamilyInvite> _pendingInvites = [];
  List<FamilyInvite> _myInvites = [];

  String? get familyId => _familyId;
  String? get familyCode => _familyCode;
  String? get familyName => _familyName;
  String? get description => _description;
  String? get rules => _rules;
  String? get imageUrl => _imageUrl;
  String? get role => _role;
  bool get isInFamily => _isInFamily;
  int get familyLevel => _familyLevel;
  int get familyDiamonds => _familyDiamonds;
  String get ownerUid => _ownerUid;
  String get ownerName => _ownerName;
  int get memberCount => _memberCount;
  List<FamilyMember> get members => _members;
  List<FamilyInvite> get pendingInvites => _pendingInvites;
  List<FamilyInvite> get myInvites => _myInvites;
  bool get isOwner => _role == 'owner';
  bool get isAdmin => _role == 'owner' || _role == 'admin';

  static const int createCost = 5000;
  static const int minLevelToCreate = 5;

  Future<void> loadMyFamily() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;

    try {
      final memberRow = await _client
          .from('family_members')
          .select('family_id, role')
          .eq('user_uid', uid)
          .maybeSingle();

      if (memberRow == null) {
        _isInFamily = false;
        _familyId = null;
        safeNotify();
        return;
      }

      _familyId = memberRow['family_id'];
      _role = memberRow['role'];

      final familyRow = await _client
          .from('families')
          .select()
          .eq('id', _familyId!)
          .maybeSingle();

      if (familyRow != null) {
        _familyCode = familyRow['family_code'];
        _familyName = familyRow['name'];
        _description = familyRow['description'];
        _rules = familyRow['rules'];
        _imageUrl = familyRow['image_url'];
        _familyDiamonds = familyRow['diamonds'] ?? 0;
        _familyLevel = familyRow['level'] ?? 1;
        _ownerUid = familyRow['owner_uid'];
        _ownerName = familyRow['owner_name'];
        _memberCount = familyRow['member_count'] ?? 0;
        _isInFamily = true;
      } else {
        _isInFamily = false;
      }

      _listenToMembers();
      _listenToInvites();
      safeNotify();
    } catch (e) {
      debugPrint('FamilyController: Error loading family: $e');
    }
  }

  void _listenToMembers() {
    _membersSub?.cancel();
    if (_familyId == null) return;
    _membersSub = _client
        .from('family_members')
        .stream(primaryKey: ['id'])
        .eq('family_id', _familyId!)
        .order('role')
        .listen((rows) {
      _members = rows.map((r) => FamilyMember.fromMap(r)).toList();
      _memberCount = _members.length;
      safeNotify();
    });
  }

  void _listenToInvites() {
    _invitesSub?.cancel();
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;

    _invitesSub = _client
        .from('family_invites')
        .stream(primaryKey: ['id'])
        .eq('target_uid', uid)
        .eq('status', 'pending')
        .listen((rows) {
      _myInvites = rows.map((r) => FamilyInvite.fromMap(r)).toList();
      safeNotify();
    });

    if (_familyId != null && isOwner) {
      _client
          .from('family_invites')
          .stream(primaryKey: ['id'])
          .eq('family_id', _familyId!)
          .eq('status', 'pending')
          .listen((rows) {
        _pendingInvites = rows.map((r) => FamilyInvite.fromMap(r)).toList();
        safeNotify();
      });
    }
  }

  void safeNotify() {
    notifyListeners();
  }

  String _generateFamilyCode() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'FAM${now.toRadixString(36).toUpperCase()}';
  }

  Future<bool> createFamily(String name, {String? imageUrl}) async {
    final uid = SupabaseService.currentUserId;
    final uc = UserController();
    if (uid == null) return false;

    if (uc.currentLevel < minLevelToCreate) {
      return false;
    }

    final wallet = WalletController();
    if (wallet.diamonds < createCost) {
      return false;
    }

    final existing = await _client
        .from('family_members')
        .select('family_id')
        .eq('user_uid', uid)
        .maybeSingle();
    if (existing != null) return false;

    try {
      wallet.spendDiamonds(createCost);

      final code = _generateFamilyCode();
      final familyRow = {
        'family_code': code,
        'name': name,
        'description': '',
        'rules': '',
        'image_url': imageUrl ?? '',
        'owner_uid': uid,
        'owner_name': uc.name,
        'diamonds': 0,
        'level': 1,
        'member_count': 1,
        'create_cost': createCost,
        'min_level_to_create': minLevelToCreate,
      };

      final result = await _client.from('families').insert(familyRow).select('id').single();
      final familyId = result['id'];

      await _client.from('family_members').insert({
        'family_id': familyId,
        'user_uid': uid,
        'user_numeric_id': uc.numericId,
        'user_name': uc.name,
        'user_avatar': uc.profilePic,
        'role': 'owner',
        'contribution': 0,
      });

      _familyId = familyId;
      _familyCode = code;
      _familyName = name;
      _description = '';
      _rules = '';
      _imageUrl = imageUrl;
      _role = 'owner';
      _isInFamily = true;
      _familyLevel = 1;
      _familyDiamonds = 0;
      _ownerUid = uid;
      _ownerName = uc.name;
      _memberCount = 1;

      _listenToMembers();
      _listenToInvites();
      safeNotify();
      return true;
    } catch (e) {
      debugPrint('FamilyController: Error creating family: $e');
      return false;
    }
  }

  Future<void> updateFamilyDetails({String? name, String? description, String? rules, String? imageUrl}) async {
    if (_familyId == null) return;
    final updates = <String, dynamic>{};
    if (name != null) {
      _familyName = name;
      updates['name'] = name;
    }
    if (description != null) {
      _description = description;
      updates['description'] = description;
    }
    if (rules != null) {
      _rules = rules;
      updates['rules'] = rules;
    }
    if (imageUrl != null) {
      _imageUrl = imageUrl;
      updates['image_url'] = imageUrl;
    }
    if (updates.isNotEmpty) {
      await _client.from('families').update(updates).eq('id', _familyId!);
    }
    safeNotify();
  }

  Future<bool> inviteUser(String targetUid, String targetName) async {
    if (_familyId == null || !isAdmin) return false;

    final existing = await _client
        .from('family_members')
        .select('id')
        .eq('family_id', _familyId!)
        .eq('user_uid', targetUid)
        .maybeSingle();
    if (existing != null) return false;

    final existingInvite = await _client
        .from('family_invites')
        .select('id')
        .eq('family_id', _familyId!)
        .eq('target_uid', targetUid)
        .eq('status', 'pending')
        .maybeSingle();
    if (existingInvite != null) return false;

    final uc = UserController();
    await _client.from('family_invites').insert({
      'family_id': _familyId!,
      'family_name': _familyName ?? '',
      'sender_uid': SupabaseService.currentUserId,
      'sender_name': uc.name,
      'target_uid': targetUid,
      'target_name': targetName,
      'status': 'pending',
    });
    return true;
  }

  Future<void> acceptInvite(String inviteId) async {
    final invite = await _client
        .from('family_invites')
        .select()
        .eq('id', inviteId)
        .maybeSingle();
    if (invite == null) return;

    final uid = SupabaseService.currentUserId;
    final uc = UserController();

    await _client.from('family_members').insert({
      'family_id': invite['family_id'],
      'user_uid': uid,
      'user_numeric_id': uc.numericId,
      'user_name': uc.name,
      'user_avatar': uc.profilePic,
      'role': 'member',
      'contribution': 0,
    });

    await _client.from('family_invites').update({'status': 'accepted'}).eq('id', inviteId);

    final memberCount = await _client
        .from('family_members')
        .select('id')
        .eq('family_id', invite['family_id'])
        .count();
    await _client.from('families').update({
      'member_count': memberCount.count,
    }).eq('id', invite['family_id']);

    await loadMyFamily();
  }

  Future<void> rejectInvite(String inviteId) async {
    await _client.from('family_invites').update({'status': 'rejected'}).eq('id', inviteId);
  }

  Future<void> removeMember(String memberUid) async {
    if (_familyId == null || !isAdmin) return;
    if (memberUid == _ownerUid) return;

    await _client
        .from('family_members')
        .delete()
        .eq('family_id', _familyId!)
        .eq('user_uid', memberUid);

    final memberCount = await _client
        .from('family_members')
        .select('id')
        .eq('family_id', _familyId!)
        .count();
    await _client.from('families').update({
      'member_count': memberCount.count,
    }).eq('id', _familyId!);
  }

  Future<void> leaveFamily() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null || _familyId == null || isOwner) return;

    await _client
        .from('family_members')
        .delete()
        .eq('family_id', _familyId!)
        .eq('user_uid', uid);

    _familyId = null;
    _isInFamily = false;
    _role = null;
    _members = [];
    _pendingInvites = [];
    _membersSub?.cancel();
    _invitesSub?.cancel();
    safeNotify();
  }

  Future<void> dissolveFamily() async {
    if (_familyId == null || !isOwner) return;

    await _client.from('family_invites').delete().eq('family_id', _familyId!);
    await _client.from('family_members').delete().eq('family_id', _familyId!);
    await _client.from('families').delete().eq('id', _familyId!);

    _familyId = null;
    _familyCode = null;
    _familyName = null;
    _isInFamily = false;
    _role = null;
    _members = [];
    _pendingInvites = [];
    _membersSub?.cancel();
    _invitesSub?.cancel();
    safeNotify();
  }

  Future<void> assignAdmin(String memberUid) async {
    if (_familyId == null || !isOwner) return;
    await _client
        .from('family_members')
        .update({'role': 'admin'})
        .eq('family_id', _familyId!)
        .eq('user_uid', memberUid);
  }

  Future<void> removeAdmin(String memberUid) async {
    if (_familyId == null || !isOwner) return;
    await _client
        .from('family_members')
        .update({'role': 'member'})
        .eq('family_id', _familyId!)
        .eq('user_uid', memberUid);
  }

  Future<void> updateMemberContribution(String memberUid, int amount) async {
    if (_familyId == null) return;
    final existing = await _client
        .from('family_members')
        .select('contribution')
        .eq('family_id', _familyId!)
        .eq('user_uid', memberUid)
        .maybeSingle();
    if (existing != null) {
      await _client.from('family_members').update({
        'contribution': (existing['contribution'] ?? 0) + amount,
      }).eq('family_id', _familyId!).eq('user_uid', memberUid);
    }
  }

  Future<void> addFamilyDiamonds(int amount) async {
    if (_familyId == null) return;
    _familyDiamonds += amount;
    await _client.from('families').update({
      'diamonds': _familyDiamonds,
    }).eq('id', _familyId!);
    safeNotify();
  }

  void cleanup() {
    _membersSub?.cancel();
    _invitesSub?.cancel();
  }
}
