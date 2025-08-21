import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class DatabaseService{
  final String? uid;
  DatabaseService({this.uid});

  final CollectionReference userCollection = 
  FirebaseFirestore.instance.collection('Users');

  Future updateUserData(
    String name, String email, String password) async {
    return await userCollection.doc(uid).set({
      'name': name,
      'email': email,
      'password': password,
    });
  }
  
}

Future<dynamic> fetchUserInfo() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print("ยังไม่ได้ login");
    return null; 
  }
  final email = user.email;

  final doc = await FirebaseFirestore.instance
      .collection('Users')
      .doc(user.uid)
      .get();

  final age = calculateAge(doc.data()?['birthdate'] ?? Timestamp.fromDate(DateTime(2000, 1, 1))); // Default is Age 25
  final gender = doc.data()?['gender'] ?? 'male';
  final _foodAllergies = doc.data()?['foodAllergies'] ?? '';
  final _medicalConditions = doc.data()?['medicalConditions'] ?? '';
  print("Current user info: $email, Age: $age");
  return {
    'age': age,
    'sex': gender,
    'foodAllergies': _foodAllergies,
    'medicalConditions': _medicalConditions,
  };
}

int calculateAge(Timestamp birthdate) {
  // birthdate ควรเป็นรูปแบบ 'yyyy-MM-dd'
  final birth =birthdate.toDate();
  final now = DateTime.now();
  int age = now.year - birth.year;
  if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
    age--;
  }
  return age;
}

class UserInfo{
  final String? email;
  final String? sex;
  final DateTime? birthdate;
  final int? age;
  UserInfo({
    this.email, this.sex , this.birthdate, this.age
  });
  
  
}