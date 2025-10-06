import 'config.dart';
import 'firebase_options.dart';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
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

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Chat(
        chatController: _chatController,
        currentUserId: 'user1',
        onMessageSend: (text) {
          _chatController.insertMessage(
            TextMessage(
              // Better to use UUID or similar for the ID - IDs must be unique
              id: '${Random().nextInt(1000) + 1}',
              authorId: 'user1',
              createdAt: DateTime.now().toUtc(),
              text: text,
            ),
          );

          var messagesSize = _chatController.messages.length - 1;
          var lastMessage = _chatController.messages[messagesSize];
          var lastText = lastMessage.toJson()['text'];
          debugPrint("Query: $lastText");

          String response = "No response";
          try
          {
            var getresponse = queryEndpoints('ask_gemini', lastText).then((text) {response = text;});
          }
          catch(e)
          {
              debugPrint(e.toString());
          }

          _chatController.insertMessage(
            TextMessage( // Better to use UUID or similar for the ID - IDs must be unique
              id: '${Random().nextInt(1000) + 1}',
              authorId: 'Gemini',
              createdAt: DateTime.now().toUtc(),
              text: response,
              )
          );
        },
        resolveUser: (UserID id) async {
          return User(id: id, name: 'John Doe');
        },
      ),
    );
  }

  static Future<String> queryEndpoints(String endpointName, String prompt) async 
  {
    Uri endpoint = Uri.https(cloudRunHost, "/$endpointName", {"query" :prompt});
    var response = await http.get(endpoint);

    if(response.statusCode == 200)
    {
        var result = response.body;
        return result;
    } 

    return response.statusCode.toString();
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

class GeminiChatPage extends StatelessWidget {
  const GeminiChatPage({super.key});
 
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(MyApp.title)),
    body: LlmChatView(
      provider: FirebaseProvider( // use FirebaseProvider and vertexAI()
        model: FirebaseAI.googleAI().generativeModel(
          model: model, 
          systemInstruction: Content.text('You are a kind and funny commercial conversational agent.'),
          // tools: [
          //   Tool.functionDeclarations([getDeclaration('queryDatabaseGemini', 'Pass query to gemini model')])
          // ]
          ),
      ),
    ),
  );

  
  static  FunctionDeclaration getDeclaration(String name, String description){
    var names = ['text', 'attachments'];
    var schemas = [Schema.string(), Schema.array(items:Schema.integer())];
    Schema schema = Schema.object(properties: Map<String, Schema>.fromIterables(names, schemas));
    
    return FunctionDeclaration(
            name,
            description,
            parameters: Map<String, Schema>.fromIterables(['prompt'], [schema])
          );
  }

  static Future<String> queryEndpoints(String endpointName, String prompt) async 
  {
    Uri endpoint = Uri.https(cloudRunHost, "/$endpointName", {"text": prompt});
    var response = await http.get(endpoint);

    if(response.statusCode == 200)
    {
        debugPrint("gemini response:${response.body}");
        var result = response.body;
        return result;
    } 

    return response.statusCode.toString();
  }

  static Future<String> queryDatabaseGemini(String prompt) async 
  {
    debugPrint("gemini request:${prompt}");
    return queryEndpoints('search_database', prompt);
  }
}

class Prompt {
  String? text;
  Iterable<FileAttachment> attachments = Iterable.empty();
  
  Prompt(String text, Iterable<FileAttachment> attachments)
  {
    this.text = text;
    this.attachments = attachments;
  }

  @override
  String toString()
  {
    var attachmentsBytes = attachments.map((a)=> a.bytes);
    var attachmentString = attachmentsBytes.join(" ");

    return "$text $attachmentString";
  }
}    




