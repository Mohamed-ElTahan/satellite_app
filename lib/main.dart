import 'package:flutter/material.dart';

void main() {
  runApp(const SatelliteApp());
}

class SatelliteApp extends StatelessWidget {
  const SatelliteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Satellite')),
        body: const Center(child: Text('Satellite')),
      ),
    );
  }
}
