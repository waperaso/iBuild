import 'package:flutter/material.dart';

import 'api_client.dart';
import 'app.dart';

void main() {
  runApp(IBuildApp(api: createHttpApi()));
}
