import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vector_math/vector_math.dart';

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
const kMapZoom = 17.0;

class HomeScreen extends StatefulWidget {
  static const id = "HOME_SCREEN";

  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<Marker> _markers = <Marker>[];
  Animation<double>? _animation;
  late GoogleMapController _controller;

  final _mapMarkerSC = StreamController<List<Marker>>();

  StreamSink<List<Marker>> get _mapMarkerSink => _mapMarkerSC.sink;

  Stream<List<Marker>> get mapMarkerStream => _mapMarkerSC.stream;

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    // Change the accuracy for refined results
    distanceFilter: 10,
  );

  final stream = Stream.periodic(kDuration, (count) => kLocations[count])
      .take(kLocations.length);

  late StreamSubscription<Position> positionStream;

  late Position lastPos;

  @override
  void initState() {
    super.initState();

    // adding dummy movement at initial stage
    // to demonstration smooth motion of marker
    // Future.delayed(
    //   const Duration(seconds: 1),
    //   () {
    //     stream.listen((event) async {
    //       animateCar(kStartPosition, event, _mapMarkerSink, this, _controller);
    //     }).onDone(
    //       () async {
    //         // after dummy motion move marker back to current location
    //         Position position = await _determinePosition();
    //         animateCar(
    //             kStartPosition,
    //             LatLng(position.latitude, position.longitude),
    //             _mapMarkerSink,
    //             this,
    //             _controller);
    //       },
    //     );
    //   },
    // );

    //Starting the animation after 1 second.
    // handle realtime movement and update marker and camera
    Future.delayed(const Duration(seconds: 1)).then((value) async {
      Position position = await _determinePosition();
      setState(() {
        lastPos = position;
      });
      animateCar(
        kStartPosition,
        LatLng(position.latitude, position.longitude),
        _mapMarkerSink,
        this,
        _controller,
      ).then((_) {
        positionStream =
            Geolocator.getPositionStream(locationSettings: locationSettings)
                .listen((Position? position) {
          if (position != null && position != lastPos) {
            animateCar(
                    LatLng(lastPos.latitude, lastPos.longitude),
                    LatLng(position.latitude, position.longitude),
                    _mapMarkerSink,
                    this,
                    _controller)
                .then(
              (_) => setState(() {
                lastPos = position;
              }),
            );
          }
          debugPrint(
            position == null
                ? 'Unknown'
                : '${position.latitude.toString()}, ${position.longitude.toString()}',
          );
        });
      });
    });
  }

  @override
  void dispose() {
    positionStream.cancel();
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
      return Future.error('Location services are disabled.');
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
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    const currentLocationCamera = CameraPosition(
      target: kStartPosition,
      zoom: kMapZoom,
    );

    final googleMap = StreamBuilder<List<Marker>>(
        stream: mapMarkerStream,
        builder: (context, snapshot) {
          return GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: currentLocationCamera,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            mapToolbarEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            markers: Set<Marker>.of(snapshot.data ?? []),
            padding: const EdgeInsets.all(8),
          );
        });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Packt Demo'),
      ),
      body: Stack(
        children: [
          googleMap,
        ],
      ),
    );
  }

  setUpMarker() async {
    const currentLocationCamera = kStartPosition;

    final pickupMarker = Marker(
      markerId: MarkerId("${currentLocationCamera.latitude}"),
      position: LatLng(
          currentLocationCamera.latitude, currentLocationCamera.longitude),
      icon: BitmapDescriptor.fromBytes(
          await getBytesFromAsset('asset/icons/ic_car_top_view.png', 70)),
    );

    //Adding a delay and then showing the marker on screen
    await Future.delayed(const Duration(milliseconds: 500));

    _markers.add(pickupMarker);
    _mapMarkerSink.add(_markers);
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<void> animateCar(
    LatLng from,
    LatLng to,
    StreamSink<List<Marker>>
        mapMarkerSink, //Stream build of map to update the UI
    TickerProvider
        provider, //Ticker provider of the widget. This is used for animation
    GoogleMapController controller, //Google map controller of our widget
  ) async {
    final double bearing = getBearing(from, to);

    _markers.clear();

    var carMarker = Marker(
      markerId: const MarkerId("driverMarker"),
      position: from,
      icon: BitmapDescriptor.defaultMarker,
      // icon: BitmapDescriptor.fromBytes(
      //   await getBytesFromAsset('asset/icons/ic_car_top_view.png', 60),
      // ),
      anchor: const Offset(0.5, 0.5),
      flat: true,
      rotation: bearing,
      draggable: false,
    );

    //Adding initial marker to the start location.
    _markers.add(carMarker);
    mapMarkerSink.add(_markers);

    final animationController = AnimationController(
      duration: const Duration(
        milliseconds: 200,
      ), //Animation duration of marker
      vsync: provider, //From the widget
    );

    Tween<double> tween = Tween(begin: 0, end: 1);

    _animation = tween.animate(animationController)
      ..addListener(() async {
        //We are calculating new latitude and logitude for our marker
        final v = _animation!.value;
        double lng = v * to.longitude + (1 - v) * from.longitude;
        double lat = v * to.latitude + (1 - v) * to.latitude;
        LatLng newPos = LatLng(lat, lng);

        //Removing old marker if present in the marker array
        if (_markers.contains(carMarker)) _markers.remove(carMarker);

        //New marker location
        carMarker = Marker(
            markerId: const MarkerId("driverMarker"),
            position: newPos,
            icon: BitmapDescriptor.defaultMarker,
            // icon: BitmapDescriptor.fromBytes(
            //   await getBytesFromAsset('asset/icons/ic_car_top_view.png', 50),
            // ),
            anchor: const Offset(0.5, 0.5),
            flat: true,
            rotation: bearing,
            draggable: false);

        //Adding new marker to our list and updating the google map UI.
        _markers.add(carMarker);
        mapMarkerSink.add(_markers);

        //Moving the google camera to the new animated location.
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: newPos,
              zoom: kMapZoom,
            ),
          ),
        );
      });

    //Starting the animation
    animationController.forward();
  }

  double getBearing(LatLng begin, LatLng end) {
    double lat = (begin.latitude - end.latitude).abs();
    double lng = (begin.longitude - end.longitude).abs();

    if (begin.latitude < end.latitude && begin.longitude < end.longitude) {
      return degrees(atan(lng / lat));
    } else if (begin.latitude >= end.latitude &&
        begin.longitude < end.longitude) {
      return (90 - degrees(atan(lng / lat))) + 90;
    } else if (begin.latitude >= end.latitude &&
        begin.longitude >= end.longitude) {
      return degrees(atan(lng / lat)) + 180;
    } else if (begin.latitude < end.latitude &&
        begin.longitude >= end.longitude) {
      return (90 - degrees(atan(lng / lat))) + 270;
    }
    return -1;
  }
}
