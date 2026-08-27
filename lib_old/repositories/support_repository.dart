import '../models/chat_message.dart';

abstract class SupportRepository {
  Future<List<ChatMessage>> getChatHistory();
  Future<ChatMessage> sendMessage(ChatMessage message);
  Future<ChatMessage> getAIResponse(String userInput);
}
