import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dahcpplication/auth/database.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';
import 'package:dahcpplication/controller/controller.dart';


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

class AccountPage extends StatefulWidget{
  const AccountPage({Key? key}) : super(key: key);

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage>{
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _birthdateController = TextEditingController();
  final _genderController = TextEditingController();
  final _foodAllergiesController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  DateTime? birthdate;

  @override
  void dispose() {
    _birthdateController.dispose();
    _genderController.dispose();
    _foodAllergiesController.dispose();
    _medicalConditionsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    LoadUserInfo();
}

Future<dynamic> LoadUserInfo() async {
  final user = _auth.currentUser;
  if (user == null) {
    print("ยังไม่ได้ login");
    return;
  }
  final doc = await _firestore.collection('Users').doc(user.uid).get();
  if (!doc.exists) return;
  final data = doc.data()!;
  setState(() {
    // วันเกิด
    if (data['birthdate'] != null) {
      birthdate = (data['birthdate'] as Timestamp).toDate();
      _birthdateController.text =
          "${birthdate!.day}/${birthdate!.month}/${birthdate!.year}";
    }
    _genderController.text = data['gender'] ?? '';
    _foodAllergiesController.text = data['foodAllergies'] ?? '';
    _medicalConditionsController.text = data['medicalConditions'] ?? '';
  });
}

//Function Calling
 Future<void> _updateUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('Users').doc(user.uid).set({
          'birthdate': birthdate != null ? Timestamp.fromDate(birthdate!) : null,
          'gender': _genderController.text,
          'foodAllergies': _foodAllergiesController.text,
          'medicalConditions': _medicalConditionsController.text,
        },SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
        );
      }
    } catch (e) {
      print("Error updating user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')),
      );
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('โปรไฟล์', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold ,)),
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
                    Row(
                      children: [
                        // อายุ
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("วันเกิด",
                                  style: TextStyle(fontSize: 14)),
                              const SizedBox(height: 5),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  border: Border.all(color: const Color(0xFF90CAF9)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: TextFormField(
                                  style: const TextStyle(color: Colors.black),
                                  controller : _birthdateController,
                                  readOnly: true,
                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: birthdate ?? DateTime.now(),
                                    firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: ThemeData.light(),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      birthdate = pickedDate; // เก็บเป็น DateTime
                                      _birthdateController.text =
                                          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                                    });
                                  }
                                },
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
                                child: DropdownButtonFormField<String>(
                                  dropdownColor: Colors.blue.shade100,
                                value: _genderController.text.isNotEmpty ? _genderController.text : null,
                                style: const TextStyle(color: Colors.black),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Male',
                                    child: Text(
                                      'Male',
                                      style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), ), // ใช้สีเดียวกับ BoxDecoration
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Female',
                                    child: Text(
                                      'Female',
                                      style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _genderController.text = value!;
                                  });
                                },
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
                          child: TextFormField(
                            style: const TextStyle(color: Colors.black),
                            controller: _foodAllergiesController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
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
                          child: TextFormField(
                            style: const TextStyle(color: Colors.black),
                            controller: _medicalConditionsController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                     ElevatedButton(
                        onPressed: _updateUserData,
                        child: const Text('บันทึกข้อมูล'),
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