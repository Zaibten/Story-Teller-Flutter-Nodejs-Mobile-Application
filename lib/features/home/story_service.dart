// lib/features/home/services/story_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class StoryApiService {
  static const String baseUrl = 'http://localhost:9000'; // Update with your server URL
  
  // Generate a single story
  static Future<Map<String, dynamic>> generateStory({
    required String character,
    required String world,
    required String mood,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/generate-story'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'character': character,
          'world': world,
          'mood': mood,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e'
      };
    }
  }
}