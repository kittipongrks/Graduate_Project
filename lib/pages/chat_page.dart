import 'package:flutter/material.dart';
import 'package:dahcpplication/controller/controller.dart';

class MyChatPage extends StatefulWidget {
  const MyChatPage({super.key});

  @override
  State<MyChatPage> createState() => _MyChatPageState();
}

class _MyChatPageState extends State<MyChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.person, size: 30),
            const SizedBox(width: 8),
            const Text("Doctor"),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isMe = _messages[index]['isMe'] as bool;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.green[100] : Colors.blue[100],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
                        bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                      ),
                    ),
                    child: Text(_messages[index]['text']),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                  // เมื่อมีการกดปุ่มส่งข้อความ
                  onPressed: () async {
                    if (_messageController.text.trim().isNotEmpty && !_isLoading) {
                      final userMessage = _messageController.text.trim();
                      setState(() {
                        _messages.add({
                          'text': userMessage,
                          'isMe': true,
                        });
                        _isLoading = true;
                        _messageController.clear();
                      });

                      try {
                        final geminiReply = await callGemini(userMessage).timeout(
                          const Duration(seconds: 10),
                          onTimeout: () => 'เกิดข้อผิดพลาด: Gemini ใช้เวลาตอบนานเกินไป',
                        );

                        setState(() {
                          _messages.add({
                            'text': geminiReply,
                            'isMe': false,
                          });
                        });
                      } catch (e) {
                        setState(() {
                          _messages.add({
                            'text': 'เกิดข้อผิดพลาด: $e',
                            'isMe': false,
                          });
                        });
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}