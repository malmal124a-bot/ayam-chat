import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomShareHelper {
  
  // دالة نسخ الرابط الحقيقي للروم
  static void copyRoomLink(BuildContext context, String roomId) {
    final roomLink = 'https://rssasachat.com/room/$roomId';
    Clipboard.setData(ClipboardData(text: roomLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ رابط الغرفة بنجاح')),
    );
  }

  // دالة المشاركة الفعالة عبر منصات التواصل الاجتماعي
  static Future<void> shareToSocial({
    required String platform,
    required String roomId,
    required String roomName,
  }) async {
    final String message = 'انضم إلى غرفة "$roomName" على Rssasa Chat واستمتع بالدردشة الصوتية! معرف الغرفة: $roomId';
    final String encodedMessage = Uri.encodeComponent(message);
    final String roomLink = Uri.encodeComponent('https://rssasachat.com/room/$roomId');

    String url = '';

    if (platform == 'whatsapp') {
      url = 'https://wa.me/?text=$encodedMessage%20$roomLink';
    } else if (platform == 'telegram') {
      url = 'https://t.me/share/url?url=$roomLink&text=$encodedMessage';
    } else if (platform == 'facebook') {
      url = 'https://www.facebook.com/sharer/sharer.php?u=$roomLink';
    } else if (platform == 'twitter') {
      url = 'https://twitter.com/intent/tweet?text=$encodedMessage&url=$roomLink';
    }

    if (url.isNotEmpty) {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
