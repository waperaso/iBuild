import 'package:http/http.dart' as http;

import 'api_http.dart';

HttpApiClient createHttpApi() => HttpApiClient(http.Client());
