import 'package:flutter/material.dart';

class RoomExitHandler {

  // 1. خروج نهائي من الغرفة (فصل الصوت والرجوع للصفحة الرئيسية)
  static void leaveRoomCompletely(BuildContext context) {
    // ضع هنا كود قطع اتصال الصوت (مثلاً Agora Engine Leave Channel)
    // AgoraClient.leaveChannel();

    // العودة للصفحة الرئيسية وإزالة شاشة الروم من الـ Stack
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // 2. الاحتفاظ بالروم عائمة (تصغير الشاشة مع استمرار الصوت في الخلفية)
  static void minimizeRoomToFloating(BuildContext context) {
    // العودة للصفحة الرئيسية مع إبقاء الاتصال الصوتي مفتوحاً
    Navigator.pop(context);
    
    // تفعيل الـ Floating Widget العائمة فوق التطبيق لعرض صورة الروم وزر الـ X
    // (يتم استدعاء الـ Overlay العائم الخاص بالروم هنا)
  }
}
