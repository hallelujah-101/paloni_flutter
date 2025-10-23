import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';


class BackendServices implements DisposableBuildContext{

  String _cloudRunHost = '';
  String _databaseId = '';
  String _collectionName = '';

  final remoteConfig = FirebaseRemoteConfig.instance;
  void getConfigs() async {
    
      await remoteConfig.fetchAndActivate();

      _cloudRunHost = remoteConfig.getString('cloudRunHost');
      _databaseId = remoteConfig.getString('databaseId');
      _collectionName = remoteConfig.getString('collectionName');
  }

  Future<void> initialiseConfigurations() async 
  {
      getConfigs();
  }

  final Client _client = http.Client();
  FirebaseFirestore get _database => FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: _databaseId);

   void updateMessages(String userId, String newMessage) {
      var documentReference = _database.collection(_collectionName).doc(userId);
      documentReference.set({"Message": newMessage}, SetOptions(merge: true));
  }

   Future<Response> askGemini(String userId, String text, List<MultipartFile> attachments) async
  {
      Uri endpoint = Uri.parse('$_cloudRunHost/ask_gemini');
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
