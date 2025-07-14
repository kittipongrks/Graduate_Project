import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class InfermedicaApi {
  final String apiModel;
  final String apiUrl;
  String? interviewId;

  InfermedicaApi({
    this.apiModel = 'infermedica-en',
    this.apiUrl = 'https://api.infermedica.com/v3/',
  });

  String get appId => dotenv.env['INFERMEDICA_APP_ID'] ?? '';
  String get appKey => dotenv.env['INFERMEDICA_APP_KEY'] ?? '';

  Future<http.Response> _request(
    String method,
    String url, {
    Map<String, dynamic>? data,
  }) async {
    final uri = Uri.parse('$apiUrl$url');

    final headers = {
      'Model': apiModel,
      'Content-Type': 'application/json',
    };

    if (interviewId != null) {
      headers['Interview-Id'] = interviewId!;
    }

    switch (method.toUpperCase()) {
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: json.encode(data),
        );
      case 'GET':
      default:
        return await http.get(uri, headers: headers);
    }
  }

  Future<dynamic> get(String url) async {
    final response = await _request('GET', url);
    return json.decode(response.body);
  }

  Future<dynamic> post(String url, Map<String, dynamic> data) async {
    final response = await _request('POST', url, data: data);
    return json.decode(response.body);
  }

  Future<dynamic> getRiskFactors(int ageValue) {
    return get('risk_factors?age.value=$ageValue');
  }

  Future<dynamic> parse(Map<String, dynamic> data) {
    return post('parse', data);
  }

  Future<dynamic> getSuggestedSymptoms(Map<String, dynamic> data) {
    return post('suggest', data);
  }

  Future<dynamic> diagnosis(Map<String, dynamic> data) {
    return post('diagnosis', data);
  }

  Future<dynamic> explain(Map<String, dynamic> data) {
    return post('explain', data);
  }
}
