import 'dart:convert';
import 'package:dahcpplication/controller/callinfermedicaapi.dart';
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


// Function to change English to Thai using LLMs
Future<String> llmsChangeEngToThai(String prompt) async {
  prompt = """ คุณเป็นนักแปลและผู้ช่วยสนทนาทางการแพทย์ ภารกิจของคุณคือแปลคำถามหรือคำศัพท์ทางการแพทย์จากภาษาอังกฤษเป็นภาษาไทยที่ฟังเป็นธรรมชาติ สำหรับผู้ใช้ทั่วไป  

    กฎ:
    1. อย่าแปลตรงตัวทีละคำ ให้ประโยคฟังเป็นธรรมชาติและเหมือนคนทั่วไปพูด
    2. ใช้ภาษาง่าย ๆ ชัดเจน และเข้าใจง่ายสำหรับทุกคน
    3. ถ้าคำศัพท์ทางการแพทย์ปรากฏ ให้ใส่คำอธิบายสั้น ๆ (1-2 คำ หรือในวงเล็บ)  
    4. ทำให้ประโยคสั้น กระชับ และเป็นมิตร 
    5. ลงท้ายด้วยเครื่องหมายคำถาม (?) ถ้าเป็นประโยคคำถาม และลงท้ายด้วยครับ

    ตัวอย่าง:  
    Input: "Are you photophobic?"
    Output: "แสงจ้าแสบตาหรือเปล่า?"  

    ตอนนี้ช่วยแปลและปรับประโยคนี้: $prompt
    """;

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
  prompt = """ Translate the $prompt into natural English suitable for Infermedica input. 
    Only output the translated phrase without explanations. 
    """;

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

Future <String> SummariseData(String prompt) async {
  prompt = """ คุณเป็นนักแปลและผู้ช่วยอธิบายทางการแพทย์ ภารกิจของคุณคือแปลคำศัพท์ทางการแพทย์ให้ผู้ใช้ทั่วไปเข้าใจง่าย  

    กฎ:
    1. ใช้ภาษาง่าย ๆ ไม่ใช้ศัพท์ทางการแพทย์ยาก ๆ
    2. อธิบายสั้น ๆ กระชับ (1-2 ประโยค)
    3. ถ้าเป็นคำที่ซับซ้อน ให้ยกตัวอย่างหรือเปรียบเทียบสั้น ๆ
    4. ทำให้ผู้ใช้ทั่วไปเข้าใจได้ทันที

    ตัวอย่าง:
    Input: "Hypertension"
    Output: "ความดันโลหิตสูง คือหัวใจต้องทำงานหนักขึ้นเพื่อส่งเลือด"

    ตอนนี้ช่วยแปลและอธิบายคำนี้: $prompt
    
    """;

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


Future<String> Terminology_medical_translate(String prompt) async{
  prompt = """ $prompt แปลคำศัพท์นี้ในทางการแพทย์ให้คนเข้าใจได้ง่ายๆ 
  เช่น Tension-type headache แปลเป็น ปวดศีรษะจากความเครียด
  ให้เอาเฉพาะภาษาไทยที่แปลออกมาเท่านั้น ไม่เอาภาษาอังกฤษหรือคำอธิบายอื่นๆ 
    
    """;

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

Future<dynamic> self_care_suggestion(DiagnosisResult dx,int age, String gender ,String medicalConditions , String foodAllergies , _evidence_common_name)async{
  final Map<String, dynamic> evidences = _evidence_common_name;
    String symptom = '';
    for (final e in List<Map<String, dynamic>>.from(evidences['supporting_evidence'] ?? [])) {
      symptom = symptom + e['common_name'] ;
      if (e['common_name'].isNotEmpty) {
        symptom += ', ';
      }
      
    }
  final prompt = """ "คุณคือผู้ช่วยสร้างคำแนะนำด้านสุขภาพสำหรับระบบ UI ของเรา ช่วยสร้างคำแนะนำจากข้อมูลผู้ป่วยที่ให้มา โดยผลลัพธ์ต้องอยู่ในรูปแบบ JSON object เท่านั้น และมี key และ value ดังนี้: `triage_level` สำหรับระดับความรุนแรง, `advice_title` สำหรับหัวข้อหลัก, และ `advice_list` สำหรับรายการคำแนะนำเป็นข้อๆ โดยแต่ละข้อมี `topic` และ `content` ตามข้อมูลด้านล่างนี้",
  "data": {
    "triage_level": "${dx.triage!.level}",
    "patient_info": {
      "age": $age,
      "sex": "$gender",
      "symptoms": ["${symptom}"],
      "allergies": {
        "medical_conditions": ["${medicalConditions}"],
        "food_allergies": ["${foodAllergies}"]
      }
    }
  },

  "output_format": {
    "triage_level": "string",
    "advice_title": "string",
    "advice_list": [
      {
        "topic": "การดูแลตัวเองเบื้องต้น",
        "content": ["string", "string"],
        "topic": "เมื่อใดควรพบแพทย์",
        "content": ["string", "string"],
        "topic": "คำแนะนำเพิ่มเติม/ข้อควรระวัง",
        "content": ["string", "string"]
      }
    ]
  }
    """;

  final body = jsonEncode({
    "contents": [
      {
        "parts": [
          {"text": prompt}
        ]
      }
    ],
  });
  final response = await http.post(
    Uri.parse(endpoint),
    headers: headers,
    body: body,
  );
  final dataEngtoThai = jsonDecode(response.body);
  print(dataEngtoThai);

  if (response.statusCode == 200 && dataEngtoThai['candidates'] != null) {
    try {
      final text = dataEngtoThai['candidates'][0]['content']['parts'][0]['text'];
      return text;
    } catch (e) {
      return 'เกิดข้อผิดพลาดในการแปลงข้อมูล: $e\n${response.body}';
    }
  } else if (dataEngtoThai['error'] != null) {
    return 'เกิดข้อผิดพลาด: ${dataEngtoThai['error']['message']}';
  } else {
    return 'เกิดข้อผิดพลาด: ไม่พบ candidates ใน response\n${response.body}';
  }
}





// Future<String> translateChangeThaiToEng(String prompt) async {
//   final url = Uri.parse("http://10.0.2.2:5000/translate");

//   final response = await http.post(
//     url,
//     headers: {
//       "Content-Type": "application/json",
//     },
//     body: jsonEncode({
//       "q": "$prompt",
//       "source": "auto",
//       "target": "en",
//       "format": "text",
//       "alternatives": 3,
//     }),
//   );

//   if (response.statusCode == 200) {
//     final data = jsonDecode(response.body);
//     print(data);
//     return data['translatedText'] ?? 'ไม่พบข้อความแปล';
//   } else {
//     print("Error: ${response.statusCode}");
//     return 'เกิดข้อผิดพลาดในการแปล: ${response.statusCode}';
//   }
// }

// Future<String> translateChangeEngToThai(String prompt) async {
//   final url = Uri.parse("http://10.0.2.2:5000/translate");

//   final response = await http.post(
//     url,
//     headers: {
//       "Content-Type": "application/json",
//     },
//     body: jsonEncode({
//       "q": "$prompt",
//       "source": "auto",
//       "target": "th",
//       "format": "text",
//       "alternatives": 3,
//     }),
//   );

//   if (response.statusCode == 200) {
//     final data = jsonDecode(response.body);
//     print(data);
//     return data['translatedText'] ?? 'ไม่พบข้อความแปล';
//   } else {
//     print("Error: ${response.statusCode}");
//     return 'เกิดข้อผิดพลาดในการแปล: ${response.statusCode}';
//   }
// }