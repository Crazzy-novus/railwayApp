import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import 'display_navigation_page.dart';
import 'select_destination_page.dart';
import 'widgets/cutom_button.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  final List<Marker> _markers = [];
  late List<String> _stationNames = [];
  late List<String> _stationCode = [];
  late Map<String, LatLng> _stationLocations = {};
  double? _latitude;
  double? _longitude;
  late String _selectedStation = '';
  late bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await Geolocator.openLocationSettings();
        if (!serviceEnabled) {
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _mapController.move(LatLng(_latitude!, _longitude!), 15.0);

        _markers.add(
          Marker(
            point: LatLng(_latitude!, _longitude!),
            child: const Icon(
                Icons.my_location, color: Colors.red, size: 40),
          ),
        );
      });

      _fetchNearbyStations(position.latitude, position.longitude);
    }
    catch (e) {
      print('Error fetching location: $e');
    }
  }

  Future<void> _fetchNearbyStations(double lat, double lon) async {
    try {
      const radius = 50000;

      final url =
          'https://overpass-api.de/api/interpreter?data=[out:json];node(around:$radius,$lat,$lon)[railway=station];out;';
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['elements'] != null) {
        List<Marker> markers = [];
        List<String> stationNames = [];
        List<String> stationCodes = [];
        Map<String, LatLng> stationLocations = {};
        for (var element in data['elements']) {
          final name = element['tags']['name'] ?? 'Unknown';
          final code = element['tags']['ref'] ?? 'Unknown'; // Assuming 'ref' is the station code
          final position = LatLng(element['lat'], element['lon']);
          final marker = Marker(
            point: position,
            child: const Icon(Icons.train, color: Colors.blue, size: 40),
          );
          markers.add(marker);
          stationNames.add(name);
          stationCodes.add(code);
          stationLocations[name] = position;
        }
        setState(() {
          _markers.addAll(markers);
          _stationNames = stationNames;
          _stationCode = stationCodes;
          _stationLocations = stationLocations;
        });
      }
    } catch (e) {
      print('Error fetching nearby stations: $e');
    }
  }

  void _toggleDropdown() {
    setState(() {
      _showDropdown = !_showDropdown;
    });
  }

  void _onStationTap(String stationName) {
    if (_stationLocations.containsKey(stationName)) {
      final location = _stationLocations[stationName]!;
      _mapController.move(location, 15.0);

      // Find the station code for the selected station
      final stationIndex = _stationNames.indexOf(stationName);
      final stationCode = _stationCode[stationIndex];

      // Navigate to SelectDestinationPage with the station code
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectDestinationPage(stationCode: stationCode, stationName: stationName),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Railway Stations')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _latitude != null && _longitude != null
                  ? LatLng(_latitude!, _longitude!)
                  : const LatLng(0, 0),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                maxZoom: 22,
                maxNativeZoom: 19,
                tileProvider: CancellableNetworkTileProvider(),
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white.withOpacity(0.8), // Translucent background
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _toggleDropdown,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedStation.isNotEmpty
                                ? _selectedStation
                                : 'Select Station',
                            style: const TextStyle(fontSize: 16),
                          ),

                          Icon(
                            _showDropdown ? Icons.arrow_upward : Icons
                                .arrow_downward,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _showDropdown,
                    child: SizedBox(
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.5, // Cover half of the map
                      child: ListView.builder(
                        itemCount: _stationNames.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_stationNames[index]),
                            onTap: () {
                              setState(() {
                                _selectedStation = _stationNames[index];
                                _toggleDropdown();
                                _onStationTap(_selectedStation);
                              });
                            }
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Positioned(
          //   bottom: 20,
          //   left: 20,
          //   right: 20,
          //   child: CustomButton(
          //       text: 'Select Facility',
          //       color: Colors.yellow[600],
          //       radius: 10,
          //       onTap: () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //               builder: (context) => const SelectDestinationPage()
          //           ),
          //         );
          //       }
          //   ),
          // ),
        ],
      ),
    );
  }
}