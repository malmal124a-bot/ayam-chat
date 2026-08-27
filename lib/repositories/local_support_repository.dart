import '../models/chat_message.dart';
import 'support_repository.dart';

class LocalSupportRepository implements SupportRepository {
  final List<ChatMessage> _messages = [];

  @override
  Future<List<ChatMessage>> getChatHistory() async {
    return List.from(_messages);
  }

  @override
  Future<ChatMessage> sendMessage(ChatMessage message) async {
    _messages.add(message);
    return message;
  }

  @override
  Future<ChatMessage> getAIResponse(String userInput) async {
    await Future.delayed(const Duration(seconds: 1));
    final response = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: "شكراً لتواصلك مع مركز الدعم الذكي. كيف يمكنني مساعدتك اليوم؟",
      type: MessageType.text,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(response);
    return response;
  }
}
