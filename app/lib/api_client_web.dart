import 'dart:js_interop';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web/web.dart';

import 'api_http.dart';

HttpApiClient createHttpApi() => HttpApiClient(_CookieClient());

/// Same-origin `fetch` that always sends the session cookie.
///
/// `package:http` BrowserClient streams the body through a reader that can
/// stall after the first response, which leaves the app on the boot screen.
class _CookieClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    final response = await window
        .fetch(
          '${request.url}'.toJS,
          RequestInit(
            method: request.method,
            credentials: 'include',
            headers: request.headers.jsify()! as HeadersInit,
            body: bytes.isEmpty ? null : bytes.toJS,
          ),
        )
        .toDart;
    final buffer = (await response.arrayBuffer().toDart).toDart;
    final contentType = response.headers.get('content-type');
    return http.StreamedResponse(
      Stream<List<int>>.value(Uint8List.view(buffer)),
      response.status,
      headers: {'content-type': ?contentType},
      request: request,
    );
  }
}
