import 'dart:convert';
import 'package:http/http.dart' as http;

class StationFacilityService {
  static const String baseUrl = "http://172.16.6.153:3000/getStationGeoJson";

  static Future<Map<String, dynamic>> fetchStationData(String stationName) async {
    final url = '$baseUrl/$stationName';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load station data');
      }
    } catch (e) {
      throw Exception('Failed to load station data: $e');
    }
  }
}