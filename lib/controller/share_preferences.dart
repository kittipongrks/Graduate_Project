// import 'package:shared_preferences/shared_preferences.dart';

// class SharePreferences {
//   static String userIdKey = 'USERKEY';
//   static String emailKey = 'EMAILKEY';
//   static String birthdateKey = 'BIRTHDATEKEY';
//   static String genderKey = 'GENDERKEY';

//   Future<bool> saveUserId(String getid) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return await prefs.setString(userIdKey, getid);
//   }

//   Future<bool> saveUserEmail(String getemail) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return await prefs.setString(emailKey, getemail);
//   }
//   Future<bool> saveUserBirthDate(String getebirthdate) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return await prefs.setString(birthdateKey, getebirthdate);
//   }

//   Future<bool> saveUserGender(String getgender) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return await prefs.setString(genderKey, getgender);
//   }

//   Future<String?> getUserID() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString(userIdKey);
//   }

//   Future<String?> getUserEmail() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString(emailKey);
//   }

//   Future<String?> getUserBirthdate() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString(birthdateKey);
//   }

//   Future<String?> getGender() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString(genderKey);
//   }

// }