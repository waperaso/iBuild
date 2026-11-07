/// The only page the object card may embed. The server CSP allows this host
/// and nothing else in frame-src.
String objectMapEmbedUrl(String latitude, String longitude) {
  final pad = 0.008;
  final lat = double.tryParse(latitude) ?? 0;
  final lon = double.tryParse(longitude) ?? 0;
  return 'https://www.openstreetmap.org/export/embed.html'
      '?bbox=${lon - pad}%2C${lat - pad}%2C${lon + pad}%2C${lat + pad}'
      '&layer=mapnik&marker=$latitude%2C$longitude';
}
