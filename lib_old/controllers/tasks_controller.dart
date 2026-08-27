import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wallet_controller.dart';
import 'user_controller.dart';

class Task {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final int targetCount;
  int currentCount;
  final int rewardAmount;
  bool isClaimed;

  Task({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.targetCount,
    this.currentCount = 0,
    required this.rewardAmount,
    this.isClaimed = false,
  });
}

class TasksController extends ChangeNotifier {
  static final TasksController _instance = TasksController._internal();
  factory TasksController() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TasksController._internal() {
    debugPrint('Initializing: TasksController');
    fetchDailyTasks();
    _listenToFirestore();
  }

  void _listenToFirestore() {
    final userId = UserController().id;
    if (userId.isEmpty) return;
    
    // Listen to user's tasks document
    _firestore.collection('users').doc(userId).collection('tasks')
        .doc('daily')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final tasksData = data['tasks'] as Map<String, dynamic>?;
          if (tasksData != null) {
            for (var task in _tasks) {
              final taskData = tasksData[task.id];
              if (taskData != null) {
                task.currentCount = (taskData['currentCount'] as num?)?.toInt() ?? 0;
                task.isClaimed = taskData['isClaimed'] as bool? ?? false;
              }
            }
            notifyListeners();
          }
        }
      }
    });
  }

  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchDailyTasks() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network delay with a strict timeout
      await Future.delayed(const Duration(milliseconds: 500))
          .timeout(const Duration(seconds: 3));

      _tasks = [
        Task(
          id: 'daily_login',
          titleKey: 'task_weekly_login_title',
          descriptionKey: 'task_weekly_login_desc',
          targetCount: 1,
          rewardAmount: 10,
        ),
        Task(
          id: 'send_gift',
          titleKey: 'task_send_gift_title',
          descriptionKey: 'task_send_gift_desc',
          targetCount: 5,
          rewardAmount: 50,
        ),
        Task(
          id: 'join_room',
          titleKey: 'task_join_room_title',
          descriptionKey: 'task_join_room_desc',
          targetCount: 3,
          rewardAmount: 30,
        ),
        Task(
          id: 'send_message',
          titleKey: 'task_send_message_title',
          descriptionKey: 'task_send_message_desc',
          targetCount: 20,
          rewardAmount: 20,
        ),
      ];

      await _loadProgress().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (var task in _tasks) {
        task.currentCount = prefs.getInt('task_${task.id}_count') ?? 0;
        task.isClaimed = prefs.getBool('task_${task.id}_claimed') ?? false;
      }
    } catch (e) {
      debugPrint('Error loading tasks progress: $e');
    }
  }

  Future<void> _saveProgress(Task task) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('task_${task.id}_count', task.currentCount);
      await prefs.setBool('task_${task.id}_claimed', task.isClaimed);
      
      // Save to Firestore
      final userId = UserController().id;
      if (userId.isNotEmpty) {
        await _firestore.collection('users').doc(userId).collection('tasks')
            .doc('daily')
            .set({
          'tasks': {
            for (var t in _tasks)
              t.id: {
                'currentCount': t.currentCount,
                'isClaimed': t.isClaimed,
              }
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving task progress: $e');
    }
  }

  void updateTaskProgress(String taskId, int progress) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      if (task.currentCount < task.targetCount) {
        task.currentCount = (task.currentCount + progress).clamp(0, task.targetCount);
        _saveProgress(task);
        notifyListeners();
      }
    }
  }

  void claimReward(String taskId) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      if (task.currentCount >= task.targetCount && !task.isClaimed) {
        task.isClaimed = true;
        WalletController().addDiamonds(task.rewardAmount);
        _saveProgress(task);
        notifyListeners();
      }
    }
  }
}
