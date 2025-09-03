import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

// --- Tools (functions) ---
String function1() {
  return "✅ เรียก function1: ข้อมูลสภาพอากาศวันนี้";
}

String function2() {
  return "✅ เรียก function2: เวลาปัจจุบันคือ ...";
}

// --- Agent (Generative-based) ---
Future<String> agent(String userInput) async {
  final model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: "AIzaSyDZWPTPjfbZbCzewYN04-zzW8dCuiTna_k",
  );

  // Prompt: บังคับให้ Gemini ตอบเป็น JSON
  final prompt = """
  คุณคือระบบจัดการ Tools
  User จะถามคำถาม
  คุณต้องตอบกลับเป็น JSON เท่านั้น โดยมีรูปแบบ:
  {
    "call": "function1" | "function2" | "none",
    "args": {}
  }

  function1 = ใช้เมื่อเกี่ยวกับอากาศ
  function2 = ใช้เมื่อเกี่ยวกับเวลา
  none = ถ้าไม่ต้องใช้ tools
""";

  final response = await model.generateContent([
    Content.text("$prompt\n\nUser: $userInput")
  ]);

  final output = response.text ?? "{}";

  final cleaned = output
    .replaceAll("```json", "")
    .replaceAll("```", "")
    .trim();

  try {
    final data = jsonDecode(cleaned);

    final call = data["call"];
    if (call == "function1") return function1();
    if (call == "function2") return function2();
    return "🤖 Gemini: $userInput → ไม่ต้องใช้ Tools";
  } catch (e) {
    return "❌ Parse JSON error: $output";
  }
}

// --- Example Run ---
void main() async {
  print(await agent("ตอนนี้อากาศเป็นยังไงบ้าง"));   // → function1
  print(await agent("ตอนนี้กี่โมงแล้ว"));          // → function2
  print(await agent("เล่าเรื่องตลกหน่อย"));       // → Gemini จะตอบ none
}
