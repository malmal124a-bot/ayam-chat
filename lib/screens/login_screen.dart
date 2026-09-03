import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/app_icon.dart';
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
      
      // Google Sign-In via Supabase (hosted OAuth)
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
        final isNew = authController.isNewUser;
        debugPrint('GOOGLE_LOGIN: isNew=$isNew, redirecting to ${isNew ? "EditProfile" : "MainShell"}');
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) =>
            isNew ? const EditProfileScreen(isInitialSetup: true) : const MainShell())
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
      await authController.signInWithFacebook();
      
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

  void _showEmailAuthDialog({required bool isSignUp}) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool signingUp = isSignUp;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1F180B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            signingUp ? 'إنشاء حساب جديد' : 'تسجيل الدخول بالبريد',
            style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'البريد الإلكتروني',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    prefixIcon: const AppIcon('Icons.email_rounded', icon: Icons.email_rounded, color: Colors.amber),
                    filled: true,
                    fillColor: const Color(0xFF2A1F0D),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'كلمة المرور',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    prefixIcon: const AppIcon('Icons.lock_rounded', icon: Icons.lock_rounded, color: Colors.amber),
                    filled: true,
                    fillColor: const Color(0xFF2A1F0D),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () {
                setDialogState(() => signingUp = !signingUp);
              },
              child: Text(
                signingUp ? 'لديك حساب؟ سجل الدخول' : 'جديد؟ أنشئ حساباً',
                style: const TextStyle(color: Colors.amber),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      final password = passwordController.text;
                      if (email.isEmpty || password.length < 6) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('أدخل بريداً صحيحاً وكلمة مرور من 6 أحرف على الأقل')),
                          );
                        }
                        return;
                      }
                      Navigator.pop(dialogContext);
                      if (signingUp) {
                        await _handleEmailSignUp(email, password);
                      } else {
                        await _handleEmailLogin(email, password);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(signingUp ? 'إنشاء حساب' : 'دخول', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEmailLogin(String email, String password) async {
    setState(() => _isLoading = true);
    try {
      if (!mounted) return;
      final authController = Provider.of<AuthController>(context, listen: false);
      final success = await authController.signInWithEmail(email, password);

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل تسجيل الدخول، تحقق من البريد وكلمة المرور')),
          );
        }
        return;
      }

      if (!mounted) return;
      Provider.of<UserController>(context, listen: false).login();

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainShell()),
        );
      }
    } catch (e) {
      debugPrint('EMAIL_LOGIN Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailSignUp(String email, String password) async {
    setState(() => _isLoading = true);
    try {
      if (!mounted) return;
      final authController = Provider.of<AuthController>(context, listen: false);
      final success = await authController.signUpWithEmail(email, password);

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل إنشاء الحساب، تأكد من عدم وجود حساب بنفس البريد')),
          );
        }
        return;
      }

      if (!mounted) return;
      Provider.of<UserController>(context, listen: false).login();

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EditProfileScreen(isInitialSetup: true)),
        );
      }
    } catch (e) {
      debugPrint('EMAIL_SIGNUP Error: $e');
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
                          const SizedBox(height: 30),
                          // Email / Password login
                          GestureDetector(
                            onTap: _isLoading ? null : () => _showEmailAuthDialog(isSignUp: false),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white24, width: 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const AppIcon('Icons.alternate_email_rounded', icon: Icons.alternate_email_rounded, color: Colors.amber, size: 22),
                                  const SizedBox(width: 10),
                                  Text(
                                    'الدخول بالبريد الإلكتروني',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      child: const AppIcon(
        'Icons.chat_bubble_rounded',
        icon: Icons.chat_bubble_rounded,
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
            AppIcon(
              'Icons.person_outline_rounded',
              icon: Icons.person_outline_rounded,
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
