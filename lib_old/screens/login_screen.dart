import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';
import 'edit_profile_screen.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    
    try {
      debugPrint('GOOGLE_LOGIN: Initiating Google sign-in');
      
      // Use real Firebase Google Sign-In
      if (!mounted) return;
      final authController = Provider.of<AuthController>(context, listen: false);
      final success = await authController.signInWithGoogle();
      
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل تسجيل الدخول عبر Google')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      
      // Call user controller login logic
      if (!mounted) return;
      Provider.of<UserController>(context, listen: false).login();
      
      // Simulate a brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        debugPrint('GOOGLE_LOGIN: Redirecting to EditProfileScreen');
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const EditProfileScreen(isInitialSetup: true))
        );
      }
    } catch (e) {
      debugPrint('GOOGLE_LOGIN Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleFacebookLogin() async {
    setState(() => _isLoading = true);
    
    try {
      debugPrint('FACEBOOK_LOGIN: Initiating Facebook sign-in');
      
      if (!mounted) return;
      final authController = Provider.of<AuthController>(context, listen: false);
      final success = await authController.signInWithFacebook();
      
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل تسجيل الدخول عبر Facebook')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      
      // Call user controller login logic
      if (!mounted) return;
      Provider.of<UserController>(context, listen: false).login();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        debugPrint('FACEBOOK_LOGIN: Redirecting to EditProfileScreen');
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const EditProfileScreen(isInitialSetup: true))
        );
      }
    } catch (e) {
      debugPrint('FACEBOOK_LOGIN Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePhoneLogin() async {
    setState(() => _isLoading = true);
    
    try {
      debugPrint('PHONE_LOGIN: Phone authentication requires phone number input screen');
      
      // TODO: Create phone number input screen
      // For now, show message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال رقم الهاتف (قيد التطوير)')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGuestLogin() async {
    setState(() => _isLoading = true);
    
    try {
      debugPrint('GUEST_LOGIN: Initiating guest login');
      
      // Generate temporary random 6-digit user ID
      final random = DateTime.now().millisecondsSinceEpoch % 900000 + 100000;
      final guestId = random.toString();
      
      if (!mounted) return;
      final userController = Provider.of<UserController>(context, listen: false);
      
      // Set up guest user session
      userController.id = guestId;
      userController.name = 'Guest $guestId';
      userController.login();
      
      // Simulate brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        debugPrint('GUEST_LOGIN: Redirecting to Main Shell');
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const MainShell())
        );
      }
    } catch (e) {
      debugPrint('GUEST_LOGIN Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 375),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Elegant app logo in card
                          _buildAppLogoCard(),
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
                            'دردشة صوتية ممتعة',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 50),
                          const Text(
                            'الدخول عبر',
                            style: TextStyle(fontSize: 14, color: Colors.white54),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSocialIcon(
                                icon: Icons.g_mobiledata,
                                color: Colors.red,
                                onTap: _handleGoogleLogin,
                                label: 'Google',
                              ),
                              _buildSocialIcon(
                                icon: Icons.phone,
                                color: Colors.green,
                                onTap: _handlePhoneLogin,
                                label: 'Phone',
                              ),
                              _buildSocialIcon(
                                icon: Icons.facebook,
                                color: Colors.blue,
                                onTap: _handleFacebookLogin,
                                label: 'Facebook',
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          // Guest/Quick Login Button
                          _buildGuestLoginButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppLogoCard() {
    return Container(
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
    );
  }

  Widget _buildSocialIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleGuestLogin,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withValues(alpha: 0.2),
              Colors.orange.withValues(alpha: 0.1),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline_rounded,
              color: Colors.amber,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'دخول سريع (ضيف)',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
