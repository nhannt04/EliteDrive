import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class ChatMessage {
  final String role; // "user" or "model"
  final String text;

  ChatMessage({required this.role, required this.text});

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'parts': [
        {'text': text}
      ]
    };
  }
}

class ChatbotProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add user message to history
    _messages.add(ChatMessage(role: 'user', text: text));
    _isLoading = true;
    notifyListeners();

    try {
      // 2. Format history payload
      final List<Map<String, dynamic>> historyJson = 
          _messages.map((msg) => msg.toJson()).toList();

      // 3. Query Backend `/api/v1/chatbot/chat`
      final response = await ApiClient.post(
        '/v1/chatbot/chat',
        body: {'history': historyJson},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = decoded['reply'] as String? ?? 'Xin lỗi, tôi không nhận được phản hồi.';
        
        // 4. Add model reply to history
        _messages.add(ChatMessage(role: 'model', text: reply));
      } else {
        _messages.add(ChatMessage(
          role: 'model',
          text: 'Lỗi kết nối máy chủ (${response.statusCode}). Vui lòng thử lại!',
        ));
      }
    } catch (e) {
      _messages.add(ChatMessage(
        role: 'model',
        text: 'Lỗi kết nối mạng: $e. Vui lòng kiểm tra lại đường truyền!',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}
