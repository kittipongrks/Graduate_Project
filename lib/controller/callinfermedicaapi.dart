import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dahcpplication/controller/gemini_generate.dart';
import 'package:dahcpplication/auth/database.dart';
import 'package:firebase_auth/firebase_auth.dart';

// -----------------------------------------------------------------------------
// CONFIG
// -----------------------------------------------------------------------------
const String infermedicaBaseUrl = 'https://api.infermedica.com/v3';
// ตั้งค่า credentials ของคุณ
final infermedicaAppId = dotenv.env['INFERMEDICA_APP_ID'] ?? '';
final infermedicaAppKey = dotenv.env['INFERMEDICA_APP_KEY'] ?? '';
// Locale ตัวอย่าง (Infermedica รองรับหลายภาษา ดู docs)

// อายุ/เพศของผู้ใช้ (ในระบบจริงคุณดึงจากโปรไฟล์หรือให้ user กรอก)
const int defaultAge = 30; // ตัวอย่าง
const String defaultSex = 'male'; // 'male' | 'female'
const String defaultAllergies = '';
const String defaultMedicalConditions = '';



// -----------------------------------------------------------------------------
// CHAT MODELS
// -----------------------------------------------------------------------------

enum ChatSender { user, bot, system, error }

enum EvidenceChoice { present, absent, unknown }

enum MessageType { text, cardEvidence , cardDiagnosis , cardSuggest, cardMedicine}

class ChatMessage {
  final String id;
  final MessageType type ;
  final ChatSender sender;
  final String? text;
  final Map<String, dynamic>? textreuslt;
  final Timestamp timestamp;


  ChatMessage({
    required this.id,
    required this.sender,
    required this.type,
    this.text,
    this.textreuslt,
    Timestamp? timestamp,
  }) : timestamp = timestamp ?? Timestamp.now();

  //Maping Chatsender to String for display
  Map<String , dynamic> toMap(){
    return {
      'senderID': id,
      'sender': sender.name,
      'type': type.name,
      'text': text,
      'textreuslt': textreuslt ?? {},
      'timestamp': timestamp,
    };
  }
}


// Representation of evidence item for Infermedica
class EvidenceItem {
  final String id; // symptom or risk factor ID from Infermedica
  final EvidenceChoice choice;
  final String? source; // 'initial', 'user', 'question', etc.
  final String? common_name;

  EvidenceItem({required this.id, required this.choice ,this.source , this.common_name});

  Map<String, dynamic> toJson() => {
        'id': id,
        'choice_id': _choiceToString(choice),
        if (source != null) 'source': source,
      };

  static String _choiceToString(EvidenceChoice c) {
    switch (c) {
      case EvidenceChoice.present:
        return 'present';
      case EvidenceChoice.absent:
        return 'absent';
      case EvidenceChoice.unknown:
        return 'unknown';
    }
  }
  
}


// -----------------------------------------------------------------------------
// INFERMEDICA SERVICE LAYER
// -----------------------------------------------------------------------------

class InfermedicaService {
  String? case_id;

  Future<void> new_case_id() async {
    final uuid = Uuid();
    case_id = uuid.v4();
  }
  
  void resetPatient(){
    case_id = null;
  }
  InfermedicaService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Accept' : 'application/json',
    'App-Id': infermedicaAppId,
    'App-Key': infermedicaAppKey,

    'Dev-Mode':'true',
    if (case_id != null) 'Interview-Id' : case_id!,
  };
  
  Future<void> getSymptomName(String symptomId)async{
    final responce = await http.get(
      Uri.parse('$infermedicaBaseUrl/symptoms/$symptomId'),
      headers: _headers(),
    );
    final symptom_name = jsonDecode(responce.body)['name'];
    print(symptom_name);
  }


  /// Call /parse to extract mentions (symptoms / risk factors) from user free text.
  Future<ParseResult> parseText({
    required String text,
    required int age,
    required String sex,
  }) async {
    final uri = Uri.parse('$infermedicaBaseUrl/parse');
    final body = utf8.encode(jsonEncode({
      'text': text,
      'age': { 'value': age , 'unit' : 'year'},
      'sex': sex,
      // 'context': [], // optional: prior context strings you maintain
    }));

    final resp = await _client.post(uri, headers: _headers(), body: body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final Map<String, dynamic> data = jsonDecode(resp.body);
      return ParseResult.fromJson(data);
    } else {
      throw InfermedicaHttpException(resp.statusCode, resp.body);
    }
  }

  /// Call /diagnosis with accumulated evidence.
  Future<DiagnosisResult> diagnosis({
    required List<EvidenceItem> evidence,
    required int age,
    required String sex,
    bool noGroups = false,
  }) async {
    final uri = Uri.parse('$infermedicaBaseUrl/diagnosis');
    final body = utf8.encode(jsonEncode({
      'age': { 'value': age , 'unit' : 'year'},
      'sex': sex,
      'evidence': evidence.map((e) => e.toJson()).toList(),
      // 'extras': { ... } // e.g., enable triage, suggestions, etc.
      'extras': {
            'disable_groups': noGroups,
        }
    }));

    final resp = await _client.post(uri, headers: _headers(), body: body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final Map<String, dynamic> data = jsonDecode(resp.body);
      return DiagnosisResult.fromJson(data);
    } else {
      throw InfermedicaHttpException(resp.statusCode, resp.body);
    }
  }

  Future<DiagnosisTriage> triage({
    required List<EvidenceItem> evidence,
    required int age,
    required String sex,
  }) async {
    final uri = Uri.parse('$infermedicaBaseUrl/triage');
    final body = utf8.encode(jsonEncode({
      'age': { 'value': age , 'unit' : 'year'},
      'sex': sex,
      'evidence': evidence.map((e) => e.toJson()).toList(),
    }));
    final resp = await _client.post(uri, headers: _headers(), body: body);


    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final Map<String, dynamic> data = jsonDecode(resp.body);
      return DiagnosisTriage.fromJson(data);
    } else {
      throw InfermedicaHttpException(resp.statusCode, resp.body);
    }
  }


  Future<Map<String,dynamic>> explain({
    required List<EvidenceItem> evidence,
    required int age,
    required String sex,
    required String target,
  }) async {
    final uri = Uri.parse('$infermedicaBaseUrl/explain');
    final body = utf8.encode(jsonEncode({
      'age': { 'value': age , 'unit' : 'year'},
      'sex': sex,
      'evidence': evidence.map((e) => e.toJson()).toList(),
      'target': target,
    }));

    final resp = await _client.post(uri, headers: _headers(), body: body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final Map<String, dynamic> data = jsonDecode(resp.body);
      return {'supporting_evidence':data['supporting_evidence'] ?? [],
              'conflicting_evidence':data['conflicting_evidence'] ?? [],
              'unconfirmed_evidence': data['unconfirmed_evidence'] ?? [],
      };
    } else {
      throw InfermedicaHttpException(resp.statusCode, resp.body);
    }
  }

  /// https://api.infermedica.com/v3/concepts?ids=c_1,c_4
  Future<List<Map<String, dynamic>>> getConceptsByIds(List<String> ids) async {
    final idToString = ids.join(',');
    final uri = Uri.parse('$infermedicaBaseUrl/concepts/?ids=$idToString');

    final resp = await http.get(uri, headers: _headers());

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final List<dynamic> data = jsonDecode(resp.body);

      // map ให้เหลือเฉพาะ id + name
      return data
          .map((item) => {
                'id': item['id'] as String,
                'name': item['name'] as String,
                'common_name': item['common_name'] as String? ?? item['name'] as String,
              })
          .toList();
    } else {
      throw Exception(
          'Infermedica API error: ${resp.statusCode} ${resp.body}');
    }
  }

}
class InfermedicaHttpException implements Exception {
  final int statusCode;
  final String body;
  InfermedicaHttpException(this.statusCode, this.body);
  @override
  String toString() => 'InfermedicaHttpException($statusCode): $body';
}

// -----------------------------------------------------------------------------
// PARSE RESULT MODEL (simplified)
// -----------------------------------------------------------------------------

class ParseMention {
  final String id; // symptom/risk ID
  final String name;
  final double confidence;
  final bool negated; // text indicates absence

  ParseMention({
    required this.id,
    required this.name,
    required this.confidence,
    required this.negated,
  });

  factory ParseMention.fromJson(Map<String, dynamic> json) => ParseMention(
        id: json['id'] as String,
        name: json['name'] as String? ?? json['orth'] as String? ?? 'Unknown',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        negated: json['choice_id'] == 'absent' || json['negated'] == true,
      );
}

class ParseResult {
  final List<ParseMention> mentions;
  ParseResult({required this.mentions});
  factory ParseResult.fromJson(Map<String, dynamic> json) {
    final m = (json['mentions'] as List?)?.map((e) => ParseMention.fromJson(e)).toList() ?? [];
    return ParseResult(mentions: m);
  }
}

// -----------------------------------------------------------------------------
// DIAGNOSIS RESULT MODEL (simplified)
// -----------------------------------------------------------------------------

class DiagnosisQuestionItem {
  final String id; // symptom/risk to confirm
  final String name; // readable

  DiagnosisQuestionItem({required this.id, required this.name});

  factory DiagnosisQuestionItem.fromJson(Map<String, dynamic> json) => DiagnosisQuestionItem(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Unknown',
      );
}

class DiagnosisQuestion {
  final String text; // question prompt
  final List<DiagnosisQuestionItem> items;
  final String? type; // single | group | multiple | ...

  DiagnosisQuestion({required this.text, required this.items, this.type});

  factory DiagnosisQuestion.fromJson(Map<String, dynamic> json) => DiagnosisQuestion(
        text: json['text'] as String? ?? '...?',
        items: (json['items'] as List?)
                ?.map((e) => DiagnosisQuestionItem.fromJson(e))
                .toList() ??
            [],
        type: json['type'] as String?,
      );
}

class DiagnosisCondition {
  final String id;
  final String name;
  final String? name_th;
  final double probability;
  DiagnosisCondition({required this.id, required this.name, required this.probability , this.name_th});
  factory DiagnosisCondition.fromJson(Map<String, dynamic> json) => DiagnosisCondition(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Unknown',
        name_th :json['name_th'] as String? ?? 'Unknown',
        probability: (json['probability'] as num?)?.toDouble() ?? 0,
      );
}

class DiagnosisTriage {
  final String level; // e.g., emergency, consult GP, self-care
  final String? recommendation;
  DiagnosisTriage({required this.level, this.recommendation});
  factory DiagnosisTriage.fromJson(Map<String, dynamic> json) => DiagnosisTriage(
        level: json['triage_level'] as String? ?? 'unknown',
        recommendation: json['recommendation'] as String?,
      );
}

class DiagnosisResult {
  final DiagnosisQuestion? question;
  final List<DiagnosisCondition> conditions;
  final DiagnosisTriage? triage;

  DiagnosisResult({this.question, required this.conditions, this.triage});

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    DiagnosisQuestion? q;
    if (json['question'] != null) {
      q = DiagnosisQuestion.fromJson(json['question']);
    }
    final conditions = (json['conditions'] as List?)
            ?.map((e) => DiagnosisCondition.fromJson(e))
            .toList() ??
        [];
    DiagnosisTriage? t;
    if (json['triage'] != null) {
      t = DiagnosisTriage.fromJson(json['triage']);
    }
    return DiagnosisResult(question: q, conditions: conditions, triage: t);
  }

  bool get isFinished => question == null || (question?.items.isEmpty ?? true);
}

// -----------------------------------------------------------------------------
// CHAT LOOP CONTROLLER
// -----------------------------------------------------------------------------

class InfermedicaChatController extends ChangeNotifier {

  Future<void> resetChat() async {
    await service.new_case_id(); // Generate a new case_id
    _messages.clear();
    _evidence.clear();
    addSystemMessage('สวัสดีอีกครั้ง!');
    addSystemMessage('อยากเล่าอะไรให้ฟังไหมเกี่ยวกับอาการของคุณ');
    notifyListeners();
  }
  InfermedicaChatController({
    required this.service,
    String? UserId,
    int? age,
    String? sex,
    String? caseId,
    String? foodAllergies,
    String? medicalConditions,
  })  : UserId = UserId ?? '',
        age = age ?? defaultAge,
        sex = sex ?? defaultSex,
        foodAllergies = foodAllergies ?? defaultAllergies,
        medicalConditions = medicalConditions ?? defaultMedicalConditions,
        caseId = caseId ?? const Uuid().v4();
        

  final InfermedicaService service;
  int age ;
  String sex;
  String foodAllergies;
  String medicalConditions;
  String UserId;
  final String caseId;

  Future<void> loadUserData() async {
    final userProfile = await fetchUserInfo();
    UserId = userProfile.uid ;
    age = userProfile['age'] ?? defaultAge;
    sex = userProfile['sex'] ?? defaultSex;
    foodAllergies = userProfile['foodAllergies'] ?? defaultAllergies;
    medicalConditions = userProfile['medicalConditions'] ?? defaultMedicalConditions;

    notifyListeners();
  }

  final List<ChatMessage> _messages = [];
  List<EvidenceItem> _evidence = [];

  Map<String, dynamic> _evidence_common_name = {};

  bool _isBusy = false;
  DiagnosisResult? _lastDiagnosis;

  int questionCount = 0;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isBusy => _isBusy;
  DiagnosisResult? get lastDiagnosis => _lastDiagnosis;

  void addSystemMessage(String text) {
  notifyListeners();
  Future.delayed(Duration(seconds: 1), () { 
    _messages.add(ChatMessage(
      id: const Uuid().v4(), 
      sender: ChatSender.system,
      type: MessageType.text,
      text: text
      ));
    notifyListeners();
  });
}

  void addErrorMessage(String text) {
    _messages.add(ChatMessage(
      id: const Uuid().v4(), 
      sender: ChatSender.error, 
      type: MessageType.text,
      text: text));
    notifyListeners();
  }

  Future<void> startNewCase() async {
    await service.new_case_id();
    _evidence.clear();
    _lastDiagnosis = null;
    notifyListeners();
  }

  // Public entry when user submits text in TextField.
  Future<void> handleUserInput(String rawUserText) async {
    if (rawUserText.trim().isEmpty) return;

    // Show user message in chat.
    _messages.add(ChatMessage(
      id: const Uuid().v4(), 
      sender: ChatSender.user, 
      type: MessageType.text,
      text: rawUserText));
    notifyListeners();

    callParse(rawUserText);
    // If we are currently answering a follow‑up question expecting yes/no/maybe,
    // try to map quick answer directly to evidence for that pending question.
  }

  void callParse(String rawUserText) async{
    if (_lastDiagnosis?.question != null) {
      final q = _lastDiagnosis!.question!;
      final EvidenceChoice? mapped = await _mapUserQuickAnswer(rawUserText);
      if (mapped != null && q.items.isNotEmpty) {
        // apply same choice to all items in the question (simple case).
        for (final item in q.items) {
          _upsertEvidence(item.id, mapped, source: 'suggest');
        }
        await _runDiagnosisCycle();
        return;
      }
      // else fall through to full parse of free text to capture new symptoms.
    }

    // Otherwise treat as new free‑text symptom description.
    final processed = await _preProcessUserText(rawUserText);
    await _runParseThenDiagnosis(processed);
  }

  // ---------------------------------------------------------------------------
  // INTERNAL FLOW STEPS
  // ---------------------------------------------------------------------------

  Future<String> _preProcessUserText(String input) async {
    // TODO: implement your custom logic here.
    // Examples:
    // - Trim whitespace
    // - Language translation to English if needed
    // - Remove emojis / slang normalization
    // - Expand abbreviations ("bp" -> "blood pressure")
    // In this demo we just trim.
    return input.trim();
  }

  void _upsertEvidence(String id, EvidenceChoice choice, {String? source}) {
    final idx = _evidence.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _evidence[idx] = EvidenceItem(id: id, choice: choice, source: source ?? _evidence[idx].source);
    } else {
      _evidence.add(EvidenceItem(id: id, choice: choice, source: source));
    }
  }

  EvidenceChoice _inferChoiceFromParseMention(ParseMention m) {
    if (m.negated) return EvidenceChoice.absent;
    // You could use confidence threshold; here default to present
    return EvidenceChoice.present;
  }

  Future<void> _runParseThenDiagnosis(String processedUserText) async {
    if (questionCount > 1){
      return;
    }
    _isBusy = true;
    notifyListeners();
    processedUserText = await llmsChangeThaiToEng(processedUserText);
    try {
      final parse = await service.parseText(
        text: processedUserText,
        age: age,
        sex: sex,
      );
      if (parse.mentions.isEmpty) {
        // Add a bot message telling user we couldn't detect symptoms & ask to rephrase.
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          sender: ChatSender.bot,
          type: MessageType.text,
          text: "ฉันไม่พบอาการจากข้อความนั้น คุณช่วยอธิบายเพิ่มเติมได้ไหม?", // Thai
        ));
        notifyListeners();
      } else {
        // Convert mentions to evidence
        for (final m in parse.mentions) {
          _upsertEvidence(m.id, _inferChoiceFromParseMention(m), source: 'initial');
        }
        await _runDiagnosisCycle();
      }
    } catch (e) {
      addErrorMessage('เกิดข้อผิดพลาดในการวิเคราะห์ข้อความ: $e');
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _runDiagnosisCycle() async {
    _isBusy = true;
    notifyListeners();
    try {
      final dx = await service.diagnosis(
        evidence: _evidence,
        age: age,
        sex: sex,
        noGroups: true,
      );
      _lastDiagnosis = dx;

      if (dx.isFinished || questionCount >= 10) {
        final tx = await service.triage(
          evidence: _evidence, 
          age: age, 
          sex: sex
        );
        // ใส่ค่า triage ลงไปใน DiagnosisResult
        final updatedDx = DiagnosisResult(
          question: dx.question,
          conditions: dx.conditions,
          triage: tx,
        );
        _lastDiagnosis = updatedDx;

        final dataEvidence = await _MaptoCardForcardEvidence(updatedDx);
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          sender: ChatSender.bot,
          type: MessageType.cardEvidence,
          textreuslt : dataEvidence,
        ));

        // Show final diagnosis summary.
        // final summaryEn = _buildFinalSummaryText(updatedDx);
        final dataDiagnosis = await _MaptoCardForcardDiagnosis(updatedDx);
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          sender: ChatSender.bot,
          type: MessageType.cardDiagnosis,
          textreuslt: dataDiagnosis,
        ));


        final dataselfcare = await _MaptoCardForcardSuggest(updatedDx);
        _messages.add(ChatMessage(
          id: const Uuid().v4(), 
          sender: ChatSender.bot,
          type: MessageType.cardSuggest,
          textreuslt: dataselfcare,
        ));
        _messages.add(ChatMessage(
          id: const Uuid().v4(), 
          sender: ChatSender.bot,
          type: MessageType.cardMedicine,
          textreuslt: dataselfcare,
        ));
        
        saveMessagesToFirebase();

      } 
      else {
        // Show follow‑up question.
        final qTextEn = _buildQuestionDisplayText(dx.question!);
        final qTextTh = await llmsChangeEngToThai(qTextEn);
        // change to thai
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          sender: ChatSender.bot,
          type: MessageType.text,
          text: qTextTh,
        ));
        questionCount++;
      }
      notifyListeners();
    } catch (e) {
      addErrorMessage('เกิดข้อผิดพลาดในการเรียก diagnosis: $e');
      print('เกิดข้อผิดพลาดในการเรียก diagnosis: $e');
    } finally {
      _isBusy = false;
      notifyListeners();
      print(_isBusy);
    }
  }
  
  String _buildQuestionDisplayText(DiagnosisQuestion q) {
    // Example representation for chat.
    // For group questions, items could be multiple; we show bullet list.
    final buf = StringBuffer();
    buf.writeln(q.text);
    // if (q.items.isNotEmpty) {
    //   for (final item in q.items) {
    //     buf.writeln('- ${item.name}');
    //   }
    // }
    return buf.toString().trim();
  }

  Future<List<String>> collect_conditions_name(DiagnosisResult dx)async{
    List <String> c_thai_List = [];
    for (final i in dx.conditions.take(5)){
      String c_thai = await Terminology_medical_translate(i.name);
      c_thai_List.add(c_thai);
    }
    return c_thai_List ;
  }

  Future<Map<String, dynamic>> _MaptoCardForcardEvidence(DiagnosisResult dx) async {
    // ดึงข้อมูล concepts จาก service
    final concepts = await service.getConceptsByIds(
      _evidence.map((e) => e.id).toList(),
    );

    // สร้าง Map <id, common_name>
    final Map<String, String> commonNameMap = {
      for (final concept in concepts)
        concept['id']: concept['common_name'] ?? concept['name'],
    };

    // อัปเดต EvidenceItem แต่ละตัวให้มี common_name
    _evidence = _evidence.map((e) {
      return EvidenceItem(
        id: e.id,
        choice: e.choice,
        source: e.source,
        common_name: commonNameMap[e.id],
      );
    }).toList();

    // Debug print
    for (var e in _evidence) {
      print("id=${e.id}, choice=${e.choice}, common_name=${e.common_name}");
    }

    // สร้าง data สำหรับ card
    return {
      'title': "ข้อมูลอาการ",
      'evidences': _evidence.map((e) => {
        'id': e.id,
        'common_name': e.common_name ?? e.id,
        'choice': EvidenceItem._choiceToString(e.choice),
      }).toList(),
    };

  }

  
  Future<Map<String, dynamic >> _MaptoCardForcardDiagnosis (DiagnosisResult dx) async{
    List c_thai_List = await collect_conditions_name(dx);
    return {
      'title' : "คาดการณ์เบื้องต้น",
      'conditions': dx.conditions.take(5).map((c) => {
        'id': c.id,
        'name': c.name,
        'name_th': c_thai_List[dx.conditions.indexOf(c)],
        'probability': c.probability,
      }).toList(),
      'triage': dx.triage != null ? {
        'level': dx.triage!.level,
        'recommendation': dx.triage!.recommendation,
      } : null,
    };
  }

  Future<Map<String, dynamic>> _MaptoCardForcardSuggest(DiagnosisResult dx) async {
    // แปลง _evidence เป็น Map ที่ self_care_suggestion ต้องการ
    final List evidences = _evidence.map((e) => {
      'id': e.id,
      'common_name': e.common_name ?? e.id,
      'choice': EvidenceItem._choiceToString(e.choice),
    }).toList();

    final Map<String, dynamic> preparedData = {
      'title': "ข้อมูลอาการ",
      'evidences': evidences,
    };

    // เรียก self_care_suggestion พร้อมส่ง preparedData
    final result = await self_care_suggestion(
      dx,
      age,
      sex,
      medicalConditions,
      foodAllergies,
      preparedData,
    );

    try {
      // 🔹 ตัด ```json และ ``` ออก (ถ้า needed)
      String cleaned = result
          .toString()
          .replaceAll("```json", "")
          .replaceAll("```", "")
          .trim();
      final Map<String, dynamic> parsed = jsonDecode(cleaned);

      return {
        'title_suggest': "คำแนะนำ",
        'triage_level': parsed['triage_level'] ?? "-",
        'advice_list': parsed['advice_list'] ?? [],
        'title_medicine': "คำแนะนำการใช้ยา",
        'medicine_list': parsed['medicine_list'] ?? [],
      };
    } catch (e) {
      print("JSON parse error: $e");
      return {
        'title_suggest': "คำแนะนำ",
        'triage_level': "-",
        'advice_list': [],
        'title_medicine' : "",
        'medicine_list': [],
      };
    }
  }


  Future<EvidenceChoice?> _mapUserQuickAnswer(String text) async{
    final lastChatMessage = _messages.last;
    final lastQuestionText = lastChatMessage.text; 

    final prompt = """ จัดประเภทข้อความที่ผู้ใช้ป้อนว่าเป็นหนึ่งในคำสำคัญสำหรับ Infermedica EvidenceChoice ตามความหมาย:
      - ถ้าข้อความแสดงถึงความหมายเชิงบวกหรือการยืนยัน และเหมาะสมกับกรอบคำถาม ให้ตอบด้วย "present".
      - ถ้าข้อความแสดงถึงความหมายเชิงลบ การปฏิเสธ หรือไม่เหมาะสมกับกรอบคำถาม ให้ตอบด้วย "absent".
      - ถ้าข้อความแสดงถึงความไม่แน่ใจ ความสงสัย หรือไม่เกี่ยวข้องกับคำถามเลย ให้ตอบด้วย "unknown".

      ตัวอย่าง:
      - คำถาม: "คุณมีไข้ 37-38 องศาใช่หรือไม่?" → ผู้ใช้ตอบ "37.5" ถือว่า present.
      - คำถามเดียวกัน → ผู้ใช้ตอบ "35" ถือว่า absent.
      - คำถามเดียวกัน → ผู้ใช้ตอบ "dwasdkopj" หรือ "อาการดีอยู่" ถือว่า unknown.

      แสดงผลลัพธ์เป็นเพียงคำสำคัญเท่านั้น: present, absent, หรือ unknown.
      คำถามล่าสุดที่ถามผู้ใช้: $lastQuestionText
      ข้อความที่ผู้ใช้ป้อน: $text """;



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

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['candidates'] != null) {
    try {
      final text = data['candidates'][0]['content']['parts'][0]['text']
          .trim()
          .toLowerCase();

      switch (text) {
        case 'present':
          return EvidenceChoice.present;
        case 'absent':
          return EvidenceChoice.absent;
        case 'unknown':
          return EvidenceChoice.unknown;
        default:
          return null; // unexpected output
      }
    } catch (e) {
      print('Error parsing response: $e\n${response.body}');
      return null;
    }
  } else if (data['error'] != null) {
    print('Error: ${data['error']['message']}');
    return null;
  } else {
    print('Error: No candidates found\n${response.body}');
    return null;
  }
  }

  Future<void> saveMessagesToFirebase() async {
    final resultRef = FirebaseFirestore.instance.collection('messages').doc();
        print("create new document with ID: ${resultRef.id} success");

        // แปลง _messages เป็น list ของ Map ด้วย toMap()
        final messageMaps = _messages.map((msg) {
          return {
            'id': msg.id,
            'sender':msg.sender,
            'type': msg.type.name,
            'text': msg.text ?? '',
            'textreuslt': msg.textreuslt ?? {},
          };
        }).toList();
        print("transform _messages to Map success");

        await resultRef.set({
          'userId': UserId,
          'createdAt': FieldValue.serverTimestamp(),
          'result': messageMaps,
        });

        print('Saved result to Firestore with ID: ${resultRef.id}');
  }

}


