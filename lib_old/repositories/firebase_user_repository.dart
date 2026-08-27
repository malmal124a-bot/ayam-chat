import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  @override
  Future<UserModel?> getUser(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user from Firestore: $e');
      return null;
    }
  }

  @override
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.id).set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user in Firestore: $e');
      rethrow;
    }
  }

  @override
  Future<bool> login(String username, String password) async {
    // Firebase Auth handles authentication, this is for backward compatibility
    return true;
  }

  Future<void> createUser(UserModel user) async {
    try {
      final doc = await _firestore.collection(_collection).doc(user.id).get();
      if (!doc.exists) {
        await _firestore.collection(_collection).doc(user.id).set(user.toJson());
      }
    } catch (e) {
      debugPrint('Error creating user in Firestore: $e');
      rethrow;
    }
  }
}
