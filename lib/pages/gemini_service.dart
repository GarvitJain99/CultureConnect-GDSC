import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  Future<String> generateResponse(String culture, String category) async {
    String? apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      return "API Key is missing!";
    }

    final Uri url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateText?key=$apiKey');

    String prompt =
        "Provide detailed information about $category in $culture culture in an engaging and informative manner.";

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      try {
        return data["candidates"][0]["content"]["parts"][0]["text"] ??
            "No response from AI.";
      } catch (e) {
        return "Error parsing AI response.";
      }
    } else {
      return "Failed to generate content. Error: ${response.statusCode}";
    }
  }
}
