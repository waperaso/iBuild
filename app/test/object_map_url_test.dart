import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/object_map_url.dart';

void main() {
  test('the object map embeds only the OpenStreetMap export page', () {
    final url = objectMapEmbedUrl('41.3111', '69.2797');
    final uri = Uri.parse(url);
    expect(uri.scheme, 'https');
    expect(uri.host, 'www.openstreetmap.org');
    expect(uri.path, '/export/embed.html');
    expect(uri.queryParameters['layer'], 'mapnik');
    expect(uri.queryParameters['marker'], '41.3111,69.2797');
    expect(url, isNot(contains('tile.openstreetmap.org')));
  });
}
