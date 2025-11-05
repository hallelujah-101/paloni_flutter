import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';


class BackendServices implements DisposableBuildContext{

  String _cloudRunHost = Characters.empty.toString();
  String storagePath = Characters.empty.toString();

  final _remoteConfig = FirebaseRemoteConfig.instance;
  final Client _client = http.Client();

  Future<void> initialiseConfigurations() async 
  {
     await _remoteConfig.fetchAndActivate();
      _cloudRunHost = _remoteConfig.getString('cloudRunHost');
      storagePath = _remoteConfig.getString('storagePath');
  }

  
  Future<Response> askGemini(String userId, String text, List<MultipartFile> attachments) async
  {
      MultipartRequest request = buildPostRequest(userId, text, attachments);

      var streamedResponse = await _client.send(request);
      var response = await http.Response.fromStream(streamedResponse);
      return response;
  }

  String getImagePath(Map<String, dynamic> product)
  {
    var file = product['Image'];
    var category = product['category'];
    var gender = product['gender'];

    return "$storagePath/$category/$gender/$file";
  }


  MultipartRequest buildPostRequest(String userId, String text, List<MultipartFile> attachments)
  {
    Uri endpoint = Uri.parse('$_cloudRunHost/ask_gemini');
    Map<String, String> fields = {'text':text, 'session_id':userId};
    var headers = {'Content-Type': 'multipart/form-data' ,
                    'Connection': 'keep-alive',
                    'Accept': '*/*', 
                    'Accept-Encoding': 'gzip, deflate, br'
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
