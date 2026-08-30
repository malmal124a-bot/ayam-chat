import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// Checks GitHub release `latest-apk` for a `version.json` describing the
/// newest build, and downloads/installs the APK when a newer one exists.
class AppUpdateService {
  static const String _versionJsonUrl =
      'https://github.com/malmal124a-bot/ayam-chat/releases/download/latest-apk/version.json';

  static const String apkUrl =
      'https://github.com/malmal124a-bot/ayam-chat/releases/download/latest-apk/app-release.apk';

  /// Returns update info if a newer build is published, otherwise null.
  static Future<AppUpdateInfo?> checkForUpdate() async {
    if (!Platform.isAndroid) return null;
    try {
      final res = await http
          .get(Uri.parse(_versionJsonUrl))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final info = AppUpdateInfo.fromJson(json);
      if (info.build <= 0) return null;

      final pkg = await PackageInfo.fromPlatform();
      final localBuild = int.tryParse(pkg.buildNumber) ?? 0;
      if (info.build > localBuild) return info;
      return null;
    } catch (e) {
      // Network/parse errors are non-fatal: just don't prompt.
      return null;
    }
  }

  /// Downloads the APK to a temp file, reporting progress 0..1.
  static Future<String> downloadApk(
    String url, {
    required void Function(double progress) onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/app-release-update.apk';
    final file = File(filePath);
    if (await file.exists()) await file.delete();

    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request);
    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = file.openWrite();
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }
    } finally {
      await sink.flush();
      await sink.close();
      client.close();
    }
    onProgress(1.0);
    return filePath;
  }

  /// Opens the system installer for the downloaded APK.
  static Future<void> installApk(String path) async {
    await OpenFilex.open(path);
  }
}

class AppUpdateInfo {
  final String version;
  final int build;
  final String? notes;

  AppUpdateInfo({
    required this.version,
    required this.build,
    this.notes,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      version: (json['version'] ?? '1.0.0').toString(),
      build: (json['build'] is int)
          ? json['build'] as int
          : int.tryParse(json['build']?.toString() ?? '') ?? 0,
      notes: json['notes']?.toString(),
    );
  }
}
