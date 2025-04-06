import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'gemini_service.dart';

class GeneratedContentPage extends StatefulWidget {
  final String culture;
  final String category;
  const GeneratedContentPage(
      {super.key, required this.culture, required this.category});

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
    var result =
        await _geminiService.generateResponse(widget.culture, widget.category);

    setState(() {
      generatedContent = result["text"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.category} in ${widget.culture}"),
        backgroundColor: const Color(0xFFFC7C79),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFC7C79), Color(0xFFEDC0F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            if (generatedContent == "Fetching details...")
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownBody(
                      data: generatedContent,
                      selectable: true,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
