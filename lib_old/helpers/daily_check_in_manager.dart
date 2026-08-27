import 'package:flutter/material.dart';

// استبدال الواجهة الحالية وإلغاؤها نهائياً
// استدعاء وتفعيل تصميم تسجيل الدخول اليومي القديم والمنظم

class DailyCheckInManager {
  static Widget getActiveCheckInView() {
    // تم حذف الواجهة غير المطلوبة وعرض الواجهة القديمة السليمة
    return const OldDailyCheckInScreen();
  }
}

class OldDailyCheckInScreen extends StatelessWidget {
  const OldDailyCheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: const Text(
            'تسجيل الدخول اليومي (التصميم القديم والمنظم)',
            style: TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
