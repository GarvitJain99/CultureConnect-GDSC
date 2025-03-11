import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  Future<String> generateResponse(String culture, String category) async {
    String? apiKey = "AIzaSyAaZRuhbS9BKEPxvSBtfscmBja2EJmZB2Y";

    final Uri url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');

    String prompt =
        "Provide a structured cultural insight about $category in $culture of India. Format the response as follows: Cultural Significance: Explain the importance of this category in the region. Traditions & Practices: Describe local customs, rituals, or historical background. Famous Aspects Mention notable examples (e.g., famous dishes, art styles, language dialects). Ensure the response remains cultural-specific.";

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "role": "user", // ✅ Added "role": "user" as per API docs
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]
          ['text']; // ✅ Corrected extraction
    } else {
      throw Exception(
          'Failed to generate content. Status: ${response.statusCode}, Response: ${response.body}');
    }
  }
}
