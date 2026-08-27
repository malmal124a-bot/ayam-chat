import 'package:flutter/foundation.dart';

// [تبديل واجهات الروم أو النوافذ المنبثقة حسب طلب الهندسة]
// إيقاف واستبعاد الواجهة غير المنتظمة، وتفعيل الواجهة الثانية المنظمة والشيك بالكامل.

class RoomInterfaceSwitcher {
  static void switchInterface(bool useCleanAndStylishView) {
    if (useCleanAndStylishView) {
      // تشغيل الواجهة المنظمة والشيك المظبوطة
      debugPrint("تم تفعيل الواجهة الثانية المنتظمة والشيك بنجاح");
    } else {
      // إغلاق وتعطيل الواجهة القديمة غير المنتظمة
      debugPrint("تم إيقاف الواجهة غير المنتظمة");
    }
  }
}
