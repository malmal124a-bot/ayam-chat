import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../utils/image_utils.dart';
import '../services/supabase_service.dart';

/// Central service for resolving SVGA asset paths to CDN URLs
/// with automatic disk caching for offline playback.
///
/// Strategy:
/// 1. Remote URL (http/https) → return as-is (already resolved by DB)
/// 2. Known local asset → check Supabase `svga_url_overrides` config table,
///    fall back to disk cache, then to original asset path
/// 3. Unknown path → return original (graceful fallback)
class SvgaAssetService {
  SvgaAssetService._();
  static final SvgaAssetService instance = SvgaAssetService._();

  /// In-memory override map loaded from Supabase `svga_url_overrides` table.
  /// Key = local asset path, Value = remote CDN URL
  Map<String, String> _overrides = {};

  /// Preview image URLs from the same table (local_path → preview_image_url)
  Map<String, String> _previewUrls = {};

  /// Display names from the same table (local_path → display_name)
  Map<String, String> _displayNames = {};

  bool _loaded = false;

  Directory? _cacheDir;

  /// Loads URL overrides from Supabase `svga_url_overrides` table.
  /// Call this once at startup (non-blocking).
  Future<void> loadOverrides() async {
    if (_loaded) return;
    try {
      final rows = await SupabaseService.client
          .from('svga_url_overrides')
          .select('local_path, remote_url, preview_image_url, display_name');
      final overrides = <String, String>{};
      final previews = <String, String>{};
      final names = <String, String>{};
      for (final row in rows) {
        final local = row['local_path']?.toString();
        final remote = row['remote_url']?.toString();
        if (local != null && remote != null && remote.isNotEmpty) {
          overrides[local] = remote;
        }
        if (local != null) {
          final preview = row['preview_image_url']?.toString();
          if (preview != null && preview.isNotEmpty) previews[local] = preview;
          final name = row['display_name']?.toString();
          if (name != null && name.isNotEmpty) names[local] = name;
        }
      }
      _overrides = overrides;
      _previewUrls = previews;
      _displayNames = names;
      _loaded = true;
    } catch (e) {
      debugPrint('SvgaAssetService: Failed to load overrides from DB: $e');
      _loaded = true; // Don't retry on every call
    }
  }

  Future<Directory> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationCacheDirectory();
    _cacheDir = Directory('${appDir.path}/svga_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  String _normalizeAssetPath(String path) {
    var clean = path.trim();
    while (clean.startsWith('assets/assets/')) {
      clean = clean.replaceFirst('assets/assets/', 'assets/');
    }
    if (!clean.startsWith('assets/') && !clean.startsWith('http')) {
      clean = 'assets/$clean';
    }
    return clean;
  }

  /// Gets the preview image URL for a given local asset path (if available).
  String? getPreviewUrl(String localPath) => _previewUrls[localPath];

  /// Gets the display name for a given local asset path (if available).
  String? getDisplayName(String localPath) => _displayNames[localPath];

  /// Resolves any SVGA path (local asset or remote) to a playable path.
  ///
  /// Resolution order:
  /// 1. Already HTTP URL → return as-is
  /// 2. Override map (from DB) → download + cache → return local file path
  /// 3. No override found → return normalized local asset path (may fail)
  Future<String> resolve(String path) async {
    final trimmed = path.trim();

    // Already a remote URL — return as-is
    if (ImageUtils.isHttpUrl(trimmed)) return trimmed;

    final cleanPath = _normalizeAssetPath(trimmed);

    // Ensure overrides are loaded
    if (!_loaded) await loadOverrides();

    // Check override map from DB
    final remoteUrl = _overrides[cleanPath];
    if (remoteUrl == null) return cleanPath; // No override — fallback to asset

    // Check disk cache
    final cacheDir = await _getCacheDir();
    final cacheKey = cleanPath.replaceAll(RegExp(r'[^\w\-\.]'), '_');
    final cachedFile = File('${cacheDir.path}/$cacheKey.svga');
    if (await cachedFile.exists()) {
      return cachedFile.path;
    }

    // Download from CDN and cache
    try {
      final response = await http.get(Uri.parse(remoteUrl)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        await cachedFile.parent.create(recursive: true);
        await cachedFile.writeAsBytes(response.bodyBytes);
        return cachedFile.path;
      }
    } catch (e) {
      debugPrint('SvgaAssetService: CDN download failed for $cleanPath: $e');
    }

    // Fallback to local asset
    return cleanPath;
  }

  /// Pre-downloads all overridden SVGA files to disk cache in background.
  Future<void> preCacheAll() async {
    if (!_loaded) await loadOverrides();
    if (_overrides.isEmpty) return;

    final cacheDir = await _getCacheDir();
    for (final entry in _overrides.entries) {
      final cacheKey = entry.key.replaceAll(RegExp(r'[^\w\-\.]'), '_');
      final cachedFile = File('${cacheDir.path}/$cacheKey.svga');
      if (await cachedFile.exists()) continue;

      try {
        final response = await http.get(Uri.parse(entry.value)).timeout(const Duration(seconds: 20));
        if (response.statusCode == 200) {
          await cachedFile.parent.create(recursive: true);
          await cachedFile.writeAsBytes(response.bodyBytes);
        }
      } catch (_) {}
    }
  }

  /// Clears the entire SVGA disk cache.
  Future<void> clearCache() async {
    final cacheDir = await _getCacheDir();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
    _cacheDir = null;
  }
}
