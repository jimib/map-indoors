import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import "package:flutter_beacon/flutter_beacon.dart";
import 'package:http/http.dart' as http;

void initBeacons() async {
  try {
    // fetchBeacons().then((beacons) {
    //   developer.log('Beacons: ${beacons.length}');
    // });

    developer.log("init #1 y");
    // if you want to manage manual checking about the required permissions
    // await flutterBeacon.initializeScanning;
    developer.log("init #2 y");

    // or if you want to include automatic checking permission
    await flutterBeacon.initializeAndCheckScanning;
    developer.log("init #3 y");

    scanBeacons();
  } on PlatformException catch (e) {
    // library failed to initialize, check code and message
    developer.log("Error: ${e.message}");
  }
}

void scanBeacons() async {
  final regions = <Region>[];

  developer.log("scan #1");

  if (Platform.isIOS) {
    // iOS platform, at least set identifier and proximityUUID for region scanning
    regions.add(Region(
        identifier: '23A01AF0-232A-4518-9C0E-323FB773F5EF',
        proximityUUID: '23A01AF0-232A-4518-9C0E-323FB773F5EF'));

    regions.add(Region(
        identifier: 'f7826da6-4fa2-4e98-8024-bc5b71e0893e',
        proximityUUID: 'f7826da6-4fa2-4e98-8024-bc5b71e0893e'));
  } else {
    // Android platform, it can ranging out of beacon that filter all of Proximity UUID
    regions.add(Region(
        identifier: 'com.sensoro',
        proximityUUID: '23A01AF0-232A-4518-9C0E-323FB773F5EF'));
  }

  developer.log("scan #2");
  // to start monitoring beacons
  //var streamRanging =
  flutterBeacon.ranging(regions).listen((RangingResult result) {
    // result contains a region, event type and event state
    // int id = 0;
    // for (Beacon beacon in result.beacons) {
    //   developer.log("${id++} ${beacon.toString()}");
    // }
    // developer.log("---------------");
  });

  // to stop monitoring beacons
  // _streamMonitoring.cancel();
  developer.log("scan #3");
}

List<Beacon> parseBeacons(String body) {
  final parsed = jsonDecode(body).cast<Map<String, dynamic>>();

  return parsed.map<Beacon>((json) => Beacon.fromJson(json)).toList();
  // return "x";
}

Future<List<Beacon>> fetchBeacons() async {
  var client = http.Client();

  final response =
      await client.get(Uri.parse('https://dev.jimib.uk/service/beacons'));

  // Use the compute function to run parsePhotos in a separate isolate.
  return compute(parseBeacons, response.body);
}

class Beacon {
  final int id;
  final String name;

  final double lat;
  final double lng;
  final int majorId;
  final int minorId;
  final int floor;

  const Beacon(
      {required this.name,
      this.id = 0,
      this.majorId = 0,
      this.minorId = 0,
      this.lat = 0.0,
      this.lng = 0.0,
      this.floor = 0});

  factory Beacon.fromJson(Map<String, dynamic> json) {
    return Beacon(
        name: json['name'] as String,
        majorId: json['majorId'] as int,
        minorId: json['minorId'] as int,
        lat: json['lat'] as double,
        lng: json['lng'] as double,
        floor: json['floor'] as int);
  }
}
