import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  // DeepSeek API key
  final String _apiKey = 'sk-21d757d8bea148d080aa80dbeffdebb1';
  final String _apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  @override
  void initState() {
    super.initState();
    // Add initial welcome message
    _messages.add({
      'sender': 'bot',
      'message': 'Hello! I\'m your plant assistant. How can I help you today?'
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    // Add haptic feedback
    HapticFeedback.lightImpact();

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add({
        'sender': 'user',
        'message': userMessage,
      });
      _isTyping = true;
      _messageController.clear();
    });

    try {
      // Prepare messages for DeepSeek API
      List<Map<String, String>> apiMessages = [
        {
          'role': 'system',
          'content':
              'You are a helpful plant assistant. You provide advice on plant care, '
                  'identification, gardening tips, and answer questions about plants. '
                  'Keep your responses focused on plants and gardening. '
                  'Be friendly, helpful, and concise in your responses.'
        }
      ];

      // Add conversation history
      for (var message in _messages) {
        String role = message['sender'] == 'user' ? 'user' : 'assistant';
        apiMessages.add({
          'role': role,
          'content': message['message'] ?? '',
        });
      }

      // Make API request
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': apiMessages,
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botResponse = data['choices'][0]['message']['content'];

        setState(() {
          _messages.add({
            'sender': 'bot',
            'message': botResponse,
          });
          _isTyping = false;
        });
      } else {
        // Parse error response
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to get response';

        // Check for specific error types
        if (response.statusCode == 402) {
          errorMessage =
              'API account has insufficient balance. Please check your DeepSeek account.';
        } else if (errorData.containsKey('error') &&
            errorData['error'].containsKey('message')) {
          errorMessage = errorData['error']['message'];
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = e.toString();
      // Clean up error message for display
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      setState(() {
        _messages.add({
          'sender': 'bot',
          'message': 'Sorry, I encountered an error: $errorMessage',
        });
        _isTyping = false;
      });
      print('DeepSeek API error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Assistant'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Ask me anything about plants!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        // Show typing indicator
                        return Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.green,
                              radius: 16,
                              child: Icon(
                                Icons.eco,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(
                                    width: 6,
                                    height: 6,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1,
                                      color: Colors.green,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Typing...'),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      final message = _messages[index];
                      final isBot = message['sender'] == 'bot';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: isBot
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.end,
                          children: [
                            if (isBot)
                              const CircleAvatar(
                                backgroundColor: Colors.green,
                                radius: 16,
                                child: Icon(
                                  Icons.eco,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isBot
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isBot
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                message['message'] ?? '',
                                style: TextStyle(
                                  color: isBot
                                      ? Colors.green[800]
                                      : Colors.blue[800],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!isBot)
                              const CircleAvatar(
                                backgroundColor: Colors.blue,
                                radius: 16,
                                child: Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Color(0xFFF3F3F3),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () => _sendMessage(),
                  backgroundColor: Colors.green,
                  mini: true,
                  elevation: 0,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
