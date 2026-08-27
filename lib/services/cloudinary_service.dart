import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Uploads images and raw files (SVGA, JSON, GIF, audio...) to Cloudinary
/// using an unsigned upload preset (no API secret needed on the client).
class CloudinaryService {
  CloudinaryService._();

  /// Cloud name from the Cloudinary dashboard.
  static const String cloudName = 'womtce0x';

  /// IMPORTANT: Create an unsigned upload preset in Cloudinary
  /// (Dashboard > Settings > Upload > Upload presets > Add upload preset,
  ///  Signing Mode: Unsigned) and paste its name here.
  static const String uploadPreset = 'ayam_chat';

  static bool get isConfigured => uploadPreset.isNotEmpty;

  /// Uploads an image picked with [ImagePicker].
  static Future<String> uploadImage(XFile file, {String? folder}) async {
    final bytes = await file.readAsBytes();
    return uploadImageBytes(bytes,
        folder: folder, fileName: file.name);
  }

  /// Uploads raw image bytes.
  static Future<String> uploadImageBytes(
    Uint8List bytes, {
    String? folder,
    String? fileName,
  }) async {
    return _upload('image', bytes, fileName ?? 'image.jpg', folder: folder);
  }

  /// Uploads a non-image file (SVGA, JSON, GIF, audio...).
  static Future<String> uploadFileBytes(
    Uint8List bytes,
    String fileName, {
    String? folder,
  }) async {
    return _upload('raw', bytes, fileName, folder: folder);
  }

  static Future<String> _upload(
    String resourceType,
    Uint8List bytes,
    String fileName, {
    String? folder,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'Cloudinary upload preset is not configured. '
        'Create an unsigned upload preset and set CloudinaryService.uploadPreset.',
      );
    }

    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    if (folder != null && folder.isNotEmpty) {
      request.fields['folder'] = folder;
    }

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw Exception(
          'Cloudinary upload failed (${response.statusCode}): ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final url = json['secure_url'] ?? json['url'];
    if (url == null) {
      throw Exception('Cloudinary upload returned no URL');
    }
    return url as String;
  }
}
