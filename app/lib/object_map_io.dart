import 'package:flutter/material.dart';

class ObjectMap extends StatelessWidget {
  const ObjectMap({super.key, required this.latitude, required this.longitude});

  final String latitude;
  final String longitude;

  @override
  Widget build(BuildContext context) {
    return Text('$latitude, $longitude');
  }
}
