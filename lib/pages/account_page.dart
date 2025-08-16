import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
class AccountPage extends StatelessWidget{
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ข้อมูลส่วนตัว', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold ,)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              _exitAlertDialog(context);
            },
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ส่วนหัวสีน้ำเงิน + ไอคอนผู้ใช้ (ไม่มีรอยเว้าลงมาแล้ว)
            Container(
              color: Colors.blue,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: Color.fromARGB(0, 33, 149, 243),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),
            
            // AGE + GENDER ในบรรทัดเดียวกัน
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8), // ขอบมน
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  
                  children: [
                    // AGE + GENDER
                    Row(
                      children: [
                        // อายุ
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("อายุ", style: TextStyle(fontSize: 14)),
                              const SizedBox(height: 5),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  border: Border.all(color: const Color(0xFF90CAF9)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: const TextField(
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Enter your age",
                                    hintStyle: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // เพศ
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("เพศ", style: TextStyle(fontSize: 14)),
                              const SizedBox(height: 5),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  border: Border.all(color: const Color(0xFF90CAF9)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: const TextField(
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Enter your gender",
                                    hintStyle: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ข้อมูลแพ้อาหารและยา
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("ข้อมูลแพ้อาหาร และยา", style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 5),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            border: Border.all(color: const Color(0xFF90CAF9)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: const TextField(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter allergy info",
                              hintStyle: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ข้อมูลโรคประจำตัว
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("ข้อมูลโรคประจำตัว", style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 5),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            border: Border.all(color: const Color(0xFF90CAF9)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: const TextField(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter your health condition",
                              hintStyle: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    
  }
}