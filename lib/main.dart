import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:developer' as developer;

import './utils/beacons.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  const MapSample({Key? key}) : super(key: key);

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<MapViewController> _controller = Completer();
  double rotation = 0;

  @override
  void initState() {
    super.initState();
    developer.log("Initiaised the state");
    initBeacons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: GoogleMap(
      //   mapType: MapType.hybrid,
      //   initialCameraPosition: _kGooglePlex,
      //   onMapCreated: (GoogleMapController controller) {
      //     _controller.complete(controller);
      //   },
      // ),
      body: MapView(onMapViewCreated: (controller) {
        _controller.complete(controller);
      }),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FloatingActionButton(
              onPressed: () {
                _gotoLocationByCoords(lat: 30.3804505, lng: -97.7318073);
              },
              child: const Icon(Icons.home),
            ),
            FloatingActionButton(
              onPressed: () {
                rotation += 90;
                _setBearing(bearing: rotation);
              },
              child: const Icon(Icons.rotate_90_degrees_cw),
            ),
            FloatingActionButton(
              onPressed: () {
                _setBearing(bearing: -18.5);
                _gotoLocationByName("PIXEL_INSPIRATION");
              },
              child: const Text("Pixel"),
            ),
            FloatingActionButton(
              onPressed: () {
                _clearMap();
              },
              child: const Icon(Icons.clear),
            ),
            FloatingActionButton(
              onPressed: () {
                _syncContent();
              },
              child: const Icon(Icons.sync),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Future<void> _gotoLocationByName(String name) async {
    final MapViewController controller = await _controller.future;
    controller.gotoLocationByName(name);
  }

  Future<void> _setBearing({required double bearing}) async {
    final MapViewController controller = await _controller.future;
    controller.setBearing(bearing: bearing);
  }

  Future<void> _gotoLocationByCoords(
      {required double lat, required double lng}) async {
    final MapViewController controller = await _controller.future;
    controller.gotoLocationByCoords(lat: lat, lng: lng);
  }

  Future<void> _clearMap() async {
    final MapViewController controller = await _controller.future;
    controller.clearMap();
  }

  Future<void> _syncContent() async {
    final MapViewController controller = await _controller.future;
    controller.syncContent();
  }
}

typedef void MapViewCreatedCallback(MapViewController controller);

class MapView extends StatelessWidget {
  final MapViewCreatedCallback? onMapViewCreated;

  const MapView({Key? key, this.onMapViewCreated}) : super(key: key);

  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = '<platform-view-type>';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }

  void _onPlatformViewCreated(int id) {
    developer.log('onPlatformViewCreated $id', name: 'dev.map.view');
    onMapViewCreated!(MapViewController(id));
  }
}

class MapViewController {
  late MethodChannel _channel;

  MapViewController(int id) {
    _channel = MethodChannel('MapView/$id');
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'sendFromNative':
        String text = call.arguments as String;
        return Future.value("Text from native: $text");
      case 'loadedBeacons':
        developer.log("Flutter:loadedBeacons...");
        String jsonString = call.arguments as String;
        developer.log("Flutter:loadedBeacons...#1");
        List<dynamic> beaconsMap = jsonDecode(jsonString);
        developer.log("Flutter:loadedBeacons...#2 ${beaconsMap.length}");

        List<Beacon> beacons = [];
        // Map<String, dynamic> beaconsMap = jsonDecode(jsonString);
        int index = 0;
        beaconsMap.forEach((ibeacon) {
          var beacon = Beacon.fromJson(ibeacon);
          developer.log(
              "Beacon ${1 + index++}) ${beacon.name} ${beacon.majorId} ${beacon.minorId}");
          beacons.add(beacon);
        });

        // developer.log("Flutter:loadedBeacons...#3b ${beacons.length}");
        developer.log('Flutter:loadedBeacons ${beacons.first.name}');
        developer.log("Flutter:loadedBeacons...#4");

        return Future.value("Beacons received from native");
    }
  }

  Future<void> receiveFromFlutter(String text) async {
    try {
      final String result =
          await _channel.invokeMethod('receiveFromFlutter', {"text": text});
      developer.log("Result from native: $result", name: 'dev.map.controller');
    } on PlatformException catch (e) {
      developer.log("Error from native: $e.message",
          name: 'dev.map.controller');
    }
  }

  void gotoLocationByName(String location) async {
    try {
      await _channel.invokeMethod('gotoLocationByName', {"name": location});
    } on PlatformException catch (e) {
      developer.log("Error from native: $e.message");
    }
  }

  void gotoLocationByCoords({required double lat, required double lng}) async {
    try {
      await _channel
          .invokeMethod('gotoLocationByCoords', {"lat": lat, "lng": lng});
    } on PlatformException catch (e) {
      developer.log("Error from native: $e.message");
    }
  }

  void setBearing({required double bearing}) async {
    try {
      await _channel.invokeMethod('setBearing', {"bearing": bearing});
    } on PlatformException catch (e) {
      developer.log("Error from native: $e.message");
    }
  }

  void clearMap() async {
    try {
      await _channel.invokeMethod('clearMap');
    } on PlatformException catch (e) {
      developer.log("Error from native: $e.message");
    }
  }

  void syncContent() async {
    try {
      await _channel.invokeMethod('syncContent');
    } on PlatformException catch (e) {
      developer.log("Error from native: $e.message");
    }
  }
}
