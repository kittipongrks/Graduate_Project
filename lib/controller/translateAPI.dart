import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> translateText() async {
  final url = Uri.parse("http://localhost:5000/translate");

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "q": "",
      "source": "auto",
      "target": "en",
      "format": "text",
      "alternatives": 3,
      "api_key": ""
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print(data);
  } else {
    print("Error: ${response.statusCode}");
  }
}
