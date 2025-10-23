import 'package:dahcpplication/pages/history_page.dart';
import 'package:dahcpplication/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:dahcpplication/auth/database.dart';
import 'package:dahcpplication/controller/callinfermedicaapi.dart';
import 'package:dahcpplication/pages/page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
class ChatDiagnosisPage extends StatefulWidget {
  const ChatDiagnosisPage({super.key});

  @override
  State<ChatDiagnosisPage> createState() => _ChatDiagnosisState();
}

class _ChatDiagnosisState extends State<ChatDiagnosisPage> {
  InfermedicaChatController? _controller;
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  int? age;
  String? sex;
  String? foodAllergies;
  String? medicalConditions;
  String lat = '';
  String long = '';

  final bool _showSuggestionButtons = false;
  bool _isDataLoaded = false;
  

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    final document = await fetchUserInfo();
    if (document != null) {
      age = document['age'];
      sex = document['sex'];
      foodAllergies = document['foodAllergies'];
      medicalConditions = document['medicalConditions'];
    } else {
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
      'สวัสดี!'
    );
    _controller!.addSystemMessage(
      'วันเจอเรื่องอะไรมา หรือมีอาการอะไรเล่ามาได้เลยครับ'
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
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _buildFunctionButton(Icons.refresh, 'แชทใหม่', () {
                _controller?.resetChat();
                Navigator.pop(context);
              }),
              _buildFunctionButton(Icons.local_hospital_outlined, 'ค้นหาโรงพยาบาล', () {
                Navigator.pop(context);
                findNearbyHospitals();
              }),
              _buildFunctionButton(Icons.person, 'โปรไฟล์', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountPage()),
                );
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
                _DraggableButton(context
                );
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
                              content = 
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  m.text ?? "",
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                ),
                              );
                              break;

                            case MessageType.cardEvidence:
                              content = _buildCardMessageEvidence(m.textresult ?? {});
                              break;
                            case MessageType.cardDiagnosis:
                              content = _buildCardMessageDiagnosis(m.textresult ?? {});
                              break;
                            case MessageType.cardSuggest:
                              content = _buildCardMessageSuggest(m.textresult ?? {});
                              break;
                            case MessageType.cardMedicine:  
                              content = _buildCardMessageMedicine(m.textresult ?? {});
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
                                  Container(
                                    constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context).size.width * 0.8),
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
 
Widget _buildCardMessageEvidence(Map<String, dynamic> data) {
  final evidences = (data['evidences'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  // แยกตาม choice
  final supporting = evidences.where((e) => e["choice"] == "present").toList();
  final conflicting = evidences.where((e) => e["choice"] == "absent").toList();
  final unconfirmed = evidences.where((e) => e["choice"] == "unknown").toList();

  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data["title"] ?? "ข้อมูลอาการ",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),

          // Supporting evidence
          if (supporting.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...supporting.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Text("+ ",
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(e["common_name"] ?? "-"),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],

          // Conflicting evidence
          if (conflicting.isNotEmpty) ...[
            ...conflicting.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Text("- ",
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(e["common_name"] ?? "-"),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],

          // Unconfirmed evidence
          if (unconfirmed.isNotEmpty) ...[
            ...unconfirmed.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Text("? ",
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(e["common_name"] ?? "-"),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],

          const Divider(),
          const Text(
            "(นี่คือข้อมูลที่ใช้ในการประเมินอัตโนมัติ)",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}


Widget _buildCardMessageDiagnosis(Map<String, dynamic> data) {
  final conditions = (data['conditions'] as List?) ?? [];
  final triage = data['triage'];

  // แปล triage เป็นข้อความภาษาไทย
  String triageText = "-";
  Color triageColor = Colors.black87;
  if (triage != null) {
    switch (triage['level']) {
      case "self_care":
        triageText = "ดูแลตนเองที่บ้าน";
        triageColor = Colors.green;
        break;
      case "consultation":
        triageText = "แนะนำให้พบแพทย์";
        triageColor = Colors.orange;
        break;
      case "consultation_24":
        triageText = "แนะนำพบแพทย์ภายใน 24 ชั่วโมง";
        triageColor = Colors.deepOrange;
        break;
      case "emergency":
        triageText = "พบแพทย์ฉุกเฉิน";
        triageColor = Colors.red;
        break;
      case "emergency_24":
        triageText = "พบแพทย์ฉุกเฉินภายใน 24 ชั่วโมง";
        triageColor = Colors.redAccent;
        break;
    }
  }

  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data["title"] ?? "ผลการวินิจฉัยเบื้องต้น",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blueAccent,
                ),
              ),
              const Icon(Icons.local_hospital, size: 24, color: Colors.blueAccent),
            ],
          ),
          const Divider(height: 24, thickness: 1.2),

          // Conditions list
          if (conditions.isNotEmpty) ...[
            const Text(
              "ภาวะที่เป็นไปได้:",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...conditions.map((c) {
              final prob = (c["probability"] as double?) ?? 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c["name_th"] ?? "-",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      "${(prob * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else
            const Text(
              "ไม่มีข้อมูลภาวะที่เป็นไปได้",
              style: TextStyle(color: Colors.black54),
            ),

          const SizedBox(height: 20),

          // Triage info
          if (triage != null) ...[
            Row(
              children: [
                const Text(
                  "ระดับความรุนแรง: ",
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  triageText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: triageColor,
                  ),
                ),
              ],
            ),
          ],
          const Divider(),
          const Text(
            "(นี่คือข้อมูลที่ได้จาก Infermedica)",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCardMessageSuggest(Map<String, dynamic> data) {
  final triageLevel = data['triage_level'];
  final adviceList = (data['advice_list'] as List?) ?? [];

  // กรณีฉุกเฉิน
if (triageLevel == "emergency" || triageLevel == "emergency_24" || triageLevel == "consultation_24") {
  return InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: () {
      // เรียกฟังก์ชันหาสถานพยาบาลใกล้ๆ
      findNearbyHospitals();
    },
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data["title"] ?? "คำแนะนำฉุกเฉิน",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.redAccent,
                  ),
                ),
                const Icon(Icons.warning_amber_rounded,
                    size: 26, color: Colors.redAccent),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 24, thickness: 1.2),
            const Text(
              "กรุณาไปพบแพทย์ฉุกเฉินทันที\n(กดเพื่อหาสถานพยาบาลใกล้เคียง)",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  // กรณีทั่วไป
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data["title_suggest"] ?? "คำแนะนำ",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blueAccent,
                ),
              ),
              const Icon(Icons.info_outline,
                  size: 24, color: Colors.blueAccent),
            ],
          ),
          const Divider(height: 24, thickness: 1.2),

          // Advice list
          if (adviceList.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...adviceList.map((section) {
              final topic = section["topic"] ?? "";
              final contents = List<String>.from(section["content"] ?? []);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (topic.isNotEmpty)
                      Text(
                        topic,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    const SizedBox(height: 6),
                    ...contents.map(
                      (c) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• ",
                                style: TextStyle(color: Colors.black54)),
                            Expanded(
                              child: Text(
                                c,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else
            const Text(
              "ไม่มีคำแนะนำเพิ่มเติม",
              style: TextStyle(color: Colors.black54),
            ),
          const SizedBox(height: 20),
          const Divider(),
          const Text(
            "(นี่คือข้อมูลที่ได้จาก AI)",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
        
      ),
    ),
  );
}

Widget _buildCardMessageMedicine(Map<String, dynamic> data) {
  final triageLevel = data['triage_level'];
  final medicines = (data['medicine_list'] as List?) ?? [];

  String getMedicineImage(String name) {
    if (name.contains("พารา")) {
      return "assets/images/ยาพารา.png";
    } else if (name.contains("แก้ไอ")) {
      return "assets/images/ยาแก้ไอ.png";
    } else if (name.contains("ลดกรด")) {
      return "assets/images/ยาลดกรด.png";
    } else if (name.contains("ท้องเสีย") || name.contains("ผงถ่าน")){
      return "assets/images/charcoal.jpg";
    }else if (name.contains("ท้องอืด")){
      return "assets/images/simethicone.png";
    }else if (name.contains("น้ำเกลือ")){
      return "assets/images/water.png";
    }else if (name.contains("ยาแก้ไอ")){
      return "assets/images/yafixcough.jpg";
    }else if (name.contains("ยาดม")){
      return "assets/images/relief.jpg";
    }else if (name.contains("ยาระบายแก้ท้องผูก")){
      return "assets/images/senokot.jpg";
    }else if (name.contains("ยาหม่อง")){
      return "assets/images/yamonk.jpg";
    }else if (name.contains("แอลกอฮอล")){
      return "assets/images/algohol.png";
    }else if (name.contains("ไอบูโพรเฟน")){
      return "assets/images/ibuprofen.png";
    }else if (name.contains("แก้เจ็บคอ")){
      return "assets/images/strepsils.jpg";
    }else if (name.contains("ธาตุน้ำขาว")){
      return "assets/images/yathadnamkhaw.jpeg";
    }else if (name.contains("เกลือแร่")){
      return "assets/images/neolyte.jpg";
    }
    return "assets/images/medicine_placeholder.png";
  }

  

  // 🔴 กรณีอาการ sensitive
  if (triageLevel == "emergency" ||
      triageLevel == "emergency_24" ||
      triageLevel == "consultation_24") {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        // TODO: เรียกฟังก์ชันหาสถานพยาบาลใกล้ๆ เช่น goToNearestHospital();
        findNearbyHospitals();
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "อาการที่มีความอ่อนไหว",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.orange,
                    ),
                  ),
                  Icon(Icons.warning_amber_rounded,
                      size: 26, color: Colors.orange),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 24, thickness: 1.2),
              const Text(
                "อาการของท่านเป็นอาการที่มีความอ่อนไหว\nจึงแนะนำให้ปรึกษาแพทย์ผู้เชี่ยวชาญ\n(กดเพื่อหาสถานพยาบาลใกล้เคียง)",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔵 กรณีทั่วไป (โชว์ข้อมูลยาแนะนำ)
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data["title_medicine"] ?? "ข้อมูลยาแนะนำ",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blueAccent
                ),
              ),
              const Icon(Icons.medical_services, size: 24, color: Colors.blueAccent),
            ],
          ),
          const Divider(height: 24, thickness: 1.2),

          // Medicines list
          if (medicines.isNotEmpty) ...[
            ...medicines.map((m) {
              final name = m["name"] ?? "ชื่อยาไม่ระบุ";
              final indication = m["indication"] ?? "ไม่ระบุ";
              final usage = m["usage"] ?? "วิธีใช้ไม่ระบุ";
              final precautions = m["precautions"] ?? "ข้อควรระวังไม่ระบุ";
              final image = getMedicineImage(name);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // แถวบน (รูป + ชื่อยา)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ครึ่งซ้าย (รูปยา) + คงอัตราส่วน
                        Expanded(
                          flex: 1,
                          child: AspectRatio(
                            aspectRatio: 1, // 1:1 → กว้าง = สูง
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.medication,
                                        size: 40, color: Colors.blueAccent);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // ครึ่งขวา (ชื่อยา)
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),


                    const SizedBox(height: 10),

                    // แถวล่าง (usage + precautions)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "วิธีใช้: $usage",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "อาการที่รักษา: $indication",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "ข้อควรระวัง: $precautions",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text("ไม่มีข้อมูลยาแนะนำ",
                  style: TextStyle(color: Colors.black54)),
            ),

          const Divider(),
          const Text(
            "(นี่คือข้อมูลที่ได้จาก AI)",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}



Future<void> findNearbyHospitals() async {
  try {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double lat = position.latitude;
    double lon = position.longitude;

    final overpassUrl =
        "https://overpass-api.de/api/interpreter?data=[out:json];"
        "("
        "node[\"amenity\"=\"hospital\"](around:5000,$lat,$lon);"
        "way[\"amenity\"=\"hospital\"](around:5000,$lat,$lon);"
        "relation[\"amenity\"=\"hospital\"](around:5000,$lat,$lon);"
        ");"
        "out center;";

    final response = await http.get(Uri.parse(overpassUrl), headers: {
      "User-Agent": "CREATH+/1.0 (kittipongr65@nu.ac.th)"
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["elements"].isEmpty) {
        throw Exception("ไม่พบโรงพยาบาลใกล้เคียง");
      }

      final hospital = data["elements"][0];
      final hLat = hospital["lat"] ?? hospital["center"]["lat"];
      final hLon = hospital["lon"] ?? hospital["center"]["lon"];

      final mapsUrl =
          "https://www.google.com/maps/dir/?api=1&destination=$hLat,$hLon";
      await launchUrl(Uri.parse(mapsUrl),
          mode: LaunchMode.externalApplication);
    } else {
      throw Exception("API Error: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("Error: $e");
  }
}



