import 'package:flutter/widgets.dart';

import 'config.dart';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class BackendServices implements DisposableBuildContext{
  
  static final Client _client = http.Client();
  static final FirebaseFirestore _database = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: databaseId);

  static void updateMessages(String userId, String newMessage) {
      var documentReference = _database.collection(collectionName).doc(userId);
      documentReference.set({"Message": newMessage}, SetOptions(merge: true));
  }

  static Future<Response> askGemini(String userId, String text, List<MultipartFile> attachments) async
  {
      Uri endpoint = Uri.parse('$cloudRunHost/ask_gemini');
      MultipartRequest request = MultipartRequest('POST', endpoint);
      
      request.fields.addAll({'text':text, 'session_id':userId});
      request.files.addAll(attachments);
      request.headers.addAll({'Content-Type': 'multipart/form-data' ,'Connection': 'keep-alive','Accept': '*/*', 'Accept-Encoding': 'gzip, deflate, br'});

      var streamedResponse = await _client.send(request);
      var response = await http.Response.fromStream(streamedResponse);

      return response;
  }
  
  @override
  BuildContext? get context => context;
  
  @override
  void dispose() {
    dispose();
  }
}
