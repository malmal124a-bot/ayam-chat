import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../controllers/support_controller.dart';
import '../models/chat_message.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await context.read<SupportController>().sendMediaMessage(
        type: MessageType.image,
        path: image.path,
      );
      _scrollToBottom();
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (video != null) {
      await context.read<SupportController>().sendMediaMessage(
        type: MessageType.video,
        path: video.path,
      );
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider.value(
      value: SupportController(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('help_center'.tr(), style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: theme.iconTheme,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.volume_off_outlined),
              onPressed: () => context.read<SupportController>().stopSpeaking(),
              tooltip: "إيقاف الصوت",
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<SupportController>(
                builder: (context, controller, child) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final msg = controller.messages[index];
                      return _buildMessageBubble(msg);
                    },
                  );
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final theme = Theme.of(context);
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: msg.isUser ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 0),
            bottomRight: Radius.circular(msg.isUser ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isUser)
               Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy_outlined, size: 16, color: theme.colorScheme.secondary),
                    const SizedBox(width: 6),
                    Text("AI Assistant", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                  ],
                ),
              ),
            _buildMessageContent(theme, msg),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('HH:mm').format(msg.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: msg.isUser ? theme.colorScheme.onPrimary.withValues(alpha: 0.7) : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(ThemeData theme, ChatMessage msg) {
    final textColor = msg.isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    switch (msg.type) {
      case MessageType.text:
        return Text(msg.text ?? "", style: TextStyle(color: textColor, fontSize: 15, height: 1.4));
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: msg.mediaPath != null 
            ? (kIsWeb || msg.mediaPath!.startsWith('http') || msg.mediaPath!.startsWith('blob:')
                ? Image.network(msg.mediaPath!, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                : Image.file(File(msg.mediaPath!), errorBuilder: (c, e, s) => const Icon(Icons.broken_image)))
            : Icon(Icons.broken_image, color: theme.colorScheme.onSurface),
        );
      case MessageType.video:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Text("فيديو مرفق", style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
          ],
        );
      case MessageType.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.audiotrack, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Text("تسجيل صوتي", style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInputArea() {
    final theme = Theme.of(context);
    return Consumer<SupportController>(
      builder: (context, controller, child) {
        return Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            top: 12,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              _buildInputButton(Icons.image_outlined, _pickImage),
              _buildInputButton(Icons.videocam_outlined, _pickVideo),
              _buildInputButton(
                controller.isRecording ? Icons.mic : Icons.mic_none, 
                () {
                  if (controller.isRecording) {
                    controller.stopRecording();
                    _scrollToBottom();
                  } else {
                    controller.startRecording();
                  }
                },
                color: controller.isRecording ? theme.colorScheme.error : theme.colorScheme.onSurface,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: TextField(
                    controller: _messageController,
                    enabled: !controller.isRecording,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: controller.isRecording ? 'جاري التسجيل...' : 'message'.tr(),
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.primaryColor,
                child: IconButton(
                  icon: Icon(Icons.send, color: theme.colorScheme.secondary, size: 22),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputButton(IconData icon, VoidCallback onPressed, {Color? color}) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(icon, color: color ?? theme.colorScheme.onSurface),
      onPressed: onPressed,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    SupportController().sendTextMessage(_messageController.text);
    _messageController.clear();
    _scrollToBottom();
  }
}
