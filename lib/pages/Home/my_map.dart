import 'dart:async';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_animarker/core/ripple_marker.dart';
import 'package:flutter_animarker/widgets/animarker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

//Setting dummy values
const kStartPosition = LatLng(28.5677553, 77.3823991);
const kMarkerId = MarkerId('MarkerId1');
const kDuration = Duration(seconds: 2);
const kLocations = [
  kStartPosition,
  LatLng(28.5687653, 77.3825991),
  LatLng(28.5697683, 77.3826091),
  LatLng(28.5707723, 77.3827291),
];
const kMapZoom = 16.0;

class MyMapPage extends StatefulWidget {
  const MyMapPage({Key? key}) : super(key: key);

  @override
  State<MyMapPage> createState() => _MyMapPageState();
}

class _MyMapPageState extends State<MyMapPage> {
  final markers = <MarkerId, Marker>{};
  final controller = Completer<GoogleMapController>();
  // late GoogleMapController controller;
  final stream = Stream.periodic(kDuration, (count) => kLocations[count])
      .take(kLocations.length);

  double currentZoom = kMapZoom;

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    // Change the accuracy for refined results
    distanceFilter: 10,
  );

  late StreamSubscription<Position> positionStream;

  late LatLng lastPos;

  Future<void> startLocationStream() async {
    // handle realtime movement and update marker and camera
    await Future.delayed(const Duration(seconds: 1), () async {
      Position position = await _determinePosition();
      var pos = LatLng(position.latitude, position.longitude);
      setState(() {
        lastPos = pos;
      });
      positionStream =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position? position) {
        if (position != null &&
            LatLng(position.latitude, position.longitude) != lastPos) {
          newLocationUpdate(LatLng(position.latitude, position.longitude));
          setState(() {
            lastPos = LatLng(position.latitude, position.longitude);
          });
        }
        debugPrint(
          position == null
              ? 'Unknown'
              : '${position.latitude.toString()}, ${position.longitude.toString()}',
        );
      });
    });
  }

  @override
  void initState() {
    super.initState();

    // adding dummy movement at initial stage
    // to demonstration smooth motion of marker
    Future.delayed(const Duration(seconds: 1), () {
      stream.listen((event) async {
        newLocationUpdate(event);
      }).onDone(() async {
        // after dummy motion move marker back to current location
        Future.delayed(const Duration(seconds: 1), () async {
          Position position = await _determinePosition();
          newLocationUpdate(LatLng(position.latitude, position.longitude));
        });
        startLocationStream();
      });
    });
  }

  @override
  void dispose() {
    try {
      positionStream.cancel();
      // controller.dispose();
      controller.future.then((value) => value.dispose());
    } catch (err) {
      debugPrint(err.toString());
    }
    super.dispose();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Please enable location service'),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    await Geolocator.openLocationSettings().then((value) {
                      Navigator.of(context).pop();
                      _determinePosition();
                      // startLocationStream();
                    });
                  },
                  child: const Text('Enable Location'),
                )
              ],
            );
          });
      // return Future.error('Location services are disabled.');

    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Please allow permission for location'),
                actions: [
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      _determinePosition();
                      startLocationStream();
                    },
                    child: const Text('Allow'),
                  )
                ],
              );
            });
        // return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Please allow permission for location'),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await Geolocator.openAppSettings();
                    _determinePosition();
                    startLocationStream();
                  },
                  child: const Text('Open Settings'),
                )
              ],
            );
          });
      // return Future.error(
      //     'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  void newLocationUpdate(LatLng latLng) {
    // var mr = markers[kMarkerId];

    var marker = Marker(
      infoWindow: const InfoWindow(title: 'My Marker'),
      markerId: kMarkerId,
      position: latLng,
      // ripple: true,
    );
    if (mounted) {
      setState(() => markers[kMarkerId] = marker);
    }

    //Moving the google camera to the new animated location.
    Future.delayed(const Duration(seconds: 1), () {
      controller.future.then(
        ((value) {
          value.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: latLng,
                zoom: currentZoom,
              ),
            ),
          );
        }),
      ).catchError((err) {});
    });

    // var marker = RippleMarker(
    //   markerId: kMarkerId,
    //   position: latLng,
    //   ripple: true,
    // );
    // setState(() => markers[kMarkerId] = marker);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Maps Demo'),
      ),
      body: FutureBuilder<Position?>(
        future: Future.delayed(const Duration(seconds: 2), () async {
          try {
            return await _determinePosition();
          } catch (err) {
            return null;
          }
        }),
        builder: (context, snap) {
          if (snap.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AvatarGlow(
                    glowColor: Colors.red,
                    endRadius: 90.0,
                    duration: const Duration(milliseconds: 2000),
                    repeat: true,
                    showTwoGlows: true,
                    repeatPauseDuration: const Duration(milliseconds: 100),
                    child: Material(
                      // Replace this child with your own
                      elevation: 8.0,
                      shape: const CircleBorder(),
                      child: CircleAvatar(
                        backgroundColor: Colors.grey[100],
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                        radius: 40.0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          var currentLocationCamera = CameraPosition(
            target: LatLng(snap.data!.latitude, snap.data!.longitude),
            zoom: currentZoom,
          );
          return Animarker(
            curve: Curves.ease,
            mapId: controller.future.then<int>(
              (value) => value.mapId,
            ), //Grab Google Map Id
            markers: markers.values.toSet(),
            child: GoogleMap(
              minMaxZoomPreference: const MinMaxZoomPreference(16, 16),
              zoomControlsEnabled: true,
              zoomGesturesEnabled: true,
              myLocationEnabled: true,
              mapType: MapType.normal,
              onCameraMove: (CameraPosition pos) {
                setState(() {
                  currentZoom = pos.zoom;
                });
              },
              initialCameraPosition: currentLocationCamera,
              onMapCreated: (gController) => controller.complete(
                gController,
              ), //Complete the future GoogleMapController
            ),
          );
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: (() async {
      //     Position pos = await _determinePosition();
      //     LatLng latLng = LatLng(pos.latitude, pos.longitude);
      //     newLocationUpdate(latLng);
      //   }),
      //   child: const Icon(Icons.my_location),
      // ),
    );
  }
}
