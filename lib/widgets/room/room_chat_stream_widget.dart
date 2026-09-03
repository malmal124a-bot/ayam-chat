import 'package:flutter/material.dart';
import 'dart:io';
import '../../controllers/room_ui_controller.dart';
import '../app_icon.dart';

class RoomChatStreamWidget extends StatelessWidget {
  final List<RoomMessage> messages;
  final ScrollController scrollController;
  final VoidCallback onJoinMic;

  const RoomChatStreamWidget({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.onJoinMic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: ListView.builder(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          return _buildChatMessage(context, msg);
        },
      ),
    );
  }

  Widget _buildChatMessage(BuildContext context, RoomMessage msg) {
    final bool isSystem = msg.type == RoomMessageType.system;
    final bool isGift = msg.type == RoomMessageType.gift;
    final bool isImage = msg.type == RoomMessageType.image;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSystem 
            ? Colors.amber.withValues(alpha: 0.15) 
            : isGift 
              ? Colors.pink.withValues(alpha: 0.1) 
              : Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: isSystem 
            ? Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 0.5) 
            : null,
        ),
        child: isImage 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "${msg.senderName} ",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Lv.${msg.senderLevel}',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (msg.imageUrl!.startsWith('http://') ||
                              msg.imageUrl!.startsWith('https://'))
                          ? Image.network(
                              msg.imageUrl!,
                              width: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const AppIcon('Icons.broken_image', icon: Icons.broken_image, color: Colors.white54, size: 50);
                              },
                            )
                          : Image.file(
                              File(msg.imageUrl!),
                              width: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const AppIcon('Icons.broken_image', icon: Icons.broken_image, color: Colors.white54, size: 50);
                              },
                            ),
                    ),
                ],
              )
            : RichText(
                text: TextSpan(
                  children: [
                    if (!isSystem) ...[
                      TextSpan(
                        text: "${msg.senderName} ",
                        style: TextStyle(
                          color: isGift ? Colors.pinkAccent : Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      WidgetSpan(
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Lv.${msg.senderLevel}',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const TextSpan(text: " "),
                    ],
                    _buildMessageText(msg.text, isSystem, isGift),
                  ],
                ),
                textAlign: TextAlign.right,
              ),
      ),
    );
  }

  TextSpan _buildMessageText(String text, bool isSystem, bool isGift) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'@(\w+)');
    
    final TextStyle defaultStyle = TextStyle(
      color: isSystem ? Colors.amber : (isGift ? Colors.white : Colors.white.withValues(alpha: 0.95)),
      fontSize: 13,
      fontFamily: 'Cairo',
      fontWeight: isSystem ? FontWeight.bold : FontWeight.normal,
    );

    int lastMatchEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: defaultStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(0)!,
        style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
      ));
      lastMatchEnd = match.end;
    }
    
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: defaultStyle,
      ));
    }
    
    return TextSpan(children: spans);
  }
}
