import 'package:uuid/uuid.dart';
import 'package:dahcpplication/controller/accessapi.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dahcpplication/controller/gemini_generate.dart';
import 'package:flutter/foundation.dart';

Future<dynamic> getApiInfermedica() async{
  final appId = dotenv.env['INFERMEDICA_APP_ID'];
  final appKey = dotenv.env['INFERMEDICA_APP_KEY'];
  if (appId == null || appKey == null) {
    throw Exception('Infermedica API credentials are not set in .env file');
  }
  return {'appId': appId, 'appKey': appKey};
}

Future<String>continoudiagnosis() async {
  

  return 'การวินิจฉัยต่อเนื่อง';
}