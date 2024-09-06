import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'models/railway_station.dart';

class DisplayNavigationPage extends StatelessWidget {
  final String stationCode;

  const DisplayNavigationPage({super.key, required this.stationCode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Flutter Map with GeoJSON')),
        body:  MapScreen(receivedStationCode: stationCode,),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  final String receivedStationCode;
  const MapScreen({super.key, required this.receivedStationCode});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController mapController = MapController(); // Step 1: Define mapController
  List<Marker> markers = [];
  List<LatLng> polylinePoints = [];
  String _selectedTile = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  final List<String> _tileOptions = [
    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    'http://{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
    'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}'
  ];
  Timer? _timer;
  LatLng? _currentLocation;

@override
void initState() {
  super.initState();
  fetchFacilityData();
  drawPolyline();
  startUpdatingCurrentLocation();
  _initializeMapCenter();
}

  Future<void> _initializeMapCenter() async {
    _currentLocation = await getCurrentLocation();
    setState(() {
      mapController.move(_currentLocation!, 15.0);
    });
  }
void startUpdatingCurrentLocation() {
  _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
    updateCurrentLocationMarker();
  });
}

  Future<LatLng> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    return LatLng(position.latitude, position.longitude);
  }

  Future<void> updateCurrentLocationMarker() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(
          msg: "Location services are disabled.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }

      // Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(
            msg: "Location permissions are denied.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(
          msg: "Location permissions are permanently denied.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }

      // Get the current position with high accuracy
      final currentLocation = await getCurrentLocation();
      setState(() {
        if (markers.isNotEmpty) {
          markers.removeAt(0); // Remove the old current location marker
        }
        markers.insert(
          0,
          Marker(
            width: 80.0,
            height: 80.0,
            point: currentLocation,
            child: const Icon(Icons.my_location_sharp, color: Colors.blue, size: 40.0),
          ),
        );
        mapController.move(currentLocation, 18.5); // Update the map center
      });

      Fluttertoast.showToast(
        msg: "Current location marker updated",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      print('Failed to get current location: $e');
    }
  }

@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}

Future<void> drawPolyline() async {
  final parser = GeoJsonParser(widget.receivedStationCode);
  final coordinates = await parser.retrieveCoordinates();

  setState(() {
    polylinePoints = coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();

    // Add start marker
    markers.add(
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(coordinates.first[1], coordinates.first[0]),
        child: const Icon(Icons.location_on, color: Colors.green, size: 40.0),
      ),
    );

    // Add end marker
    markers.add(
      Marker(
        point: LatLng(coordinates.last[1], coordinates.last[0]),
        width: 80.0,
        height: 80.0,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ),
    );
  });
}

Future<void> fetchFacilityData() async {
  final parser = GeoJsonParser(widget.receivedStationCode);
  final data = await parser.getFacilityGeometries();

  if (data['features'] != null) {
    data['features'].forEach((feature) {
      if (feature['geometry']['type'] == 'Point') {
        List coords = feature['geometry']['coordinates'];
        Icon markerIcon;

        switch (feature['properties']['facilityType']) {
          case 'ATM':
            markerIcon = const Icon(Icons.atm, color: Colors.red, size: 40.0);
            break;
          case 'Cafeteria':
            markerIcon = const Icon(Icons.local_cafe, color: Colors.green, size: 40.0);
            break;
          case 'Waiting Hall"':
            markerIcon = const Icon(Icons.build_circle, color: Colors.blue, size: 40.0);
            break;
          case 'Rest Room':
            markerIcon = const Icon(Icons.family_restroom, color: Colors.green, size: 40.0);
            break;
          case 'Entry':
            markerIcon = const Icon(Icons.door_back_door, color: Colors.green, size: 40.0);
            break;
          case 'Escalator':
            markerIcon = const Icon(Icons.escalator, color: Colors.green, size: 40.0);
            break;
          case 'Exit':
            markerIcon = const Icon(Icons.transit_enterexit, color: Colors.green, size: 40.0);
            break;
          case 'Food Court':
            markerIcon = const Icon(Icons.fastfood, color: Colors.green, size: 40.0);
            break;
          case 'Help Desk':
            markerIcon = const Icon(Icons.help_center, color: Colors.green, size: 40.0);
            break;
          case 'Parcel Office':
            markerIcon = const Icon(Icons.conveyor_belt, color: Colors.green, size: 40.0);
            break;
          case 'Store':
            markerIcon = const Icon(Icons.store, color: Colors.green, size: 40.0);
            break;
          default:
            markerIcon = const Icon(Icons.location_on, color: Colors.grey, size: 40.0);
        }

        setState(() {
          markers.add(
            Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(coords[1], coords[0]),
              child: markerIcon,
            ),
          );
        });
      }
    });
  }
}

@override
Widget build(BuildContext context) {
  return Column(
    children: [
      DropdownButton<String>(
        hint: const Text('Select Map Tile'),
        value: _selectedTile,
        onChanged: (String? newValue) {
          setState(() {
            _selectedTile = newValue!;
          });
        },
        items: _tileOptions.map<DropdownMenuItem<String>>((String tile) {
          return DropdownMenuItem<String>(
            value: tile,
            child: Text(tile),
          );
        }).toList(),
      ),
      Expanded(
        child: FlutterMap(
          mapController: mapController, // Step 2: Initialize mapController
          options:  MapOptions(
            initialCenter: _currentLocation ?? const LatLng(9.488966,77.8162655),
            initialZoom: 20.5,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c'],
              maxZoom: 22,


            ),
            PolylineLayer(
              polylines: [
                Polyline(points: polylinePoints, strokeWidth: 3.0, color: Colors.blue),
              ],
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    ],
  );
}
}