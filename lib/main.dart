import 'package:uuid/uuid.dart';
import 'config.dart';
import 'firebase_options.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

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
        onMessageSend: (text) {
          _chatController.insertMessage(
            TextMessage(
              id: Uuid().v1(),
              authorId: userID,
              createdAt: DateTime.now().toUtc(),
              text: text,
            ),
          );

          int messagesSize = _chatController.messages.length - 1;
          Message lastMessage = _chatController.messages[messagesSize];
          String lastText = lastMessage.toJson()['text'];
         
          askGemini(lastText).then((responseBody)
          {
            var response = jsonDecode(responseBody)['output'];

            _chatController.insertMessage(
            TextMessage(
              id: Uuid().v1(),
              authorId: "Gemini",
              createdAt: DateTime.now().toUtc(),
              text: response,
            ));
          
          });
        },
        resolveUser: (UserID id) async {
          return User(id: id);
        },
      ),
    );
  }

  Future<String> askGemini(String prompt) async
  {
    Uri endpoint = Uri.parse('$cloudRunHost/ask_gemini?query=$prompt');

    var response = await client.get(endpoint, headers: {'Connection': 'keep-alive','Accept': '*/*', 'Accept-Encoding': 'gzip, deflate, br'});
    return response.body;
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




