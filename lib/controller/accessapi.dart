// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:dahcpplication/controller/gemini_generate.dart';

// String infermedica_url = 'https://api.infermedica.com/v3/';

// Map<String , String> _remote_headers(String appId , String appKey , String? case_id){
//   final header = {
//     'Content-Type':'application/json',
//     'Accept':'application/json',
//     'App-Id':appId,
//     'App-Key':appKey,
//     'Dev-Mode':'true',
//     };
//     if (case_id != null && case_id.isNotEmpty) {
//       header['Interview-Id'] = case_id;
//     }
//     return header;
// }

// Future<dynamic> call_endpoint(
//   String endpoint , 
//   String appId , 
//   String appKey , 
//   Map<String , dynamic>? params , 
//   Map<String , dynamic>? request_spec , 
//   String? case_id ) async
//   {
//   final url = Uri.parse(infermedica_url + endpoint);
//   final headers = _remote_headers(appId, appKey, case_id);
//   http.Response resp;
//   if (request_spec != null){
//     resp = await http.post(
//       url, 
//       headers: headers,
//       body:utf8.encode(jsonEncode(request_spec)),
//       );
//   }else{
//     resp = await http.get(
//       url, 
//       headers: headers,
//       );
//   }
//   print(url);
//   print(headers);
//   print(jsonEncode(request_spec));
//   print(jsonDecode(resp.body));
//   if (resp.statusCode < 200 || resp.statusCode >= 300) {
//     throw Exception('API Error: ${resp.statusCode} ${resp.body}');
//   }
//   return jsonDecode(resp.body);
// }

// Future<dynamic> call_diagnosis(
//   List<Map<String , dynamic>> evidence , 
//   int age , 
//   String sex , 
//   String case_id , 
//   String appId , 
//   String appKey , {
//   bool noGroups = true,
//   String? languageModel,
//   }) async{
//     final request_spec = {
//       'age': {'value': age , 'unit': 'year'},
//       'sex': sex.toLowerCase(),
//       'evidence': evidence,
//       'extras':{
//         'disble_groups': noGroups,
//       }
//     };
//     return await call_endpoint(
//       'diagnosis',
//       appId,
//       appKey,
//       null, // params
//       request_spec,
//       case_id,
//     );
// }

// Future<dynamic> call_triage(
//   List<Map<String, dynamic>> evidence,
//   int age,
//   String sex,
//   String case_id,
//   String appId,
//   String appKey, {
//   String? languageModel,
// }) async {
//   final request_spec = {
//     'age': {'value': age , 'unit': 'year'},
//     'sex': sex.toLowerCase(),
//     'evidence': evidence,
//   };

//   return await call_endpoint(
//     'triage',
//     appId,
//     appKey,
//     null, // params
//     request_spec,
//     case_id,
//   );
// }

// Future<dynamic> call_parse(
//   int age,
//   String sex,
//   String text,
//   String appId,
//   String appKey,
//   String case_id, {
//   List<String> conversationContext = const [],
//   List<String> conc_types = const ['symptom', 'risk_factor'],
//   String? languageModel,
// }) async {
//   final request_spec = {
//     'age': {'value': age , 'unit': 'year'},
//     'sex': sex.toLowerCase(),
//     'text': text.replaceAll('\n', '').trim().toLowerCase(),
//     'context': conversationContext,
//     'include_tokens': true,
//     'concept_types': conc_types,
//     if (languageModel != null) 'model': languageModel,
//   };
//   print("JSON Request: ${jsonEncode(request_spec)}");
//   return await call_endpoint(
//     'parse',
//     appId,
//     appKey,
//     null, // params
//     request_spec,
//     case_id,
//   );
// }

// Future<Map<String, String>> getObservationNames(
//   Map<String, dynamic> age,
//   String appId,
//   String appKey,
//   String case_id, 
//   String? languageModel,
// ) async {
//   // ดึง risk factors
//   final riskFactors = await call_endpoint(
//     'risk_factors',
//     appId,
//     appKey,
//     {
//       'age.value': age['value'],
//       'age.unit': age['unit'],
//     },
//     null,
//     case_id,
//   );

//   // ดึง symptoms
//   final symptoms = await call_endpoint(
//     'symptoms',
//     appId,
//     appKey,
//     {
//       'age.value': age['value'],
//       'age.unit': age['unit'],
//     },
//     null,
//     case_id,
//   );

//   // รวมข้อมูลทั้งหมด
//   final obsStructs = <dynamic>[];
//   obsStructs.addAll(riskFactors);
//   obsStructs.addAll(symptoms);

//   // คืนค่าเป็น Map<id, name>
//   return {
//     for (final struct in obsStructs)
//       if (struct['id'] != null && struct['name'] != null)
//         struct['id']: struct['name']
//   };
// }

// void nameEvidence(List<Map<String, dynamic>> evidence, Map<String, String> naming) {
//   for (final piece in evidence) {
//     if (piece.containsKey('id') && naming.containsKey(piece['id'])) {
//       piece['name'] = naming[piece['id']];
//     }
//   }
// }

// List<Map<String, dynamic>> mentionsToEvidence(List<Map<String, dynamic>> mentions) {
//   return [
//     for (final m in mentions)
//       {
//         'id': m['id'],
//         'choice_id': m['choice_id'],
//         'source': 'initial',
//       }
//   ];
// }

// List<Map<String, dynamic>> questionAnswerToEvidence(
//   Map<String, dynamic> questionStructItem,
//   String observationValue,
// ) {
//   return [
//     {
//       'id': questionStructItem['id'],
//       'choice_id': observationValue,
//     }
//   ];
// }