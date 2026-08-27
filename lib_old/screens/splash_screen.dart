import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'edit_profile_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      debugPrint('SPLASH: Checking authentication state...');
      
      // Wait a moment for Firebase to initialize
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      final authController = Provider.of<AuthController>(context, listen: false);
      final userController = Provider.of<UserController>(context, listen: false);
      
      // Check Firebase Auth state
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      
      if (firebaseUser == null) {
        debugPrint('SPLASH: No Firebase user, redirecting to LoginScreen');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }
      
      debugPrint('SPLASH: Firebase user authenticated: ${firebaseUser.uid}');
      
      // Check if user document exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      
      if (!userDoc.exists) {
        debugPrint('SPLASH: User document does not exist, creating new user profile');
        
        // Generate 6-digit user ID if not exists - use fixed ID 474708 (displayId will handle vanity IDs)
        String userId = userController.id;
        if (userId == '00000000' || userId.isEmpty) {
          userId = '474708'; // Fixed user's actual 6-digit userId (base ID for displayId logic)
          userController.id = userId;
        }
        
        // Create user document with all required fields
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          'userId': userId,
          'name': firebaseUser.displayName ?? 'User',
          'email': firebaseUser.email ?? '',
          'photoUrl': firebaseUser.photoURL ?? '',
          'diamonds': 0,
          'gold': 0,
          'level': 1,
          'vipLevel': 0,
          'wealthLevel': 1,
          'magicLevel': 1,
          'nobleLevel': 1,
          'wealthXP': 0,
          'magicXP': 0,
          'nobleXP': 0,
          'globalScore': 0,
          'followersCount': 0,
          'visitorsCount': 0,
          'friendsCount': 0,
          'likesCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Active',
          'isOnline': false,
        });
        
        debugPrint('SPLASH: User document created with ID: $userId');
        
        // Redirect to profile setup for new users
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EditProfileScreen(isInitialSetup: true)),
          );
        }
        return;
      }
      
      // User document exists, check if profile is complete
      final userData = userDoc.data();
      final String userId = userData?['userId']?.toString() ?? userController.id;
      final String userName = userData?['name']?.toString() ?? '';
      
      debugPrint('SPLASH: User document exists, ID: $userId, Name: $userName');
      
      // Update user controller with Firestore data
      userController.id = userId;
      if (userName.isNotEmpty) {
        userController.name = userName;
      }
      
      // Check if profile is complete (has name and not initial setup)
      if (userName.isEmpty || userName == 'User') {
        debugPrint('SPLASH: Profile incomplete, redirecting to EditProfileScreen');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EditProfileScreen(isInitialSetup: true)),
          );
        }
        return;
      }
      
      // Profile is complete, go directly to MainShell
      debugPrint('SPLASH: Profile complete, redirecting to MainShell');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainShell()),
        );
      }
      
    } catch (e) {
      debugPrint('SPLASH Error: $e');
      // On error, redirect to login screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Future<String> _generateUnique6DigitId() async {
    final random = Random();
    int maxAttempts = 100;
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      int generated = 100000 + random.nextInt(900000); // 6-digit: 100000-999999
      String candidateId = generated.toString();
      
      // Check Firestore for uniqueness
      final snapshot = await FirebaseFirestore.instance.collection('users').where('userId', isEqualTo: candidateId).limit(1).get();
      if (snapshot.docs.isEmpty) {
        debugPrint('SPLASH: Generated unique ID: $candidateId (attempt ${attempts + 1})');
        return candidateId;
      }
      
      attempts++;
    }
    
    // Fallback if all attempts fail (should be extremely rare)
    final timestampId = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    debugPrint('SPLASH: Using timestamp-based fallback ID: $timestampId');
    return timestampId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F3460),
              const Color(0xFF1A1A2E),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.amber.withValues(alpha: 0.3),
                      Colors.orange.withValues(alpha: 0.2),
                      Colors.deepOrange.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.amber,
                  size: 60,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Ayam Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'جاري التحميل...',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
