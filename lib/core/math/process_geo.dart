import 'dart:convert';
import 'dart:io';

void main() async {
  print('Downloading JSON...');
  final httpClient = HttpClient();
  final request = await httpClient.getUrl(Uri.parse('https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_land.geojson'));
  final response = await request.close();
  final jsonString = await response.transform(utf8.decoder).join();
  print('Decoded string');
  final data = jsonDecode(jsonString);

  List<List<List<double>>> polygons = [];

  final features = data['features'] as List;
  for (final feature in features) {
    if (feature['geometry'] == null) continue;
    final geomType = feature['geometry']['type'];
    final coordinates = feature['geometry']['coordinates'];

    if (geomType == 'Polygon') {
      for (final poly in coordinates) {
        List<List<double>> currentPoly = [];
        for (final pt in poly) {
           currentPoly.add([(pt[0] as num).toDouble(), (pt[1] as num).toDouble()]);
        }
        polygons.add(currentPoly);
      }
    } else if (geomType == 'MultiPolygon') {
      for (final multi in coordinates) {
        for (final poly in multi) {
          List<List<double>> currentPoly = [];
          for (final pt in poly) {
             currentPoly.add([(pt[0] as num).toDouble(), (pt[1] as num).toDouble()]);
          }
          polygons.add(currentPoly);
        }
      }
    }
  }

  // Generate Dart file content
  StringBuffer sb = StringBuffer();
  sb.writeln('class EarthData {');
  sb.writeln('  // Topographical Landmass polygons (Lng, Lat)');
  sb.writeln('  static const List<List<List<double>>> continents = [');
  
  for (final poly in polygons) {
    sb.writeln('    [');
    for (final pt in poly) {
      // Limit decimals to 1 to save massive space
      sb.writeln('      [${pt[0].toStringAsFixed(1)}, ${pt[1].toStringAsFixed(1)}],');
    }
    sb.writeln('    ],');
  }
  
  sb.writeln('  ];');
  sb.writeln('}');

  File(r'm:\antigravity_projects\satellite\lib\core\math\earth_data.dart').writeAsStringSync(sb.toString());
  print('Saved ${polygons.length} polygons to earth_data.dart');
  exit(0);
}
