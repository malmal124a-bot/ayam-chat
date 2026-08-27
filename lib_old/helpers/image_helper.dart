import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageHelper {
  /// Convert image file to Base64 string
  static Future<String?> imageToBase64(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/${imageFile.mimeType ?? 'jpeg'};base64,$base64String';
    } catch (e) {
      debugPrint('Error converting image to Base64: $e');
      return null;
    }
  }

  /// Convert image file path to Base64 string
  static Future<String?> imagePathToBase64(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final extension = imagePath.split('.').last.toLowerCase();
      return 'data:image/$extension;base64,$base64String';
    } catch (e) {
      debugPrint('Error converting image path to Base64: $e');
      return null;
    }
  }

  /// Convert web image bytes to Base64 string
  static String? webBytesToBase64(List<int> bytes, String mimeType) {
    try {
      final base64String = base64Encode(bytes);
      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      debugPrint('Error converting web bytes to Base64: $e');
      return null;
    }
  }

  /// Upload image to Firebase Storage and return download URL
  static Future<String?> uploadToFirebaseStorage(XFile imageFile, String path) async {
    try {
      final storage = FirebaseStorage.instance;
      final ref = storage.ref().child(path);
      
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        final uploadTask = ref.putData(bytes);
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      } else {
        final file = File(imageFile.path);
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Error uploading to Firebase Storage: $e');
      return null;
    }
  }

  /// Check if string is Base64 image
  static bool isBase64Image(String? value) {
    if (value == null) return false;
    return value.startsWith('data:image/') && value.contains(';base64,');
  }

  /// Safe Base64 image decoder for Flutter Web compatibility
  /// Strips data URI prefix and decodes Base64 string to bytes
  static Uint8List? decodeBase64Image(String base64String) {
    try {
      // Remove data URI prefix if present (e.g., data:image/png;base64,)
      String cleanedBase64 = base64String;
      if (base64String.startsWith('data:image/')) {
        final lastIndex = base64String.indexOf(',');
        if (lastIndex != -1) {
          cleanedBase64 = base64String.substring(lastIndex + 1);
        }
      }
      
      // Decode Base64 to bytes
      final bytes = base64Decode(cleanedBase64);
      return bytes;
    } catch (e) {
      debugPrint('Error decoding Base64 image: $e');
      return null;
    }
  }

  /// Get ImageProvider from various image sources with safe Base64 handling
  static ImageProvider getImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const AssetImage('assets/Asad/room.jpg');
    }

    // Check if it's a Base64 image
    if (isBase64Image(imagePath)) {
      final bytes = decodeBase64Image(imagePath);
      if (bytes != null) {
        return MemoryImage(bytes);
      }
      // Fallback if decoding fails
      return const AssetImage('assets/Asad/room.jpg');
    }

    // Check if it's a network URL (including Firebase Storage URLs)
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CachedNetworkImageProvider(imagePath);
    }

    // Check if it's an asset
    if (imagePath.startsWith('assets/')) {
      return AssetImage(imagePath);
    }

    // Default fallback
    return const AssetImage('assets/Asad/room.jpg');
  }

  /// Build image widget with safe Base64 handling and error fallback
  static Widget buildSafeImage({
    required String? imagePath,
    BoxFit? fit,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (imagePath != null && (imagePath.startsWith('http://') || imagePath.startsWith('https://'))) {
      // Use CachedNetworkImage for network/Firebase Storage URLs
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: fit ?? BoxFit.cover,
        width: width,
        height: height,
        placeholder: (context, url) => placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        errorWidget: (context, url, error) => errorWidget ??
            placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.withValues(alpha: 0.3),
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
      );
    }

    return Image(
      image: getImageProvider(imagePath),
      fit: fit ?? BoxFit.cover,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.withValues(alpha: 0.3),
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
    );
  }
}
