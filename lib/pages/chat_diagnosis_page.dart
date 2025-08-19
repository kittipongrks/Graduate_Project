import 'package:flutter/material.dart';
import 'package:dahcpplication/auth/database.dart';
import 'package:dahcpplication/controller/callinfermedicaapi.dart';
import 'package:dahcpplication/pages/riskfactor_page.dart'; // สำหรับการถามคำถามผู้ใช้ก่อนเริ่มแชท ??
import 'package:dahcpplication/pages/page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDiagnosisPage extends StatefulWidget {
  const ChatDiagnosisPage({super.key});

  @override
  State<ChatDiagnosisPage> createState() => ChatDiagnosis();
}

class ChatDiagnosis extends State<ChatDiagnosisPage> {
  double posXofDragButton = 300; 
  double posYofDragButton = 550;
  late final InfermedicaChatController _controller;
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  int age = defaultAge;
  String sex = defaultSex;

  @override
  void initState() {
    super.initState();
    _controller = InfermedicaChatController(service: InfermedicaService());
    _controller.addListener(_onControllerChanged);
    // Initial greeting
    _controller.addSystemMessage('สวัสดี! คุณมีอาการอะบ้างพิมพ์ระบุมาได้เลยครับ');
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    final document = await fetchUserInfo();
    if (document != null) {
      setState(() {
        age = document['age'];
        sex = document['sex'];
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
    // Scroll to bottom after rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendCurrentText() async {
    final txt = _textCtrl.text;
    _textCtrl.clear();
    await _controller.handleUserInput(txt);
  }


 void _DraggableButton(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          'ฟังก์ชันเพิ่มเติม',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3, // 3 คอลัมน์
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _buildFunctionButton(Icons.refresh, 'แชทใหม่', () {
                Navigator.pop(context);
              }),
              _buildFunctionButton(Icons.history, 'ประวัติ', () {
                Navigator.pop(context);
              }),
              _buildFunctionButton(Icons.location_pin, 'แผนที่', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyMapPage()),
                );
              }),
              _buildFunctionButton(Icons.person, 'โปรไฟล์', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountPage()),
                );
              }),
              _buildFunctionButton(Icons.settings, 'ตั้งค่า', () {
                Navigator.pop(context);
              }),
              _buildFunctionButton(Icons.exit_to_app, 'ออกระบบ', (){
                Navigator.pop(context);
                _exitAlertDialog(context);
              }),
              
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildFunctionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500 , color: Color.fromARGB(255, 0, 0, 0)),
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final msgs = _controller.messages;

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
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Chat messages
              Column(
                children: [
                  Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl, // ใช้ _scrollCtrl เหมือนเดิม
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length, // ใช้ msgs.length เหมือนเดิม
                  itemBuilder: (context, i) {
                    final m = msgs[i]; // ใช้ m = msgs[i] เหมือนเดิม
                    final isMe = m.sender == ChatSender.user; // กำหนด isMe จาก m.sender
                    final color = switch (m.sender) { // ใช้ color switch เหมือนเดิม
                      ChatSender.user => Colors.green.shade100, // เปลี่ยนสีตามตัวอย่าง
                      ChatSender.bot => Colors.blue.shade100, // เปลี่ยนสีตามตัวอย่าง
                      ChatSender.system => Colors.blue.shade100,
                      ChatSender.error => Colors.red.shade200,
                    };

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
                                  backgroundColor: Color(0xFFBDBDBD), // ใช้สีเทาอ่อน
                                  backgroundImage: AssetImage('assets/images/Doctor_image_1per1.png'), // หากมีรูปภาพ
                                ),
                              ),
                            Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(15),
                                  topRight: const Radius.circular(15),
                                  bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : const Radius.circular(15),
                                ),
                              ),
                              child: Text(
                                m.text, // ใช้ m.text เหมือนเดิม
                                style: const TextStyle(fontSize: 16, color: Colors.black87), // ใช้สีดำเข้ม
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_controller.isBusy) // ใช้ _controller.isBusy เหมือนเดิม
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
              // Input box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl, // ใช้ _textCtrl เหมือนเดิม
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendCurrentText(), // ใช้ _sendCurrentText() เหมือนเดิม
                    decoration: InputDecoration(
                      hintText: "พิมพ์ข้อความของคุณ...",
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface, // ใช้สีพื้นหลังของ Theme
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
                  onPressed: _sendCurrentText, // ใช้ _sendCurrentText() เหมือนเดิม
                ),
              ],
            ),
          ),
              ],
              ),
              
          // ปุ่มที่ลากได้
          
          Positioned(
            left: posXofDragButton,
            top: posYofDragButton,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  posXofDragButton += details.delta.dx;
                  posYofDragButton += details.delta.dy;

                  final containerWidth = MediaQuery.of(context).size.width - 16; // padding 16x2
                  final containerHeight = MediaQuery.of(context).size.height - 16;

                  posXofDragButton = posXofDragButton.clamp(0.0, containerWidth - 50);
                  posYofDragButton = posYofDragButton.clamp(0.0, containerHeight - 200);
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: IconButton(
                  icon : Icon(Icons.add),
                  onPressed: (){
                    _DraggableButton(context);
                  },
                ),
              ),
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

void _exitAlertDialog(BuildContext context){
  showDialog(context: context, builder: 
  (BuildContext context){
    return AlertDialog(
      title: const Text('ออกจากระบบ' , style: TextStyle(fontSize: 20 , fontWeight: FontWeight.bold)),
      content: const Text('ต้องการออกจากระบบหรือไม่?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('ไม่'),
        ),
        TextButton(
          onPressed: () async{
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pop();
          },
          child: const Text('ใช่'),
        ),
      ],
    );
  },
  );
}