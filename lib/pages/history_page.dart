import 'package:flutter/material.dart';
import 'chat_detail_page.dart';
import 'package:hive/hive.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  Map<String, dynamic> _chats = {};

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final chats = await getAllChats();
    setState(() {
      _chats = chats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติการแชท')),
      body: _chats.isEmpty
          ? const Center(child: Text('ยังไม่มีประวัติการแชท'))
          : ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chatId = _chats.keys.elementAt(index);
                final messages = _chats[chatId];
                final firstMessage = messages.isNotEmpty
                    ? messages.first['text'] ?? '[ข้อความไม่มีเนื้อหา]'
                    : '[ไม่มีข้อความ]';

                return ListTile(
                  title: Text('แชท #${index + 1}'),
                  subtitle: Text(firstMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await deleteChat(chatId);
                      _loadChats();
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailPage(chatId: chatId),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
Future<Map<String, dynamic>> getAllChats() async {
  final box = await Hive.openBox('chatBox');
  final Map<String, dynamic> chats = {};
  for (var key in box.keys) {
    chats[key] = box.get(key);
  }
  return chats;
}

// โค้ดที่แก้ไขเพื่อป้องกัน TypeError ขณะดึงข้อมูล
Future<List<Map<String, dynamic>>> getChatMessages(String chatId) async {
  final box = await Hive.openBox('chatBox');
  // 1. ดึงข้อมูล
  final rawList = box.get(chatId) as List<dynamic>?; 
  
  if (rawList == null) {
    return []; // คืนค่า list ว่างถ้าไม่พบ
  }

  // 2. แปลงแต่ละข้อความใน List 
  final List<Map<String, dynamic>> messages = rawList.map((msg) {
    if (msg is Map) {
      // ⚠️ สำคัญ: ใช้ .cast<String, dynamic>() เพื่อแปลง Map ของ Hive 
      final Map<String, dynamic> castedMsg = msg.cast<String, dynamic>();
      
      // 3. ตรวจสอบและแปลง textresult ภายในด้วย (ถ้ามี)
      if (castedMsg['textresult'] != null && castedMsg['textresult'] is Map) {
        castedMsg['textresult'] = (castedMsg['textresult'] as Map).cast<String, dynamic>();
      }
      
      return castedMsg;
    }
    return <String, dynamic>{};
  }).where((msg) => msg.isNotEmpty).toList(); 
  
  return messages;
}

Future<void> deleteChat(String chatId) async {
  final box = await Hive.openBox('chatBox');
  await box.delete(chatId);
}
