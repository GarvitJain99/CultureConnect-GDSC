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
  List<String> imageUrls = [];
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    fetchGeneratedContent();
  }

  void fetchGeneratedContent() async {
    var result =
        await _geminiService.generateResponse(widget.culture, widget.category);

    print("Extracted Image URLs: ${result["images"]}"); // Debugging output

    setState(() {
      generatedContent = result["text"];

      // ✅ Explicitly cast result["images"] as a List<String>
      List<dynamic> dynamicUrls = result["images"] ?? [];
      imageUrls = dynamicUrls
          .map((e) => e.toString())
          .where((url) => url.isNotEmpty)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.category} in ${widget.culture}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: generatedContent,
              selectable: true,
            ),
            const SizedBox(height: 16),
            ...imageUrls.map((url) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Image.network(url,
                      errorBuilder: (context, error, stackTrace) {
                    return const Text("Image failed to load");
                  }),
                )),
          ],
        ),
      ),
    );
  }
}
