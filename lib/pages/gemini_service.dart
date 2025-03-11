import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  Future<Map<String, dynamic>> generateResponse(String culture, String category) async {
    String? apiKey = "AIzaSyAaZRuhbS9BKEPxvSBtfscmBja2EJmZB2Y";

    final Uri url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');

    String prompt = """
Provide a structured cultural insight about $category in $culture of India.  
Format the response as follows:  

### **Cultural Significance**  
Explain the importance of this category in the mentioned culture.  

### **Traditions & Practices**  
Describe local customs, rituals, or historical background.  

### **Famous Aspects**  
Mention notable examples (e.g., famous dishes, art styles, language dialects).  

**Visual Representation:** 
Provide at least **3 valid, high-quality image URLs** from open-source platforms **like Wikimedia Commons, government archives, or academic sites.**  
- The URLs **must be direct image links** ending in `.jpg`, `.png`, or `.webp`.  
- No empty responses.  
- Only return valid, working image URLs.  
- Do not include images behind paywalls or restricted sites.  
- Format each image as:  
  `https://example.com/sample.jpg` 

Ensure that the content is not redundant and always related to the category in the given culture  
Do not include broken, restricted, or inaccessible URLs**. Only return links that can be opened without login requirements.
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

      // Extract image URLs using RegExp
      RegExp regex = RegExp(r'(https?:\/\/[^\s]+\.(?:jpg|png|webp))');
      List<String> imageUrls = regex
          .allMatches(textContent)
          .map((match) => match.group(0)!)
          .toList();

      return {
        "text": textContent.replaceAll(regex, ''), // Remove URLs from text
        "images": imageUrls,
      };
    } else {
      throw Exception(
          'Failed to generate content. Status: ${response.statusCode}, Response: ${response.body}');
  }
  }
}