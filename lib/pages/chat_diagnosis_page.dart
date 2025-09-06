import 'package:dahcpplication/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:dahcpplication/auth/database.dart';
import 'package:dahcpplication/controller/callinfermedicaapi.dart';
import 'package:dahcpplication/pages/riskfactor_page.dart'; // สำหรับการถามคำถามผู้ใช้ก่อนเริ่มแชท ??
import 'package:dahcpplication/pages/page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:dahcpplication/controller/gemini_generate.dart';

class ChatDiagnosisPage extends StatefulWidget {
  const ChatDiagnosisPage({super.key});

  @override
  State<ChatDiagnosisPage> createState() => _ChatDiagnosisState();
}

class _ChatDiagnosisState extends State<ChatDiagnosisPage> {
  InfermedicaChatController? _controller; // เปลี่ยนเป็น nullable
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  int? age;
  String? sex;
  String? foodAllergies;
  String? medicalConditions;

  bool _showSuggestionButtons = false;
  bool _isDataLoaded = false;
  

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    print("try to load userinfo");
    final document = await fetchUserInfo();
    if (document != null) {
      age = document['age'];
      sex = document['sex'];
      foodAllergies = document['foodAllergies'];
      medicalConditions = document['medicalConditions'];
      print("load UserInfo success: $age, $sex, $foodAllergies, $medicalConditions");
    } else {
      print("No user data found, using default values.");
      age = defaultAge;
      sex = defaultSex;
    }

    _controller = InfermedicaChatController(
      service: InfermedicaService(),
      age: age,
      sex: sex,
      foodAllergies: foodAllergies,
      medicalConditions: medicalConditions,
    );

    _controller!.addListener(_onControllerChanged);
    _controller!.addSystemMessage(
      'สวัสดี! ช่วยบอกเราเกี่ยวกับอาการทั้งหมดที่คุณกำลังเป็น แบบยาว ๆ หน่อยนะครับ\nจะได้ช่วยประเมินได้แม่นยำขึ้น'
    );

    setState(() {
      _isDataLoaded = true;
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
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
    await _controller?.handleUserInput(txt);
  }
  void _DraggableButton(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            const Text(
              'ฟังก์ชันเพิ่มเติม',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // IconButton(
            //   onPressed: (){
            //   themeProvider.toggleTheme();
            // }, 
            //   icon: Icon(themeProvider.currentTheme == AppTheme.light 
            // ? Icons.light_mode
            // : Icons.dark_mode)),
          ],
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


  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded || _controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final msgs = _controller!.messages;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 10),
            const Text(
              "Diagnosis",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              onPressed: () {
                _DraggableButton(context);
              },
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: msgs.length,
                        itemBuilder: (context, i) {
                          final m = msgs[i];
                          final isMe = m.sender == ChatSender.user;

                          Widget content;
                          switch (m.type) {
                            case MessageType.text:
                              content = Text(
                                m.text ?? "",
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                              );
                              break;

                            case MessageType.card:
                              content = _buildCardMessage(m.textreuslt ?? {});
                              break;

                            case MessageType.chart:
                              content = _buildChartMessage(m.textreuslt ?? {});
                              break;
                          }
                          final color = switch (m.sender) {
                            ChatSender.user => [const Color(0xFF50A4E4), const Color(0xFF7F95DB)],
                            ChatSender.bot => [Colors.grey[200]!, Colors.grey[200]!],
                            ChatSender.system => [Colors.grey[200]!, Colors.grey[200]!],
                            ChatSender.error => [Colors.red[400]!, Colors.red[600]!],
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
                                        backgroundColor: Color(0xFFBDBDBD),
                                        backgroundImage: AssetImage('assets/images/Doctor_image_1per1.png'),
                                      ),
                                    ),
                                  Container(
                                    constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context).size.width * 0.7),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: color,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(20),
                                        topRight: const Radius.circular(20),
                                        bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(10),
                                        bottomRight: isMe ? const Radius.circular(10) : const Radius.circular(20),
                                      ),
                                    ),
                                    child: content,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_controller!.isBusy)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    _buildQuickAnswerButtons(),
                    _buildInputBox(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAnswerButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildTextButton('ใช่', () {
            _textCtrl.text = "ใช่";
            _sendCurrentText();
          }),
          const SizedBox(width: 8),
          _buildTextButton('ไม่ใช่', () {
            _textCtrl.text = "ไม่ใช่";
            _sendCurrentText();
          }),
          const SizedBox(width: 8),
          _buildTextButton('อาจจะ', () {
            _textCtrl.text = "อาจจะ";
            _sendCurrentText();
          }),
        ],
      ),
    );
  }

  Widget _buildInputBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inversePrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.blue),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendCurrentText(),
              decoration: InputDecoration(
                hintText: "พิมพ์ข้อความของคุณ...",
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ClipOval(
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF50A4E4), Color(0xFF7F95DB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () {
                  _sendCurrentText();
                },
              ),
            ),
          ),
        ],
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

Widget _buildTextButton(String text, VoidCallback onPressed) {
  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: Colors.blue, // สีข้อความ
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      backgroundColor: Colors.blue.withOpacity(0.1), // สีพื้นหลังจางๆ
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.blue), // เส้นขอบ
      ),
    ),
    child: Text(text),
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

  Widget _buildCardMessage(Map<String, dynamic> data) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(data["title"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text("มูลค่า: ${data["aum"] ?? "-"}"),
      Text("กำไร/ขาดทุน: ${data["profit"] ?? "-"}"),
    ],
  );
}

Widget _buildChartMessage(Map<String, dynamic> data) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("📊 Chart Example"),
      Text("Labels: ${data["labels"]}"),
      Text("Values: ${data["values"]}"),
    ],
  );
}
