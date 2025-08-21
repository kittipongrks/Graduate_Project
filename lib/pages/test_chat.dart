import 'package:flutter/material.dart';

class ChatStartScreen extends StatelessWidget {
  const ChatStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // สีพื้นหลังตามตัวอย่าง
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage('assets/profile.png'), // รูปตัวอย่าง
                        radius: 20,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Good Morning 👋',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Hashim Saffarini',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Icon(Icons.grid_view_rounded, color: Colors.white),
                ],
              ),
            ),

            const SizedBox(height: 50),

           /// This part of the code in the `ChatStartScreen` widget is responsible for displaying the
           /// introductory content of the chat screen. Here's a breakdown of what each section does:
            // Title
            const Text(
              'Hello, Ask Me Anything...',
              style: TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // Robot Image
            Image.asset(
              'assets/robot.png', // รูปหุ่นยนต์
              height: 180,
            ),

            const SizedBox(height: 20),

            // Subtitle
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'I am a Gemini Bot, I can help you with anything you need, just ask me!',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(),

            // Input Box
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const TextField(
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        // ส่งข้อความ (ยังไม่ทำงาน)
                      },
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
