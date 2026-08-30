import 'package:flutter/material.dart';
import '../services/app_update_service.dart';

/// Shows a modal "new update available" dialog. The user can download &
/// install now, or dismiss to keep using the current version.
Future<void> showAppUpdateDialog(BuildContext context, AppUpdateInfo info) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateDialog(info: info),
  );
}

class _UpdateDialog extends StatefulWidget {
  final AppUpdateInfo info;
  const _UpdateDialog({required this.info});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double _progress = 0;
  bool _downloading = false;
  bool _done = false;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
    });
    try {
      final path = await AppUpdateService.downloadApk(
        AppUpdateService.apkUrl,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      await AppUpdateService.installApk(path);
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = 'فشل التحميل: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: const Color(0xFF16161C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          const Icon(Icons.system_update_alt, color: Color(0xFFFFD700)),
          const SizedBox(width: 10),
          const Text('تحديث جديد متاح',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإصدار ${widget.info.version} (رقم البناء ${widget.info.build})',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            if (widget.info.notes != null &&
                widget.info.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(widget.info.notes!,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            if (_downloading) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white12,
                color: const Color(0xFFFFD700),
              ),
              const SizedBox(height: 8),
              Text('${(_progress * 100).toInt()}% — جاري التحميل...',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
            if (_done) ...[
              const SizedBox(height: 8),
              const Text('تم فتح مثبّت النظام، أكمل التثبيت من فضلك.',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        if (!_downloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لاحقاً',
                style: TextStyle(color: Colors.white54)),
          ),
        if (!_downloading && !_done)
          ElevatedButton(
            onPressed: _startUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('تحميل وتثبيت'),
          ),
        if (_done)
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('حسناً'),
          ),
      ],
    );
  }
}
