import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';


class BackendServices implements DisposableBuildContext{

  static String cloudRunHost = '';
  static String databaseId = '';
  static String collectionName = '';

  void getConfigs() async {
    
      await remoteConfig.fetchAndActivate();

      cloudRunHost = remoteConfig.getString('cloudRunHost');
      databaseId = remoteConfig.getString('databaseId');
      collectionName = remoteConfig.getString('collectionName');
  }

  BackendServices()
  {
      getConfigs();
  }

  final Client _client = http.Client();
  final FirebaseFirestore _database = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: databaseId);
  final remoteConfig = FirebaseRemoteConfig.instance;

   void updateMessages(String userId, String newMessage) {
      var documentReference = _database.collection(collectionName).doc(userId);
      documentReference.set({"Message": newMessage}, SetOptions(merge: true));
  }

   Future<Response> askGemini(String userId, String text, List<MultipartFile> attachments) async
  {
      Uri endpoint = Uri.parse('$cloudRunHost/ask_gemini');
      MultipartRequest request = MultipartRequest('POST', endpoint);
      
      request.fields.addAll({'text':text, 'session_id':userId});
      request.files.addAll(attachments);
      request.headers.addAll({'Content-Type': 'multipart/form-data' ,'Connection': 'keep-alive','Accept': '*/*', 'Accept-Encoding': 'gzip, deflate, br', "Access-Control-Allow-Headers": "*"});

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
