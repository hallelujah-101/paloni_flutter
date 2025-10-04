import 'config.dart';
import 'firebase_options.dart';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:flutter/material.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String title = 'Flutter Demo';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: GeminiChatPage(),
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
        model: FirebaseAI.vertexAI().generativeModel(model: 'gemini-2.5-flash', tools: [Tool.functionDeclarations([declaration('askAgent', 'Pass query to agent'), declaration('searchDatabase', 'Pass query to database')])]),
      ),
    ),
  );

  
  static  FunctionDeclaration declaration(name, description){
    Schema schema = Schema.string();

    return FunctionDeclaration(
            name,
            description,
            parameters: Map<String, Schema>.fromIterables(['prompt'], [schema])
          );
  }

  static Future<String> askAgent(prompt) async {

    Uri endpoint = Uri.https(cloudRunHost, '/ask_gemini/', {'query' :prompt.toString()});
    var response = await http.get(endpoint);

    if(response.statusCode == 200)
    {
        return response.body;
    }

    return response.statusCode.toString();
  }

  static Future<String> searchDatabase(prompt) async {

    Uri endpoint = Uri.https(cloudRunHost, '/search_db/', {'query' :prompt.toString()});
    var response = await http.get(endpoint);

    if(response.statusCode == 200)
    {
        return response.body;
    }
    
    return response.statusCode.toString();
  }

}

class Prompt {
  String? text;
  Iterable<FileAttachment> attachments = Iterable.empty();
}    




