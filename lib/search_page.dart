import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchPage extends StatefulWidget {
  final Position position;

  SearchPage({required this.position});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<dynamic> stations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNearbyStations();
  }

  Future<void> _fetchNearbyStations() async {
    final apiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
    final latitude = widget.position.latitude;
    final longitude = widget.position.longitude;

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=5000&type=train_station&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        stations = data['results'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load nearby stations');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Railway Stations'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: stations.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(stations[index]['name']),
            subtitle: Text(stations[index]['vicinity']),
          );
        },
      ),
    );
  }
}
