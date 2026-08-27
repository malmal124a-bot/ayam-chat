import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
// import 'package:record/record.dart'; // Removed for dependency cleanup
import '../models/chat_message.dart';
import '../repositories/support_repository.dart';
import '../repositories/local_support_repository.dart';

class SupportController extends ChangeNotifier {
  static final SupportController _instance = SupportController._internal();
  factory SupportController() => _instance;

  final SupportRepository _repository;
  final FlutterTts _flutterTts = FlutterTts();
  // final AudioRecorder _audioRecorder = AudioRecorder(); // Removed for dependency cleanup

  SupportController._internal() : _repository = LocalSupportRepository() {
    print('Initializing: SupportController');
    _loadMessages();
    _initTts();
  }

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ar-SA");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _loadMessages() async {
    _isLoading = true;
    notifyListeners();
    _messages = await _repository.getChatHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      type: MessageType.text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    await _repository.sendMessage(userMsg);
    _messages.add(userMsg);
    notifyListeners();

    _getAIResponse(text);
  }

  Future<void> sendMediaMessage({
    String? text,
    required MessageType type,
    String? path,
    Uint8List? bytes,
    String? fileName,
  }) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      type: type,
      isUser: true,
      timestamp: DateTime.now(),
      mediaPath: path,
      mediaBytes: bytes,
      fileName: fileName,
    );

    await _repository.sendMessage(userMsg);
    _messages.add(userMsg);
    notifyListeners();

    _getAIResponse("User sent a ${type.name}");
  }

  Future<void> startRecording() async {
    // Recording disabled for dependency cleanup
    debugPrint("Recording is temporarily disabled.");
    /*
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        const config = RecordConfig();
        await _audioRecorder.start(config, path: path);
        _isRecording = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
    */
  }

  Future<void> stopRecording() async {
    // Recording disabled for dependency cleanup
    _isRecording = false;
    notifyListeners();
    /*
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      notifyListeners();

      if (path != null) {
        await sendMediaMessage(
          type: MessageType.audio,
          path: path,
        );
      }
    } catch (e) {
      debugPrint("Error stopping recording: $e");
      _isRecording = false;
      notifyListeners();
    }
    */
  }

  Future<void> _getAIResponse(String input) async {
    final aiResponse = await _repository.getAIResponse(input);
    _messages.add(aiResponse);
    notifyListeners();
    
    if (aiResponse.text != null) {
      speak(aiResponse.text!);
    }
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  @override
  void dispose() {
    // _audioRecorder.dispose(); // Removed for dependency cleanup
    _flutterTts.stop();
    super.dispose();
  }
}
