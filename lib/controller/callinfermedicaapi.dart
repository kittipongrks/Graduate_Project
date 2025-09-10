import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dahcpplication/controller/gemini_generate.dart';
import 'package:dahcpplication/auth/database.dart';

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

enum MessageType { text, cardEvidence , cardDiagnosis ,cardSuggest, chart }

class ChatMessage {
  final String id;
  final MessageType type ;
  final ChatSender sender;
  final String? text;
  final Map<String, dynamic>? textreuslt;
  final Timestamp timestamp;
  final dynamic payload; // optional structured info (e.g., question, conditions)


  ChatMessage({
    required this.id,
    required this.sender,
    required this.type,
    this.text,
    this.textreuslt,
    Timestamp? timestamp,
    this.payload,
  }) : timestamp = timestamp ?? Timestamp.now();

  //Maping Chatsender to String for display
  Map<String , dynamic> toMap(){
    return {
      'senderID': id,
      'sender': sender,
      'type': type.name,
      'text': text,
      'textreuslt': textreuslt,
      'payload' : payload,
      'timestamp': timestamp,
    };
  }
}


// Representation of evidence item for Infermedica
class EvidenceItem {
  final String id; // symptom or risk factor ID from Infermedica
  final EvidenceChoice choice;
  final String? source; // 'initial', 'user', 'question', etc.

  EvidenceItem({required this.id, required this.choice ,this.source});

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
    print('DIAGNOSIS BODY => ${jsonEncode({
    'age': {'value': age, 'unit': 'year'},
    'sex': sex,
    'evidence': evidence.map((e) => e.toJson()).toList(),
  })}');

    final resp = await _client.post(uri, headers: _headers(), body: body);
    print(resp.body);
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
    print(resp.body);


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
  InfermedicaChatController({
    required this.service,
    int? age,
    String? sex,
    String? caseId,
    String? foodAllergies,
    String? medicalConditions,
  })  : age = age ?? defaultAge,
        sex = sex ?? defaultSex,
        foodAllergies = foodAllergies ?? defaultAllergies,
        medicalConditions = medicalConditions ?? defaultMedicalConditions,
        caseId = caseId ?? const Uuid().v4();
        

  final InfermedicaService service;
  int age ;
  String sex;
  String foodAllergies;
  String medicalConditions;
  final String caseId;

  Future<void> loadUserData() async {
    final userProfile = await fetchUserInfo();

    age = userProfile['age'] ?? defaultAge;
    sex = userProfile['sex'] ?? defaultSex;
    foodAllergies = userProfile['foodAllergies'] ?? defaultAllergies;
    medicalConditions = userProfile['medicalConditions'] ?? defaultMedicalConditions;
    print(age);
    print(sex);

    notifyListeners();
  }

  final List<ChatMessage> _messages = [];
  final List<EvidenceItem> _evidence = [];

  Map<String, dynamic> _evidence_common_name = {};

  bool _isBusy = false;
  DiagnosisResult? _lastDiagnosis;

  int questionCount = 0;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isBusy => _isBusy;
  DiagnosisResult? get lastDiagnosis => _lastDiagnosis;

  void addSystemMessage(String text) {
  bool _isLoading = true;
  notifyListeners();
  Future.delayed(Duration(seconds: 1), () { 
    _messages.add(ChatMessage(
      id: const Uuid().v4(), 
      sender: ChatSender.system,
      type: MessageType.text,
      text: text
      ));
    _isLoading = false; // Hide loading indicator after delay
    notifyListeners();
  });
}

void resetChat() {
  _messages.clear();
  _evidence.clear();
  _lastDiagnosis = null;
  questionCount = 0;
  _evidence_common_name.clear();
  _isBusy = false;
  notifyListeners();
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
    
  }
  void handleUserChoice(String choice) {
  if (_awaitingUserChoice) {
    _awaitingUserChoice = false;
    if (choice == "ถามต่อ") {
      _runDiagnosisCycle(); // ถามต่อ
    } else {
      _finishDiagnosis(_lastDiagnosis!); // หยุดแล้วสรุป
    }
  }
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
          payload: {'type': 'no_mentions'},
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

  int questionsInBatch = 0;     // จำนวนคำถามในรอบปัจจุบัน
  bool _awaitingUserChoice = false;

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

    // ถ้า service บอกว่าจบเอง → สรุปผลเลย
    if (dx.isFinished) {
      await _finishDiagnosis(dx);
      return;
    }

    // ถ้ายังไม่จบ → ถามคำถามใหม่
    final qTextEn = _buildQuestionDisplayText(dx.question!);
    final qTextTh = await llmsChangeEngToThai(qTextEn);
    _messages.add(ChatMessage(
      id: const Uuid().v4(),
      sender: ChatSender.bot,
      type: MessageType.text,
      text: qTextTh,
      payload: {'question': dx.question},
    ));

    notifyListeners();

  } catch (e) {
    addErrorMessage('เกิดข้อผิดพลาดในการเรียก diagnosis: $e');
  } finally {
    _isBusy = false;
    notifyListeners();
  }
}


Future<void> _finishDiagnosis(DiagnosisResult dx) async {
  final tx = await service.triage(
    evidence: _evidence,
    age: age,
    sex: sex,
  );

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
    textreuslt: dataEvidence,
  ));

  final dataDiagnosis = await _MaptoCardForcardDiagnosis(updatedDx);
  _messages.add(ChatMessage(
    id: const Uuid().v4(),
    sender: ChatSender.bot,
    type: MessageType.cardDiagnosis,
    textreuslt: dataDiagnosis,
    payload: {'diagnosis': updatedDx},
  ));

  final dataselfcare = await _MaptoCardForcardSuggest(updatedDx);
  _messages.add(ChatMessage(
    id: const Uuid().v4(),
    sender: ChatSender.bot,
    type: MessageType.cardSuggest,
    textreuslt: dataselfcare,
    payload: {'diagnosis': updatedDx},
  ));
}

  

  // ---------------------------------------------------------------------------
  // HELPER TEXT BUILDERS
  // ---------------------------------------------------------------------------

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

  Future<String> _buildFinalEvidenceText() async {
    final buf = StringBuffer();
    buf.writeln('ข้อมูลอาการ:');

    if (_evidence_common_name.isEmpty) {
      buf.writeln('- ไม่มีข้อมูลอาการ/ปัจจัยเสี่ยง');
    } else {
      // loop แต่ละประเภท evidence
      final Map<String, dynamic> evidences = _evidence_common_name;

      // supporting = +
      for (final e in List<Map<String, dynamic>>.from(evidences['supporting_evidence'] ?? [])) {
        buf.writeln('- ${e['common_name']}: +');
      }

      // conflicting = -
      for (final e in List<Map<String, dynamic>>.from(evidences['conflicting_evidence'] ?? [])) {
        buf.writeln('- ${e['common_name']}: -');
      }

      // unconfirmed = ?
      for (final e in List<Map<String, dynamic>>.from(evidences['unconfirmed_evidence'] ?? [])) {
        buf.writeln('- ${e['common_name']}: ?');
      }
    }

    buf.writeln('\n(นี่คือข้อมูลที่ใช้ในการประเมินอัตโนมัติ)');
    return buf.toString().trim();
  }
    Future<Map<String, dynamic >> _MaptoCardForcardEvidence (DiagnosisResult dx) async{
    return {
      'title' : "ข้อมูลอาการ",
      'evidences': _evidence_common_name,
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

  Future<Map<String , dynamic>> _MaptoCardForcardSuggest(DiagnosisResult dx) async {
  final something = await self_care_suggestion(
    dx, 
    age, 
    sex,
    medicalConditions, 
    foodAllergies, 
    _evidence_common_name,
  );

  try {
    // 🔹 ตัด ```json และ ``` ออก
    String cleaned = something
        .replaceAll("```json", "")
        .replaceAll("```", "")
        .trim();
  print(cleaned);
    final Map<String, dynamic> parsed = jsonDecode(cleaned);

    return {
      'title': "คำแนะนำ",
      'triage_level': parsed['triage_level'] ?? "-",
      'advice_list': parsed['advice_list'] ?? [],
    };
  } catch (e) {
    print("JSON parse error: $e");
    return {
      'title': "คำแนะนำ",
      'triage_level': "-",
      'advice_list': [],
    };
  }
}



  // ---------------------------------------------------------------------------
  // USER QUICK ANSWER MAPPING yes/no/maybe -> EvidenceChoice
  // ---------------------------------------------------------------------------

  Future<EvidenceChoice?> _mapUserQuickAnswer(String text) async{
    final lastChatMessage = _messages.last;
    final lastQuestionText = lastChatMessage.text; 
    print("----------------------------------------------------");
    print(lastQuestionText);

    final t = text.trim().toLowerCase();
    if (['y', 'yes', 'ใช่', 'มี', 'present', 'true', '1'].contains(t)) {
      return EvidenceChoice.present;
    }
    if (['n', 'no', 'ไม่', 'ไม่มี', 'absent', 'false', '0'].contains(t)) {
      return EvidenceChoice.absent;
    }
    if (['m', 'maybe', 'ไม่แน่ใจ', 'unknown', 'ไม่ทราบ' , 'อาจจะ'].contains(t)) {
      return EvidenceChoice.unknown;
    }

    final prompt = """ Classify the user input as one of these keywords for Infermedica EvidenceChoice based on its meaning:
      - If the input expresses a positive or affirmative meaning, respond with "present".
      - If the input expresses a negative or denial meaning, respond with "absent".
      - If the input expresses uncertainty or doubt, respond with "unknown".

      Only output the exact keyword: present, absent, or unknown.
      Last question asked to user: $lastQuestionText
      User input: $text """;

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
}
