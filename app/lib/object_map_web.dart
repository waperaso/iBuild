import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'theme.dart';

final _maps = <String>{};

class ObjectMap extends StatelessWidget {
  const ObjectMap({super.key, required this.latitude, required this.longitude});

  final String latitude;
  final String longitude;

  @override
  Widget build(BuildContext context) {
    final viewType = 'object-map-$latitude-$longitude';
    if (_maps.add(viewType)) {
    final pad = 0.008;
    final lat = double.tryParse(latitude) ?? 0;
    final lon = double.tryParse(longitude) ?? 0;
    final src =
        'https://www.openstreetmap.org/export/embed.html?bbox=${lon - pad}%2C${lat - pad}%2C${lon + pad}%2C${lat + pad}&layer=mapnik&marker=$latitude%2C$longitude';
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      return web.HTMLIFrameElement()
        ..src = src
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
    });
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.input),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: HtmlElementView(viewType: viewType),
      ),
    );
  }
}
