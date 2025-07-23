import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dahcpplication/controller/controller.dart';
import 'package:dahcpplication/controller/infermedica_api.dart';
import 'package:dahcpplication/auth/database.dart';
import 'package:dahcpplication/controller/accessapi.dart';

class ChatDiagnosisPage extends StatefulWidget{
  const ChatDiagnosisPage({super.key});

  @override
  State<ChatDiagnosisPage> createState() => _ChatDiagnosisPageState();
}

  class _ChatDiagnosisPageState extends State<ChatDiagnosisPage> {
    final TextEditingController _messageController = TextEditingController();
    final List<Map<String, dynamic>> _messages = [];
    bool _isLoading = false;

    @override
    void initState(){
      super.initState();
      _messages.add({
        'text':'สวัสดีครับ วันนี้มีอาการอะไรบ้างช่วยระบุอาการของคุณมาได้เลย',
        'isMe': false,
      });
    }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Row(
          children: [
            const SizedBox(width: 10),
            const Text(
              "Diagnosis",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Chat messages
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final isMe = _messages[index]['isMe'] as bool;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6.0),
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey,
                                    backgroundImage: AssetImage('assets/images/Doctor_image_1per1.png'),
                                  ),
                                ),
                              Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.green[100] : Colors.blue[100],
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(15),
                                    topRight: const Radius.circular(15),
                                    bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
                                    bottomRight: isMe ? Radius.zero : const Radius.circular(15),
                                  ),
                                ),
                                child: Text(
                                  _messages[index]['text'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
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

                // Input box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: "พิมพ์ข้อความของคุณ...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () async {
                          if (_messageController.text.trim().isNotEmpty && !_isLoading) {
                            final userMessage = _messageController.text.trim();
                            setState(() {
                              _messages.add({'text': userMessage, 'isMe': true});
                              _isLoading = true;
                              _messageController.clear();
                            });

                            try {
                              final document = await fetchUserInfo();
                              final age = document['age'];
                              final sex = document['sex'];
                              final userMessageEng = await llmsChangeThaiToEng(userMessage);
                              final apiInfo = await getApiInfermedica();
                              final appId = apiInfo['appId'];
                              final appKey = apiInfo['appKey'];
                              final case_id = await new_case_id();
                              print(age);
                              print(sex);
                              print("appId : $appId");
                              print("appKey : $appKey");
                              print("User : $case_id");
                              final mentions = await read_complaints(
                              age,
                              sex,
                              appId,
                              appKey,
                              case_id,
                              userMessageEng,
                            );
                              final evidence = await mentionsToEvidence(mentions);
                              final infermedicaMessage = await conduct_interview(
                                evidence,
                                age,
                                sex,
                                case_id,
                                appId,
                                appKey,
                                );
                              
                               //Call Infermedica API 
                              setState(() {
                                _messages.add({'text': infermedicaMessage, 'isMe': false});
                              });
                            } catch (e) {
                              setState(() {
                                _messages.add({'text': 'เกิดข้อผิดพลาดจริงๆ : $e', 'isMe': false});
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
          ),
        ),
      ),
    );
  }
}