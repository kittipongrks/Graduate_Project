import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<String> callGemini(String prompt) async {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  final endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';
  final headers = {
    'Content-Type': 'application/json',
  };
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
