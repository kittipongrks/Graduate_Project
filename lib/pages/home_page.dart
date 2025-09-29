import 'package:dahcpplication/pages/chat_diagnosis_page.dart';
import 'package:flutter/material.dart';
import 'package:dahcpplication/auth/database.dart';
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? userEmail;
  int? age ;
  String? gender;
  DateTime? birthdate;
  @override
  void initState(){
    super.initState();
    //fetchUserInfo(); // เรียกข้อมูลผู้ใช้เมื่อเริ่มต้น
  } 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar + Greeting
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    radius: 24,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("สวัสดีคุณ ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      Text("วันนี้มีอะไรให้เราช่วยไหม ?", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  Spacer(),
                ],
              ),

              SizedBox(height: 20),

              SizedBox(height: 20),

              // Categories Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("ประเภท", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),

              SizedBox(height: 12),

              // Category Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCategoryCard("Doctor AI", Icons.health_and_safety, Colors.purple[200]! , onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDiagnosisPage()),);
                  },),
                  _buildCategoryCard("Diagnosis", Icons.medical_information, Colors.blue[200]! , onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDiagnosisPage()),);
                  },),
                  _buildCategoryCard("History", Icons.history_rounded, Colors.green[200]! , onTap: () {
                    // Navigate to history page
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryPage()),);
                  },),
                ],
              ),

              SizedBox(height: 24),

              // Health News
              Text("ข่าวสารทั่วไป", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

              SizedBox(height: 12),

              // Covid-19 Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Covid-19 Update", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod...", style: TextStyle(fontSize: 14)),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text("Read More" , style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildCategoryCard(String title, IconData icon, Color bgColor , {VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child : Container(
      width: 110,
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.white),
          SizedBox(height: 5),
          Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.white ) ),
        ],
      ),
    )
    );
  }
}