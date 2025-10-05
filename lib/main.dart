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

  static const String title = "Shopper";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopper',
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
        model: FirebaseAI.vertexAI().generativeModel(
          model: 'gemini-2.5-flash', 
          systemInstruction: Content.text('You are a kind and funny commercial conversational agent. You will pass the prompt to your query gemini tool and use the results to form a user friendly reply. The prompts could be multimodal and the endpoints can accomodate and provide responses for all types.'),
          tools: [
            Tool.functionDeclarations([getDeclaration('queryGemini', 'Pass query to gemini model')]
          )]),
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
            parameters: Map<String, Schema>.fromIterables(['endpointName', 'prompt'], [Schema.string(),schema])
          );
  }

  static Future<String> queryEndpoints(String endpointName, Prompt prompt) async 
  {
    Uri endpoint = Uri.https(cloudRunHost, "/$endpointName", {'query' :prompt.toJson()});
    var response = await http.get(endpoint);

    if(response.statusCode == 200)
    {
        return response.body;
    }

    return response.statusCode.toString();
  }

  static Future<String> queryGemini(String endpointName, Prompt prompt) async 
  {
    return queryEndpoints('ask_gemini', prompt);
  }
}

class Prompt {
  String? text;
  Iterable<FileAttachment> attachments = Iterable.empty();

  Map<String, dynamic> toJson()
  {
    return {'text': text, 'attachments': attachments.map((a)=> a.bytes)};
  }
}    




