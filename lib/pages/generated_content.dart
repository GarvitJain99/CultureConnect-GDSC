import 'package:flutter/material.dart';
import 'gemini_service.dart';

class GeneratedContentPage extends StatefulWidget {
  final String culture;
  final String category;
  const GeneratedContentPage({super.key, required this.culture, required this.category});

  @override
  _GeneratedContentPageState createState() => _GeneratedContentPageState();
}

class _GeneratedContentPageState extends State<GeneratedContentPage> {
  String generatedContent = "Fetching details...";
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    fetchGeneratedContent();
  }

  void fetchGeneratedContent() async {
    String content = await _geminiService.generateResponse(widget.culture, widget.category);
    setState(() {
      generatedContent = content;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.category} in ${widget.culture}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(generatedContent, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
