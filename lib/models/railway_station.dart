import '../services/station_facility_service.dart';


class GeoJsonParser {
  final String stationName;

  GeoJsonParser(this.stationName);

  Future<Map<String, dynamic>> parseGeoJson() async {

    return await StationFacilityService.fetchStationData(stationName);
  }

  Future<List<String>> getFacilityTypes() async {
    final geoJson = await parseGeoJson();
    final List<String> facilityTypes = [];
    for (var feature in geoJson['features']) {
      if (feature['properties'].containsKey('facilityType')) {
        facilityTypes.add(feature['properties']['facilityType']);
      }
    }
    return facilityTypes;
  }

  Future<List<List<double>>> retrieveCoordinates() async {
    try {
      final jsonData = await parseGeoJson();

      List<List<double>> coordinates = [];
      for (var feature in jsonData['features']) {
        if (feature['geometry']['type'] == 'LineString') {
          coordinates.addAll(List<List<double>>.from(feature['geometry']['coordinates'].map((coord) => List<double>.from(coord))));
        }
      }
      return coordinates;
    } catch (e) {
      throw Exception('Failed to retrieve coordinates: $e');
    }
  }
  Future<Map<String, dynamic>> getFacilityGeometries() async {
    return await parseGeoJson();
  }
}