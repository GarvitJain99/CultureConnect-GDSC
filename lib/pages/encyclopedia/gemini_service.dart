import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  Future<Map<String, dynamic>> generateResponse(
      String culture, String category) async {
    String? apiKey = "AIzaSyAaZRuhbS9BKEPxvSBtfscmBja2EJmZB2Y";

    final Uri url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');

    String prompt = """
Don't give any introduction, start with the content directly
Provide a structured cultural insight about $category in $culture of India.  
Format the response as follows:  

### **Cultural Significance**  
Explain the importance of this category in the mentioned culture.  

### **Traditions & Practices**  
Describe local customs, rituals, or historical background.  

### **Famous Aspects**  
Mention notable examples (e.g., famous dishes, art styles, language dialects).  

Ensure that the content is not redundant and always related to the category in the given culture.
Make sure that the content is almost always in points
""";

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String textContent = data['candidates'][0]['content']['parts'][0]['text'];

      return {
        "text": textContent
      };
    } else {
      throw Exception(
          'Failed to generate content. Status: ${response.statusCode}, Response: ${response.body}');
    }
  }
}
