// import 'dart:convert';
// import 'package:dahcpplication/controller/gemini_generate.dart';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:dahcpplication/auth/database.dart';
// import 'package:uuid/uuid.dart';
// import 'package:dahcpplication/controller/accessapi.dart';

// Future<dynamic> getApiInfermedica() async{
//   final appId = dotenv.env['INFERMEDICA_APP_ID'];
//   final appKey = dotenv.env['INFERMEDICA_APP_KEY'];
//   if (appId == null || appKey == null) {
//     throw Exception('Infermedica API credentials are not set in .env file');
//   }
//   return {'appId': appId, 'appKey': appKey};
// }

// Future<String> read_input(String prompt) async{
//   final response = await translateChangeEngToThai(prompt);
//   return response;
// }

// Future<List<Map<String, dynamic>>> read_complaint_portion(
//   int age,
//   String sex,
//   String appId,
//   String appKey,
//   String case_id,
//   List<String> context,
//   String userMessageEng,
// ) async{
//   String text = userMessageEng;
//   final Map<String , dynamic> resp = await call_parse(age, sex, text, appId, appKey, case_id);
//   print("ค่าที่ออกมาจาก response : /parse is $resp");
//   final List<dynamic> rawMentions = resp['mentions'] ?? [];

//   final List<Map<String, dynamic>> mentions = rawMentions.map((item) {
//     // ตรวจสอบว่าเป็น Map และแปลง key ให้เป็น String หากจำเป็น
//     if (item is Map<dynamic, dynamic>) {
//       return Map<String, dynamic>.from(item); // นี่คือวิธีที่ปลอดภัยในการ cast Map
//     } else {
//       // หากพบว่าไม่ใช่ Map ให้จัดการตามความเหมาะสม อาจจะ log warning หรือ return Map ว่าง
//       if (kDebugMode) { // ใช้ kDebugMode เพื่อให้แสดงเฉพาะในโหมด Debug
//         print("Warning: Unexpected item type in mentions from API: $item");
//       }
//       return <String , dynamic>{}; // คืน Map เปล่า หรือ throw exception ขึ้นอยู่กับความต้องการ
//     }
//   }).toList(); // ต้อง .toList() เพื่อให้ได้ List ที่ถูกต้อง

//   return mentions; // ตอนนี้ mentions เป็น List<Map<String, dynamic>> แล้ว
// }

// Future<List<Map<String, dynamic>>> read_complaints(
//   int age ,
//   String sex ,
//   String appId,
//   String appKey,
//   String case_id,
//   String userMessageEng,
// ) async{
//   List<Map<String , dynamic>> mentions = [];
//   List<String> context = [];
//   while (true) {
//     dynamic portion = await read_complaint_portion(age, sex, appId, appKey, case_id, context , userMessageEng);
//     if (portion != null && portion.isNotEmpty) {
//       summariseMentions(portion);
//       mentions.addAll(portion);
//       context.addAll(contextFromMentions(portion));
//     }
//     if(portion.isEmpty){
//       break;
//     }
//     if (mentions.isEmpty && portion == null) {
//       return mentions;
//     }
//   }
//   return mentions;
// }

// String mentionAsText(Map<String, dynamic> mention) {
//   const modalitySymbol = {"present": "+", "absent": "-", "unknown": "?"};
//   final name = mention["name"] ?? mention["id"] ?? '';
//   final choiceId = mention["choice_id"] ?? "unknown";
//   final symbol = modalitySymbol[choiceId] ?? "?";
//   return "$symbol$name";
// }

// List<String> contextFromMentions(List<Map<String, dynamic>> mentions) {
//   return [
//     for (final m in mentions)
//       if (m['choice_id'] == 'present' && m['id'] != null)
//         m['id'] as String
//   ];
// }

// void summariseMentions(List<Map<String, dynamic>> mentions) {
//   final summary = mentions.map(mentionAsText).join(", ");
//   print("Noting: $summary");
// }

// Future<dynamic> new_case_id() async {
//   final uuid = Uuid();
//   final case_id = uuid.v4();
//   return case_id;
// }

// Future<String?> read_single_question_answer(String questionText) async {
//   // แสดงคำถามและรับคำตอบจากผู้ใช้ (เช่นผ่าน TextField หรือ dialog)
//   final answer = await read_input(questionText);
//   if (answer == null || answer.trim().isEmpty) {
//     return null;
//   }
//   try{
//     return answer.trim();
//   }catch(e){
//     print("$e เกิดข้อผิดพลาดในการอ่านคำตอบ");
//     return await read_single_question_answer(questionText);
//   }
// }

// Future<List<dynamic>> conduct_interview(
//   List<Map<String, dynamic>> evidence,
//   int age,
//   String sex,
//   String case_id,
//   String appId,
//   String appKey, {
//   String? languageModel,
// }) async {
//   while (true) {
//     final resp = await call_diagnosis(
//       evidence,
//       age,
//       sex,
//       case_id,
//       appId,
//       appKey,
//     );

//     final questionStruct = resp['question'];
//     final diagnoses = resp['conditions'];
//     final shouldStopNow = resp['should_stop'];

//     if (shouldStopNow == true) {
//       final triageResp = await call_triage(
//         evidence,
//         age,
//         sex,
//         case_id,
//         appId,
//         appKey,
//         languageModel: languageModel,
//       );
//       return [evidence, diagnoses, triageResp];
//     }

//     List<Map<String, dynamic>> newEvidence = [];

//     if (questionStruct['type'] == 'single') {
//       final questionItems = questionStruct['items'] as List;
//       if (questionItems.length == 1) {
//         final questionItem = questionItems[0] as Map<String, dynamic>;
//         final observationValue = await read_single_question_answer(questionStruct['text']);
//         if (observationValue != null) {
//           newEvidence.addAll(questionAnswerToEvidence(questionItem, observationValue));
//         }
//       }
//     } else {
//       throw UnimplementedError("Group questions not handled in this example");
//     }

//     // อัปเดต evidence ด้วยคำตอบใหม่
//     evidence.addAll(newEvidence);
//   }
// }

// void summariseSomeEvidence(List<Map<String, dynamic>> evidence, String header) {
//   print('$header:');
//   for (var i = 0; i < evidence.length; i++) {
//     print('${i + 1}. ${mentionAsText(evidence[i])}');
//   }
//   print('');
// }

// void summariseAllEvidence(List<Map<String, dynamic>> evidence) {
//   final reported = <Map<String, dynamic>>[];
//   final answered = <Map<String, dynamic>>[];
//   for (final piece in evidence) {
//     if (piece['initial'] == true) {
//       reported.add(piece);
//     } else {
//       answered.add(piece);
//     }
//   }
//   summariseSomeEvidence(reported, 'Patient complaints');
//   summariseSomeEvidence(answered, 'Patient answers');
// }

// void summariseDiagnoses(List<dynamic> diagnoses) {
//   print('Diagnoses:');
//   for (var i = 0; i < diagnoses.length; i++) {
//     final diag = diagnoses[i];
//     print('${i + 1}. ${diag['probability']?.toStringAsFixed(2) ?? '??'} ${diag['name']}');
//   }
//   print('');
// }

// void summariseTriage(Map<String, dynamic> triageResp) {
//   print('Triage level: ${triageResp['triage_level']}');
//   final teleconsultationApplicable = triageResp['teleconsultation_applicable'];
//   if (teleconsultationApplicable != null) {
//     print('Teleconsultation applicable: $teleconsultationApplicable');
//   }
//   print('');
// }

// // Helper function: mentionAsText
// // String mentionAsText(Map<String, dynamic> piece) {
// //   // คุณต้อง implement ฟังก์ชันนี้เองตามโครงสร้าง evidence
// //   // ตัวอย่าง:
// //   final name = piece['name'] ?? piece['id'] ?? '';
// //   final choice = piece['choice_id'] ?? '';
// //   return '$name ($choice)';
// // }



// // Future<void> runDiagnosisFlow(
// //   int age,
// //   String sex,
// //   String appId,
// //   String appKey,
// //   String case_id,
// // ) async {
// //   // 1. รับข้อมูลอาการจากผู้ใช้
// //   final mentions = await read_complaints(age, sex, appId, appKey, case_id);

// //   // 2. แปลง mentions เป็น evidence
// //   final evidence = mentionsToEvidence(mentions);

// //   // 3. สรุปผลด้วย conduct_interview
// //   final result = await conduct_interview(
// //     evidence,
// //     age,
// //     sex,
// //     case_id,
// //     appId,
// //     appKey,
// //   );

// //   // 4. แสดงผลลัพธ์ (ตัวอย่าง)
// //   final evidenceResult = result[0] as List<Map<String, dynamic>>;
// //   final diagnoses = result[1];
// //   final triageResp = result[2];

// //   summariseAllEvidence(evidenceResult);
// //   summariseDiagnoses(diagnoses);
// //   summariseTriage(triageResp);
// // }



// //// Custom function by me 
// ///