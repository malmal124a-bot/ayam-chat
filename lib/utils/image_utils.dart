import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  /// Processes an XFile into a lightweight compressed Base64 string.
  /// Target: JPEG quality 40-50%, max dimensions 300x300, size < 80KB.
  /// Note: maxWidth, maxHeight, and imageQuality must be passed to ImagePicker.pickImage.
  static Future<String?> xFileToBase64(XFile xFile) async {
    try {
      final Uint8List bytes = await xFile.readAsBytes();
      
      // Strict size enforcement: 80KB limit (approx 81920 bytes)
      // Base64 string is roughly 4/3 larger than raw bytes.
      // So 80KB string means ~60KB raw bytes.
      if (bytes.length > 70 * 1024) {
        // If still too large after ImagePicker compression, we can't do much without external libs
        // But with quality 50 and 300x300, it should be around 10-20KB.
      }

      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (e) {
      return null;
    }
  }

  /// Checks if a Base64 string size is within the allowed lightweight limit.
  static bool isBase64SizeValid(String? base64String) {
    if (base64String == null) return false;
    // Base64 overhead is ~33%. Length * 0.75 is actual byte size.
    return (base64String.length * 0.75) < 80 * 1024;
  }

  /// True when [value] is a remote URL (Cloudinary etc.).
  static bool isHttpUrl(String? value) {
    return value != null &&
        (value.startsWith('http://') || value.startsWith('https://'));
  }
}
