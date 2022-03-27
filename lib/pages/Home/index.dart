import 'package:flutter/material.dart';
import 'package:rexy_demo/pages/Home/maps_page.dart';
import 'package:rexy_demo/pages/Home/my_map.dart';

/// A widget to return a number and button to
/// increase that number
///
/// See also:
///
///  * [AuthProvider] which is used for handling value
class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to maps demo'),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MyMapPage(),
                  ),
                );
              },
              child: const Text('Launch Map'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                );
              },
              child: const Text('Launch packt Map'),
            )
          ],
        ),
      ),
    );
  }
}
