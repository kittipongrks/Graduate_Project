import 'package:flutter/material.dart';

enum EvidenceChoice { present, absent, unknown}

class RiskFactorsPage extends StatefulWidget {
  const RiskFactorsPage({super.key});

  @override
  State<RiskFactorsPage> createState() => _RiskFactorsPageState();
}

class _RiskFactorsPageState extends State<RiskFactorsPage> {
  // Map เก็บผลเลือกของแต่ละ item
  Map<String, EvidenceChoice> _responses = {};

  // List ของคำถาม (id, display name)
  final List<Map<String, String>> questions = [
    {"id": "p_smoking", "name": "ท่านสูบบุหรี่หรือไม่"},
    {"id": "p_alcohol", "name": "ดื่มแอลกอฮอล์"},
    {"id": "p_pregnant", "name": "ตั้งครรภ์"},
    {"id": "p_diabetes", "name": "โรคเบาหวาน"},
    {"id": "p_hypertension", "name": "โรคความดันสูง"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("แบบสอบถามสุขภาพเบื้องต้น")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...questions.map((q) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q["name"]!,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: EvidenceChoice.values.map((choice) {
                          final label = _labelForChoice(choice);
                          return RadioListTile<EvidenceChoice>(
                            value: choice,
                            groupValue: _responses[q["id"]],
                            title: Text(label),
                            onChanged: (v) {
                              setState(() {
                                _responses[q["id"]!] = v!;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // ส่งข้อมูลนี้ต่อไปให้ Infermedica (map id + choice_id)
              final mappedEvidence = _responses.entries.map((e) {
                return {
                  "id": e.key,
                  "choice_id": _mapChoiceToString(e.value)
                };
              }).toList();

              print(mappedEvidence); // debug print
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("บันทึกข้อมูลเรียบร้อย")));
            },
            child: const Text("บันทึก"),
          )
        ],
      ),
    );
  }

  String _labelForChoice(EvidenceChoice choice) {
    switch (choice) {
      case EvidenceChoice.present:
        return "มี/ใช่";
      case EvidenceChoice.absent:
        return "ไม่มี/ไม่ใช่";
      case EvidenceChoice.unknown:
        return "ไม่แน่ใจ/ไม่ต้องการระบุ";
    }
  }

  String _mapChoiceToString(EvidenceChoice choice) {
    switch (choice) {
      case EvidenceChoice.present:
        return "present";
      case EvidenceChoice.absent:
        return "absent";
      case EvidenceChoice.unknown:
        return "unknown";
    }
  }
}
