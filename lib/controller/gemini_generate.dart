import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final Map<String , dynamic> models = {
  'gemini-2.0-flash-lite':{
    'endpoint': 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent',
  },
  'gemini-2.0-flash':{
    'endpoint': 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
  },
  'gemini-2.5-pro':{
    'endpoint': 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent',
  },
};


final apiKey = dotenv.env['GEMINI_API_KEY'];
  final endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';
  final headers = {
    'Content-Type': 'application/json',
  };


Future<String> callModelLLMs(String prompt) async {
  prompt = '''[บทบาทของคุณ: คุณคือ AI ผู้ช่วยด้านสุขภาพที่เป็นมิตรและให้ข้อมูลเบื้องต้นอย่างระมัดระวัง] 
[คำถามของผู้ใช้]:$prompt''';
  
  final body = jsonEncode({
    "contents": [
      {
        "parts": [
          {"text": prompt}
        ]
      }
    ],
    "generationConfig": {
      "maxOutputTokens": 256,
    },
  });
  final response = await http.post(
    Uri.parse(endpoint),
    headers: headers,
    body: body,
  );
  final data = jsonDecode(response.body);
  print('Gemini response: ${response.body}'); // Debug

  if (response.statusCode == 200 && data['candidates'] != null) {
    try {
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      return text;
    } catch (e) {
      return 'เกิดข้อผิดพลาดในการแปลงข้อมูล: $e\n${response.body}';
    }
  } else if (data['error'] != null) {
    return 'เกิดข้อผิดพลาด: ${data['error']['message']}';
  } else {
    return 'เกิดข้อผิดพลาด: ไม่พบ candidates ใน response\n${response.body}';
  }
}
// Function to change English to Thai using LLMs
Future<String> llmsChangeEngToThai(String prompt) async {
  prompt = """ แปลภาษาอังกฤษเป็นภาษาไทยโดยให้มีความเป็นธรรมชาติ คนทั่วไปสามารถอ่านเข้าใจได้
   โดยไม่ต้องใส่รายละเอียดเพิ่มเติม **เอาแค่คำแปล** และนี่คือ prompt: $prompt""";

  final body = jsonEncode({
    "contents": [
      {
        "parts": [
          {"text": prompt}
        ]
      }
    ],
  });
  final responseEngtoThai = await http.post(
    Uri.parse(endpoint),
    headers: headers,
    body: body,
  );
  final dataEngtoThai = jsonDecode(responseEngtoThai.body);
  print(dataEngtoThai);

  if (responseEngtoThai.statusCode == 200 && dataEngtoThai['candidates'] != null) {
    try {
      final text = dataEngtoThai['candidates'][0]['content']['parts'][0]['text'];
      return text;
    } catch (e) {
      return 'เกิดข้อผิดพลาดในการแปลงข้อมูล: $e\n${responseEngtoThai.body}';
    }
  } else if (dataEngtoThai['error'] != null) {
    return 'เกิดข้อผิดพลาด: ${dataEngtoThai['error']['message']}';
  } else {
    return 'เกิดข้อผิดพลาด: ไม่พบ candidates ใน response\n${responseEngtoThai.body}';
  }
}
// Function to change Thai to English using LLMs
Future<String> llmsChangeThaiToEng(String prompt) async {
  prompt = """ เปลี่ยนภาษาไทยเป็นภาษาอังกฤษโดยให้มีข้อมูลที่เหมาะสมสำหรับ infermedica 
  ไม่ต้องอธิบายเพิ่มเติม ถ้าเจอคำว่าประมาณว่า "ใช่" ให้แปลเป็น present ถ้าเจอ "ไม่" ให้แปลเป็น absent และถ้าไม่แน่ใจ ให้แปลเป็น unknown 
  **เอาแค่คำแปล** และนี่คือ prompt: $prompt""";

  final body = jsonEncode({
    "contents": [
      {
        "parts": [
          {"text": prompt}
        ]
      }
    ],
  });
  final responseEngtoThai = await http.post(
    Uri.parse(endpoint),
    headers: headers,
    body: body,
  );
  final dataEngtoThai = jsonDecode(responseEngtoThai.body);
  print(dataEngtoThai);

  if (responseEngtoThai.statusCode == 200 && dataEngtoThai['candidates'] != null) {
    try {
      final text = dataEngtoThai['candidates'][0]['content']['parts'][0]['text'];
      return text;
    } catch (e) {
      return 'เกิดข้อผิดพลาดในการแปลงข้อมูล: $e\n${responseEngtoThai.body}';
    }
  } else if (dataEngtoThai['error'] != null) {
    return 'เกิดข้อผิดพลาด: ${dataEngtoThai['error']['message']}';
  } else {
    return 'เกิดข้อผิดพลาด: ไม่พบ candidates ใน response\n${responseEngtoThai.body}';
  }
}