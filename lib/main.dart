import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'config.dart';
import 'firebase_options.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
import 'package:http/http.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final _chatController = InMemoryChatController();
  final _imageCache = List<String>.empty(growable: true);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  var userID = Uuid().v4();
  var client = http.Client();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Chat(
        chatController: _chatController,
        currentUserId: userID,
        builders: Builders(
          imageMessageBuilder: (context, message, index, {
            required bool isSentByMe,
            MessageGroupStatus? groupStatus,
          }) =>
            FlyerChatImageMessage(message: message, index: index),
        ),
        onAttachmentTap: () async {

            final ImagePicker picker = ImagePicker();
            final XFile? image = await picker.pickImage(source: ImageSource.gallery);

            if(image != null) {

              image.readAsBytes().then(
                
                (bytes) { 
                  String base64String = base64.encode(bytes);
                  _imageCache.add(base64String); }
                );

              final imageMessage = ImageMessage(
                                      id: Uuid().v1(),
                                      authorId: userID,
                                      createdAt: DateTime.now().toUtc(),
                                      source: image.path,
                                    );
            
            _chatController.insertMessage(imageMessage);
          }
        },
        onMessageSend: (text) {
          _chatController.insertMessage(
            TextMessage(
              id: Uuid().v1(),
              authorId: userID,
              createdAt: DateTime.now().toUtc(),
              text: text,
            ),
          );

            var attachments = List<MultipartFile>.empty(growable: true);
            for (String imageByte in _imageCache)
            {
              attachments.add(http.MultipartFile.fromString('attachments', imageByte));
            }

            updateMessages('text: $text attachments: $attachments');

            var request = askGemini(text, attachments);

        
            request.then((responseBody){
              var response = json.decode(responseBody)['output'];
              
              _chatController.insertMessage(
                TextMessage(
                  id: Uuid().v1(),
                  authorId: "Gemini",
                  createdAt: DateTime.now().toUtc(),
                  text: response,
                )
              );
              
              updateMessages('$response');
              });

              _imageCache.clear();
        },
        resolveUser: (UserID id) async {
          return User(id: id);
        },
      ),
    );
  }

  Future<String> askGemini(String text, List<MultipartFile> attachments) async
  {
    Uri endpoint = Uri.parse('$cloudRunHost/ask_gemini');
    MultipartRequest request = MultipartRequest('POST', endpoint);
    
    request.fields.addAll({'text':text, 'session_id':userID});
    request.files.addAll(attachments);
    request.headers.addAll({'Content-Type': 'multipart/form-data' ,'Connection': 'keep-alive','Accept': '*/*', 'Accept-Encoding': 'gzip, deflate, br'});

    var streamedResponse = await client.send(request);
    var response = await http.Response.fromStream(streamedResponse);
    
    return response.body;
  }

  Future<void> updateMessages(String newMessage) async {
              await _firestore.collection(collectionName).doc(documentName).update({
                      'Message': newMessage,
                    });
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: ChatPage(),
    );
  }
}




