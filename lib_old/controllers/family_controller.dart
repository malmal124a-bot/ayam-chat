import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ayam_chat/controllers/user_controller.dart';

class FamilyMember {
  final String id;
  final String name;
  final String role;
  final String avatar;
  final int contribution;

  FamilyMember({
    required this.id,
    required this.name,
    required this.role,
    this.avatar = 'assets/Asad/bg_vip_content.png',
    this.contribution = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'avatar': avatar,
      'contribution': contribution,
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      avatar: json['avatar'] as String? ?? 'assets/Asad/bg_vip_content.png',
      contribution: (json['contribution'] as num?)?.toInt() ?? 0,
    );
  }
}

class JoinRequest {
  final String userId;
  final String userName;
  final String avatar;

  JoinRequest({required this.userId, required this.userName, required this.avatar});

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'avatar': avatar,
    };
  }

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      avatar: json['avatar'] as String? ?? 'assets/Asad/bg_vip_content.png',
    );
  }
}

class FamilyTask {
  final String id;
  final String title;
  final String reward;
  final double progress; 
  bool isCompleted;
  bool isClaimed;

  FamilyTask({
    required this.id,
    required this.title,
    required this.reward,
    required this.progress,
    this.isCompleted = false,
    this.isClaimed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'reward': reward,
      'progress': progress,
      'isCompleted': isCompleted,
      'isClaimed': isClaimed,
    };
  }

  factory FamilyTask.fromJson(Map<String, dynamic> json) {
    return FamilyTask(
      id: json['id'] as String,
      title: json['title'] as String,
      reward: json['reward'] as String,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isClaimed: json['isClaimed'] as bool? ?? false,
    );
  }
}

class FamilyStoreItem {
  final String id;
  final String name;
  final int price;
  final String image;

  FamilyStoreItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
    };
  }

  factory FamilyStoreItem.fromJson(Map<String, dynamic> json) {
    return FamilyStoreItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num?)?.toInt() ?? 0,
      image: json['image'] as String,
    );
  }
}

class FamilyController extends ChangeNotifier {
  static final FamilyController _instance = FamilyController._internal();
  factory FamilyController() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FamilyController._internal() {
    debugPrint('Initializing: FamilyController');
    _listenToFirestore();
  }

  UserController get _userController => UserController();

  String? _familyName;
  String? _description;
  String? _rules;
  String? _role; 
  bool _isInFamily = false;
  int _familyLevel = 3;
  int _familyDiamonds = 2500;
  List<FamilyMember> _members = [];
  List<JoinRequest> _joinRequests = [];
  
  final List<FamilyTask> _tasks = [
    FamilyTask(id: '1', title: 'جمع 5000 نقطة شعبية', reward: '500', progress: 0.6),
    FamilyTask(id: '2', title: 'بقاء 5 أعضاء في الغرفة', reward: '200', progress: 1.0, isCompleted: true),
    FamilyTask(id: '3', title: 'إرسال 10 هدايا عائلية', reward: '1000', progress: 0.2),
  ];

  final List<FamilyStoreItem> _storeItems = [
    FamilyStoreItem(id: '1', name: 'إطار الملك العائلي', price: 5000, image: 'assets/store_assets/admin_frame.webp.webp'),
    FamilyStoreItem(id: '2', name: 'شعار العائلة المميز', price: 2000, image: 'assets/store_assets/host_tag.webp.webp'),
    FamilyStoreItem(id: '3', name: 'تأثير دخول العمالقة', price: 10000, image: 'assets/store_assets/bd_tag.webp.webp'),
  ];

  String? get familyName => _familyName;
  String? get description => _description;
  String? get rules => _rules;
  String? get role => _role;
  bool get isInFamily => _isInFamily;
  int get familyLevel => _familyLevel;
  int get familyDiamonds => _familyDiamonds;
  List<FamilyMember> get members => _members;
  List<JoinRequest> get joinRequests => _joinRequests;
  List<FamilyTask> get tasks => _tasks;
  List<FamilyStoreItem> get storeItems => _storeItems;

  void _listenToFirestore() {
    final userId = _userController.id;
    
    // Listen to user's family data
    _firestore.collection('users').doc(userId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final familyId = data['familyId'] as String?;
          if (familyId != null) {
            _loadFamilyData(familyId);
          }
        }
      }
    });
  }

  Future<void> _loadFamilyData(String familyId) async {
    try {
      final familyDoc = await _firestore.collection('families').doc(familyId).get();
      if (familyDoc.exists) {
        final data = familyDoc.data();
        if (data != null) {
          _familyName = data['name'] as String?;
          _description = data['description'] as String?;
          _rules = data['rules'] as String?;
          _familyLevel = (data['level'] as num?)?.toInt() ?? 1;
          _familyDiamonds = (data['diamonds'] as num?)?.toInt() ?? 0;
          _isInFamily = true;
          
          // Load members
          final membersSnapshot = await _firestore
              .collection('families').doc(familyId)
              .collection('members')
              .get();
          _members = membersSnapshot.docs
              .map((doc) => FamilyMember.fromJson(doc.data()))
              .toList();
          
          // Load join requests
          final requestsSnapshot = await _firestore
              .collection('families').doc(familyId)
              .collection('join_requests')
              .get();
          _joinRequests = requestsSnapshot.docs
              .map((doc) => JoinRequest.fromJson(doc.data()))
              .toList();
          
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading family data: $e');
    }
  }

  void updateFamilyDetails({String? name, String? description, String? rules}) {
    if (name != null) _familyName = name;
    if (description != null) _description = description;
    if (rules != null) _rules = rules;
    _saveToFirestore();
    notifyListeners();
  }

  Future<void> joinFamily(String familyId, {String role = 'Member'}) async {
    try {
      final userId = _userController.id;
      
      // Update user document with family ID
      await _firestore.collection('users').doc(userId).update({
        'familyId': familyId,
        'familyRole': role,
      });
      
      // Add user to family members
      await _firestore.collection('families').doc(familyId)
          .collection('members').doc(userId).set({
        'id': userId,
        'name': _userController.name,
        'role': role,
        'avatar': _userController.profilePic,
        'contribution': 0,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      
      _role = role;
      _isInFamily = true;
      await _loadFamilyData(familyId);
    } catch (e) {
      debugPrint('Error joining family: $e');
    }
  }

  Future<void> leaveFamily() async {
    try {
      final userId = _userController.id;
      final familyId = await _getUserFamilyId();
      
      if (familyId != null) {
        // Remove user from family members
        await _firestore.collection('families').doc(familyId)
            .collection('members').doc(userId).delete();
        
        // Remove family ID from user document
        await _firestore.collection('users').doc(userId).update({
          'familyId': FieldValue.delete(),
          'familyRole': FieldValue.delete(),
        });
      }
      
      _familyName = null;
      _description = null;
      _rules = null;
      _role = null;
      _isInFamily = false;
      _members = [];
      _joinRequests = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error leaving family: $e');
    }
  }

  Future<void> createFamily(String name) async {
    try {
      final userId = _userController.id;
      final familyRef = _firestore.collection('families').doc();
      
      await familyRef.set({
        'name': name,
        'description': 'عائلة جديدة للنخبة.',
        'rules': 'لا توجد قوانين محددة بعد.',
        'level': 1,
        'diamonds': 0,
        'ownerId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Add owner as member
      await familyRef.collection('members').doc(userId).set({
        'id': userId,
        'name': _userController.name,
        'role': 'Owner',
        'avatar': _userController.profilePic,
        'contribution': 0,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      
      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'familyId': familyRef.id,
        'familyRole': 'Owner',
      });
      
      _familyName = name;
      _role = 'Owner';
      _isInFamily = true;
      _familyLevel = 1;
      _familyDiamonds = 0;
      _description = "عائلة جديدة للنخبة.";
      _rules = "لا توجد قوانين محددة بعد.";
      _members = [
        FamilyMember(
          id: userId, 
          name: _userController.name, 
          role: 'Owner',
          contribution: 0,
        ),
      ];
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating family: $e');
    }
  }

  Future<void> acceptJoinRequest(String userId) async {
    try {
      final familyId = await _getUserFamilyId();
      if (familyId == null) return;
      
      final reqIndex = _joinRequests.indexWhere((r) => r.userId == userId);
      if (reqIndex != -1) {
        final req = _joinRequests[reqIndex];
        
        // Add to members
        await _firestore.collection('families').doc(familyId)
            .collection('members').doc(userId).set({
          'id': req.userId,
          'name': req.userName,
          'role': 'Member',
          'avatar': req.avatar,
          'contribution': 0,
          'joinedAt': FieldValue.serverTimestamp(),
        });
        
        // Remove from join requests
        await _firestore.collection('families').doc(familyId)
            .collection('join_requests').doc(userId).delete();
        
        _members.add(FamilyMember(id: req.userId, name: req.userName, role: 'Member', avatar: req.avatar));
        _joinRequests.removeAt(reqIndex);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error accepting join request: $e');
    }
  }

  Future<void> rejectJoinRequest(String userId) async {
    try {
      final familyId = await _getUserFamilyId();
      if (familyId == null) return;
      
      await _firestore.collection('families').doc(familyId)
          .collection('join_requests').doc(userId).delete();
      
      _joinRequests.removeWhere((r) => r.userId == userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error rejecting join request: $e');
    }
  }

  Future<void> removeMember(String memberId) async {
    try {
      final familyId = await _getUserFamilyId();
      if (familyId == null) return;
      
      await _firestore.collection('families').doc(familyId)
          .collection('members').doc(memberId).delete();
      
      await _firestore.collection('users').doc(memberId).update({
        'familyId': FieldValue.delete(),
        'familyRole': FieldValue.delete(),
      });
      
      _members.removeWhere((m) => m.id == memberId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing member: $e');
    }
  }

  Future<void> assignModerator(String memberId) async {
    try {
      final familyId = await _getUserFamilyId();
      if (familyId == null) return;
      
      // Update member role in Firestore
      await _firestore.collection('families').doc(familyId)
          .collection('members').doc(memberId).update({
        'role': 'Moderator',
      });
      
      // Update user's family role
      await _firestore.collection('users').doc(memberId).update({
        'familyRole': 'Moderator',
      });
      
      // Update local state
      final memberIndex = _members.indexWhere((m) => m.id == memberId);
      if (memberIndex != -1) {
        _members[memberIndex] = FamilyMember(
          id: _members[memberIndex].id,
          name: _members[memberIndex].name,
          role: 'Moderator',
          avatar: _members[memberIndex].avatar,
          contribution: _members[memberIndex].contribution,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error assigning moderator: $e');
    }
  }

  Future<void> removeModerator(String memberId) async {
    try {
      final familyId = await _getUserFamilyId();
      if (familyId == null) return;
      
      // Update member role back to Member in Firestore
      await _firestore.collection('families').doc(familyId)
          .collection('members').doc(memberId).update({
        'role': 'Member',
      });
      
      // Update user's family role
      await _firestore.collection('users').doc(memberId).update({
        'familyRole': 'Member',
      });
      
      // Update local state
      final memberIndex = _members.indexWhere((m) => m.id == memberId);
      if (memberIndex != -1) {
        _members[memberIndex] = FamilyMember(
          id: _members[memberIndex].id,
          name: _members[memberIndex].name,
          role: 'Member',
          avatar: _members[memberIndex].avatar,
          contribution: _members[memberIndex].contribution,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing moderator: $e');
    }
  }

  Future<bool> buyStoreItem(FamilyStoreItem item) async {
    try {
      final familyId = await _getUserFamilyId();
      if (familyId == null) return false;
      
      if (_familyDiamonds >= item.price) {
        _familyDiamonds -= item.price;
        
        await _firestore.collection('families').doc(familyId).update({
          'diamonds': _familyDiamonds,
        });
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error buying store item: $e');
      return false;
    }
  }

  Future<void> claimTaskReward(String taskId) async {
    try {
      final familyId = await _getUserFamilyId();
      if (familyId == null) return;
      
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1 && _tasks[index].isCompleted && !_tasks[index].isClaimed) {
        _tasks[index].isClaimed = true;
        _familyDiamonds += int.parse(_tasks[index].reward);
        
        await _firestore.collection('families').doc(familyId).update({
          'diamonds': _familyDiamonds,
        });
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error claiming task reward: $e');
    }
  }

  Future<String?> _getUserFamilyId() async {
    try {
      final userId = _userController.id;
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['familyId'] as String?;
      }
    } catch (e) {
      debugPrint('Error getting user family ID: $e');
    }
    return null;
  }

  Future<void> _saveToFirestore() async {
    try {
      final familyId = await _getUserFamilyId();
      if (familyId != null) {
        await _firestore.collection('families').doc(familyId).update({
          'name': _familyName,
          'description': _description,
          'rules': _rules,
        });
      }
    } catch (e) {
      debugPrint('Error saving family to Firestore: $e');
    }
  }
}
