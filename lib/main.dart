import 'package:uuid/uuid.dart';
import 'backend_services.dart';
import 'firebase_options.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
import 'package:flyer_chat_text_message/flyer_chat_text_message.dart';
import 'package:http/http.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class ChatPage extends StatefulWidget{
  const ChatPage({super.key});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final _chatController = InMemoryChatController();
  final _imageCache = List<String>.empty(growable: true);
  final _backendServices = BackendServices();

  final String _userId = Uuid().v4();

  @override
  void dispose() {
    _chatController.dispose();
    _backendServices.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    _backendServices.initialiseConfigurations();

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0.0, 
        backgroundColor: Theme.of(context).primaryColor, 
        flexibleSpace: FlexibleSpaceBar(background: Image.asset('assets/clothes_query_agent.png'), 
        centerTitle: true,), 
        toolbarHeight: 100
        ),
      body:  Chat(
        backgroundColor: Theme.of(context).primaryColor,
        chatController: _chatController,
        currentUserId: _userId,
        builders: Builders(
          customMessageBuilder: (context, message,index, 
          {
            required bool isSentByMe,
            MessageGroupStatus? groupStatus
          }) => 
          Column(
            spacing: 2, 
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              Image.network(message.metadata?['imageUrl'], 
                            fit: BoxFit.contain, 
                            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) 
                            { return Image.asset('assets/clothes_query_agent_error.png');}), 
              Text(message.metadata?['productName']),
              Text(message.metadata?['description'])
                        ]
          ),
          imageMessageBuilder: (context, message, index, {
            required bool isSentByMe,
            MessageGroupStatus? groupStatus,
          }) =>
            FlyerChatImageMessage(message: message, index: index),
          textMessageBuilder: (context, message, index, {
            required bool isSentByMe,
            MessageGroupStatus? groupStatus,
          }) =>
            FlyerChatTextMessage(
              message: message, 
              index: index, 
              receivedBackgroundColor: Color.fromARGB(127, 255, 69, 127), 
              sentBackgroundColor: const Color.fromARGB(127, 201, 197, 209),
            ),
        ),
        onAttachmentTap: () async {

            getImage().then(
              (image) {
                  if(image != null) {
                    addToCache(_imageCache, image);
                    
                    final imageMessage = message(image.path, ImageMessage);
                    _chatController.insertMessage(imageMessage);
                }
              }
            );
            
        },
        onMessageSend: (text) {
              
          _chatController.insertMessage(
            message(text, TextMessage)
          );

          var attachments = getAttachments();
          var request = _backendServices.askGemini(_userId, text, attachments);

          request.then((response){
            processGeminiResponse(response.body);
          });

          _imageCache.clear();
        },
        resolveUser: (UserID id) async {
          return User(id: id);
        },
      ),
    );
  }


  Message message(message, type)
  {

    if(type == ImageMessage)
    {
      return ImageMessage(
                id: Uuid().v1(),
                authorId: _userId,
                createdAt: DateTime.now().toUtc(),
                source: message,
              );
    }
    else if (type == CustomMessage)
    {
      return CustomMessage(
              id: Uuid().v1(),
              authorId: "Gemini",
              createdAt: DateTime.now().toUtc(),
              metadata: message,
            );
    }
    
    return  TextMessage(
            id: Uuid().v1(),
            authorId: _userId,
            createdAt: DateTime.now().toUtc(),
            text: message,
          );
  }

  void addToCache(List<String> cache, XFile image){

     image.readAsBytes().then(
      (bytes) { 
        String base64String = base64.encode(bytes);
        _imageCache.add(base64String); }
    );
  }

  Future<XFile?> getImage() async
  {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    return image;
  }

  List<MultipartFile> getAttachments()
  {
    var attachments = List<MultipartFile>.empty(growable: true);
    
    for (String imageByte in _imageCache)
    {
      attachments.add(http.MultipartFile.fromString('attachments', imageByte));
    }

    return attachments;
  }

  RegExpMatch? getReponseObject(String response)
  {
    var responseObject = RegExp(r'{.*}');
    return responseObject.firstMatch(response);
  }

  void processGeminiResponse(String response)
  {
    var responseObject = getReponseObject(response);

    if(responseObject != null)
    {
      var responseBody = Map<String, dynamic>.fromEntries({});
      var responseString = responseObject[0];
      responseBody = jsonDecode(responseString!);

       _chatController.insertMessage(message(responseBody['text'], TextMessage));

      var products = responseBody['products'];

      if(products.isNotEmpty){
        for (var product in products){
            var metadata = {"name": product['name'], "description": product['description'],  "imageUrl": _backendServices.getImagePath(product)};
            _chatController.insertMessage(message(metadata, CustomMessage));
        }
      }
    }
  }

}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  static const String title = "Shopper";
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopper',
      theme: ThemeData(
        primaryColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      home: ChatPage(),
    );
  }
}




