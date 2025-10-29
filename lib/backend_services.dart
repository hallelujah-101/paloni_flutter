import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';


class BackendServices implements DisposableBuildContext{

  String _cloudRunHost = Characters.empty.toString();
  
  final _remoteConfig = FirebaseRemoteConfig.instance;
  final Client _client = http.Client();

  Future<void> initialiseConfigurations() async 
  {
     await _remoteConfig.fetchAndActivate();
      _cloudRunHost = _remoteConfig.getString('cloudRunHost');
  }

  Future<Response> askGemini(String userId, String text, List<MultipartFile> attachments) async
  {
      MultipartRequest request = buildPostRequest(userId, text, attachments);

      var streamedResponse = await _client.send(request);
      var response = await http.Response.fromStream(streamedResponse);

      return response;
  }


  MultipartRequest buildPostRequest(String userId, String text, List<MultipartFile> attachments)
  {
    Uri endpoint = Uri.parse('$_cloudRunHost/ask_gemini');
    Map<String, String> fields = {'text':text, 'session_id':userId};
    var headers = { 'Content-Type': 'multipart/x-www-form-urlencoded' ,
                    'Connection': 'keep-alive',
                    'Access-Control-Allow-Origin':'*',
                    'Access-Control-Allow-Methods': 'GET,PUT,PATCH,POST,DELETE',
                    'Accept-Encoding': '*', 
                    'Access-Control-Allow-Headers': 'Access-Control-Allow-Origin, Origin, X-Requested-With, Content-Type, Accept'
                    };

    MultipartRequest request = MultipartRequest('POST', endpoint);
    request.fields.addAll(fields);
    request.files.addAll(attachments);
    request.headers.addAll(headers);
        
    return request;
  }
  
  @override
  BuildContext? get context => context;
  
  @override
  void dispose() {
    dispose();
  }
  
}
