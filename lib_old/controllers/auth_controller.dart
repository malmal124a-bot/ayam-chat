import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'user_controller.dart';
import 'wallet_controller.dart';
import 'agency_controller.dart';
import '../models/transaction_model.dart' as tx_model;
import '../firebase_options.dart';

class AuthController extends ChangeNotifier {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: DefaultFirebaseOptions.currentPlatform.iosClientId,
  );
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null || _isLoggedIn;

  AuthController._internal() {
    debugPrint('Initializing: AuthController');
    _loadSession();
    _auth.authStateChanges().listen((User? user) {
      _isLoggedIn = user != null;
      notifyListeners();
    });
    
    // Task 1: Reactive Auto-scaling SVIP Logic
    // Listen to WalletController for any new recharge/transaction
    WalletController().addListener(() {
      updateSvipLevel(WalletController().getTotalRecharged());
    });
  }

  // VIP Colors Map
  static const Map<int, Color> vipColors = {
    1: Colors.grey,
    2: Colors.blueGrey,
    3: Colors.blue,
    4: Colors.cyan,
    5: Colors.teal,
    6: Colors.green,
    7: Colors.orange,
    8: Colors.deepOrange,
    9: Colors.purple,
  };

  // Wholesale Pricing Logic
  static const int standardRate = 10000;  // $1 = 10,000 diamonds
  static const int wholesaleRate = 12000; // $1 = 12,000 diamonds for agents

  int get currentDiamondRate => UserController().isAgent ? wholesaleRate : standardRate;

  bool _isLoggedIn = false;

  // SVIP Level Logic
  int _svipLevel = 0;
  int get svipLevel => _svipLevel;

  // Agency Application Data
  Map<String, dynamic>? _agencyApplication;
  Map<String, dynamic>? get agencyApplication => _agencyApplication;

  void saveAgencyApplication(Map<String, dynamic> data) {
    _agencyApplication = data;
    notifyListeners();
  }

  /// Finalizes the agency application by saving data to the user profile
  /// and creating a pending request in the AgencyController.
  Future<void> submitAgencyApplication() async {
    if (_agencyApplication == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Save personal verification data to the persistent User Profile
      await prefs.setString('profile_full_name', _agencyApplication!['name'] ?? '');
      await prefs.setString('profile_phone', _agencyApplication!['phone'] ?? '');
      await prefs.setString('profile_email', _agencyApplication!['email'] ?? '');
      await prefs.setString('profile_id_front', _agencyApplication!['frontId'] ?? '');
      await prefs.setString('profile_id_back', _agencyApplication!['backId'] ?? '');

      // 2. Create the Pending Agency Request in the agency management system
      final agencyController = AgencyController();
      
      // Sync parameters with AgencyController.submitAgencyRequest named arguments
      await agencyController.submitAgencyRequest(
        agencyName: 'وكالة ${_agencyApplication!['name']}',
        personalName: _agencyApplication!['name'] ?? '',
        nationalId: 'PENDING_VERIFICATION',
        phoneNumber: _agencyApplication!['phone'] ?? '',
        whatsappLink: _agencyApplication!['phone'] ?? '',
        idCardFrontUrl: _agencyApplication!['frontId'] ?? '',
        idCardBackUrl: _agencyApplication!['backId'] ?? '',
        email: _agencyApplication!['email'] ?? '',
        description: 'Selected Tier: \$${_agencyApplication!['selectedTier']}',
        selectedTier: _agencyApplication!['selectedTier'] as int?,
      );

      debugPrint('Agency application successfully submitted and linked to profile.');
    } catch (e) {
      debugPrint('Error in submitAgencyApplication: $e');
    }
  }

  /// Task 1: Updates SVIP level based on total charged amount.
  /// Scaling: 1 SVIP level for every 1,000 USD recharged.
  void updateSvipLevel(double totalChargedAmount) {
    int newLevel = (totalChargedAmount / 1000).floor();
    if (newLevel != _svipLevel) {
      _svipLevel = newLevel;
      notifyListeners();
      debugPrint('SVIP Level Updated: $_svipLevel (Total Charged: $totalChargedAmount)');
    }
  }

  /// Unified Transaction History proxied from WalletController
  List<dynamic> get transactionHistory => WalletController().transactions.toList();

  Future<void> _loadSession() async {
    try {
      _isLoggedIn = _auth.currentUser != null;
      
      // Initialize SVIP Level from existing data
      _svipLevel = (WalletController().getTotalRecharged() / 1000).floor();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Auth Session Error: $e');
    }
  }

  Future<void> login() async {
    try {
      // This is now handled by Google Sign-In
      debugPrint('AuthController: login() called - use signInWithGoogle() instead');
    } catch (e) {
      debugPrint('Login Error: $e');
    }
  }

  Future<bool> signInWithPhone(String phoneNumber, String verificationId, String smsCode) async {
    try {
      debugPrint('PHONE_AUTH: Verifying phone number');
      
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      debugPrint('PHONE_AUTH: Successfully signed in: ${userCredential.user?.uid}');
      
      _isLoggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('PHONE_AUTH Error: $e');
      rethrow;
    }
  }

  Future<void> verifyPhoneNumber(String phoneNumber, Function(String verificationId) onCodeSent, Function(String? error) onError) async {
    try {
      debugPrint('PHONE_AUTH: Sending verification code to $phoneNumber');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          _isLoggedIn = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          notifyListeners();
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('PHONE_AUTH Verification failed: $e');
          onError(e.message);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('PHONE_AUTH: Code sent, verificationId: $verificationId');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('PHONE_AUTH: Auto retrieval timeout');
        },
      );
    } catch (e) {
      debugPrint('PHONE_AUTH Error: $e');
      onError(e.toString());
    }
  }

  Future<bool> signInWithFacebook() async {
    try {
      debugPrint('FACEBOOK_AUTH: Facebook login not implemented yet - requires flutter_facebook_auth package');
      
      // TODO: Implement Facebook authentication
      // 1. Add flutter_facebook_auth to pubspec.yaml
      // 2. Configure Facebook app in Firebase Console
      // 3. Add Facebook app credentials to Android/iOS
      
      return false;
    } catch (e) {
      debugPrint('FACEBOOK_AUTH Error: $e');
      rethrow;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('GOOGLE_AUTH: Starting Google Sign-In process');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('GOOGLE_AUTH: Sign-in aborted by user');
        return false;
      }

      debugPrint('GOOGLE_AUTH: Got Google user: ${googleUser.email}');
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('GOOGLE_AUTH: Signing in to Firebase');
      
      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      debugPrint('GOOGLE_AUTH: Successfully signed in: ${userCredential.user?.uid}');
      
      _isLoggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      
      // Generate unique 6-digit user ID
      String userId = await _generateUnique6DigitId();
      
      // Write user data to Firestore immediately
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'userId': userId,
        'name': googleUser.displayName ?? 'User',
        'email': googleUser.email ?? '',
        'photoUrl': googleUser.photoUrl ?? '',
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
      }, SetOptions(merge: true));
      
      debugPrint('GOOGLE_AUTH: User data written to Firestore with ID: $userId');
      
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('GOOGLE_AUTH Error: $e');
      rethrow;
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
      final snapshot = await _firestore.collection('users').where('userId', isEqualTo: candidateId).limit(1).get();
      if (snapshot.docs.isEmpty) {
        debugPrint('GOOGLE_AUTH: Generated unique ID: $candidateId (attempt ${attempts + 1})');
        return candidateId;
      }
      
      attempts++;
    }
    
    // Fallback if all attempts fail (should be extremely rare)
    final timestampId = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    debugPrint('GOOGLE_AUTH: Using timestamp-based fallback ID: $timestampId');
    return timestampId;
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _isLoggedIn = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      notifyListeners();
    } catch (e) {
      debugPrint('Logout Error: $e');
    }
  }

  /// Task 1: Updates user balance via WalletController with optional metadata
  void updateBalance(double amount, {String? description, String? method}) {
    WalletController().addBalance(amount, description: description, method: method);
    notifyListeners();
  }

  Future<void> pickAndUploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
      );
      
      if (image != null) {
        String imageUrl;
        
        if (kIsWeb) {
          // Web: Upload bytes to Firebase Storage
          final bytes = await image.readAsBytes();
          final userId = UserController().id;
          final ref = _storage.ref().child('profile_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
          final uploadTask = ref.putData(bytes);
          final snapshot = await uploadTask;
          imageUrl = await snapshot.ref.getDownloadURL();
        } else {
          // Mobile: Upload file to Firebase Storage
          final file = File(image.path);
          final userId = UserController().id;
          final ref = _storage.ref().child('profile_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
          final uploadTask = ref.putFile(file);
          final snapshot = await uploadTask;
          imageUrl = await snapshot.ref.getDownloadURL();
        }
        
        // Update user profile with the Firebase Storage URL
        UserController().updateProfile(newPic: imageUrl);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking/uploading profile image: $e');
    }
  }
}
