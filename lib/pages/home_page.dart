import 'package:dahcpplication/pages/chat_page.dart';
import 'package:dahcpplication/pages/chat_diagnosis_page.dart';
import 'package:flutter/material.dart';
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
      body: Column(
        children: [
          // 🔴 ภาพด้านบนสุด (กรอบแดงในภาพ)
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/header_home_page.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🔻 ส่วนเนื้อหาข้างล่าง
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // แถว: รูปโปรไฟล์เล็ก + สวัสดี คุณ...
                  Row(
                    children: [
                      const Text(
                        'สวัสดี คุณ..',
                        style: TextStyle(fontSize: 20 , fontWeight: FontWeight.bold),
                        
                      ),
                      
                    ],
                    
                  ),
                  const SizedBox(height: 12),

                  // กล่อง TextField หรือ Input
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'มีอะไรให้เราช่วยเหลือ?',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  // ปุ่ม 2 อันในแนวนอน
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ChatDiagnosisPage()),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.psychology, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text("ตรวจโรคด้วยระบบ AI"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MyChatPage()),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.chat, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text("Chatbot AI Doctor"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // กล่องใหญ่ด้านล่าง
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}