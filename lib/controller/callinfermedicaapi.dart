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




// -----------------------------------------------------------------------------
// CHAT MODELS
// -----------------------------------------------------------------------------

enum ChatSender { user, bot, system, error }

enum EvidenceChoice { present, absent, unknown }

class ChatMessage {
  final String id;
  final ChatSender sender;
  final String text;
  final Timestamp timestamp;
  final dynamic payload; // optional structured info (e.g., question, conditions)


  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    Timestamp? timestamp,
    this.payload,
  }) : timestamp = timestamp ?? Timestamp.now();

  //Maping Chatsender to String for display
  Map<String , dynamic> toMap(){
    return {
      'senderID': id,
      'sender': sender,
      'message': text,
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
  final double probability;
  DiagnosisCondition({required this.id, required this.name, required this.probability});
  factory DiagnosisCondition.fromJson(Map<String, dynamic> json) => DiagnosisCondition(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Unknown',
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
  })  : age = age ?? defaultAge,
        sex = sex ?? defaultSex,
        caseId = caseId ?? const Uuid().v4();

  final InfermedicaService service;
  final int age;
  final String sex;
  final String caseId;

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
    _messages.add(ChatMessage(id: const Uuid().v4(), sender: ChatSender.system, text: text));
    _isLoading = false; // Hide loading indicator after delay
    notifyListeners();
  });
}

  void addErrorMessage(String text) {
    _messages.add(ChatMessage(id: const Uuid().v4(), sender: ChatSender.error, text: text));
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
    _messages.add(ChatMessage(id: const Uuid().v4(), sender: ChatSender.user, text: rawUserText));
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

      if (dx.isFinished || questionCount >= 1) {
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
        

        _evidence_common_name = await service.explain(
          evidence: _evidence,
          age: age,
          sex: sex,
          target: _lastDiagnosis?.conditions.first.id ?? '',);
        print(_evidence_common_name);

        final getevidenceText = await _buildFinalEvidenceText();
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          sender: ChatSender.bot,
          text : getevidenceText,
        ));

        // Show final diagnosis summary.
        final summaryEn = _buildFinalSummaryText(updatedDx);
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          sender: ChatSender.bot,
          text: await summaryEn,
          payload: {'diagnosis': updatedDx},
        ));
      } 
      
      
      
      else {
        // Show follow‑up question.
        final qTextEn = _buildQuestionDisplayText(dx.question!);
        final qTextTh = await llmsChangeEngToThai(qTextEn);
        // change to thai
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          sender: ChatSender.bot,
          text: qTextTh,
          payload: {'question': dx.question},
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
  
  Future<void> _calltriage() async {

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

  Future<String> _buildFinalSummaryText(DiagnosisResult dx) async{
    final buf = StringBuffer();
    buf.writeln('สรุปผลเบื้องต้น:');
    buf.writeln('มีโอกาสเป็น:');
    if (dx.conditions.isEmpty) {
      buf.writeln('- ไม่พบโรคที่เป็นไปได้ (ข้อมูลไม่เพียงพอ)');
    } else {
      final c_thai_list = await collect_conditions_name(dx);

        // Loop through both lists simultaneously using an index
        for (int i = 0; i < dx.conditions.take(5).length; i++) {
          final c = dx.conditions[i];
          final c_thai = c_thai_list[i];
          final pct = (c.probability * 100).toStringAsFixed(1);
          
          buf.writeln('\n- ${c.name}: ${c_thai} ประมาณ:${pct}%');
        }
      
    }
    if (dx.triage != null) {
      buf.writeln('\nระดับคำแนะนำ: ${dx.triage!.level}');
      if (dx.triage!.recommendation != null) {
        buf.writeln(dx.triage!.recommendation!);
      }
    }
    buf.writeln('\n(นี่คือการประเมินอัตโนมัติ ไม่ใช่วินิจฉัยจากแพทย์จริง)');
    return buf.toString().trim();
  }

  Future<String> _buildFinalSelfCare(DiagnosisResult dx) async{
    if(dx.triage!= null){
      switch(dx.triage){
        case "self_care":
            
          break;
        case "consultions":

          break;
        case "emergency":

          break;
        default:

          break;
      }
    }
    final buf = StringBuffer();
    return buf.toString().trim();
  }


  // ---------------------------------------------------------------------------
  // USER QUICK ANSWER MAPPING yes/no/maybe -> EvidenceChoice
  // ---------------------------------------------------------------------------

  Future<EvidenceChoice?> _mapUserQuickAnswer(String text) async{
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
