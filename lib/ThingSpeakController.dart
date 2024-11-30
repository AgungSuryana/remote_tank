import 'dart:convert';
import 'package:http/http.dart' as http;

class ThingSpeakController {
  final String apiKey;       // ThingSpeak Write API Key
  final String channelId;     // ThingSpeak Channel ID
  final String readApiKey;    // ThingSpeak Read API Key untuk pembacaan data kontrol

  ThingSpeakController({
    required this.apiKey,
    required this.channelId,
    required this.readApiKey,
  });

  Future<void> sendControl(String field, String command) async {
    final url = Uri.parse(
        'https://api.thingspeak.com/update?api_key=$apiKey&$field=$command');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print('Command sent: $command to $field');
      } else {
        print('Failed to send command: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  Future<Map<String, String>> readControl() async {
    final url = Uri.parse(
        'https://api.thingspeak.com/channels/$channelId/feeds/last.json?api_key=$readApiKey');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          "maju": data['field1'] ?? '',
          "mundur": data['field2'] ?? '',
          "kiri": data['field3'] ?? '',
          "kanan": data['field4'] ?? '',
          "tembak": data['field5'] ?? '',
        };
      } else {
        print('Failed to read data: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('Exception: $e');
      return {};
    }
  }
}
