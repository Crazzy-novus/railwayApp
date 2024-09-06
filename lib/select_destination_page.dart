import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:demo/widgets/cutom_button.dart';
import 'package:demo/display_navigation_page.dart';

import 'models/railway_station.dart';


class SelectDestinationPage extends StatelessWidget {
  final String stationCode;
  final String stationName;

  const SelectDestinationPage({super.key, required this.stationCode, required this.stationName});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 20, color: Colors.black),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Station Selected :$stationName'),
          backgroundColor: Colors.blueAccent,
        ),
        body: LocationScreen(receivedString: stationCode),
      ),
    );
  }
}

class LocationScreen extends StatefulWidget {
  final String receivedString;

  const LocationScreen({super.key, required this.receivedString});

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String _locationMessage = "Getting location...";
  String? _selectedFacilitySource;
  String? _selectedFacilityDestination;
  List<String> _facilities = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchFacilities();
  }

  Future<void> _getCurrentLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _locationMessage =
        "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
      });
    } else if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _locationMessage = "Location permission is required to use this feature.";
      });
    }
  }

  Future<void> _fetchFacilities() async {
    final parser = GeoJsonParser(widget.receivedString);
    final facilities = await parser.getFacilityTypes();
    setState(() {
      _facilities = facilities;
    });
  }

  void showToast(String facilityType) {
    Fluttertoast.showToast(
      msg: facilityType,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
            hint: const Text('Select Destination Facility'),
            value: _selectedFacilitySource,
            onChanged: (String? newValue) {
              setState(() {
                _selectedFacilitySource = newValue;
              });
            },
            items: _facilities.map<DropdownMenuItem<String>>((String facility) {
              return DropdownMenuItem<String>(
                value: facility,
                child: Text(facility),
              );
            }).toList(),
          ),
          if (_selectedFacilitySource != null && _selectedFacilityDestination != null)
            Text(
              'Selected Facility: $_selectedFacilityDestination',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 20),
          DropdownButton<String>(
            hint: const Text('Select Destination Facility'),
            value: _selectedFacilityDestination,
            onChanged: (String? newValue) {
              setState(() {
                _selectedFacilityDestination = newValue;
              });
            },
            items: _facilities.map<DropdownMenuItem<String>>((String facility) {
              return DropdownMenuItem<String>(
                value: facility,
                child: Text(facility),
              );
            }).toList(),
          ),
          if (_selectedFacilitySource != null && _selectedFacilityDestination != null)
            Text(
              'Selected Facility: $_selectedFacilityDestination',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomButton(
                text: 'Start Navigation',
                color: Colors.yellow[600],
                radius: 10,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>  DisplayNavigationPage(stationCode:widget.receivedString)
                    ),
                  );
                }
            ),
          ),
        ],
      ),
    );
  }
}