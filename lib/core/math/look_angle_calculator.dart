import 'dart:math' as math;

class LookAngleCalculator {
  static const double earthRadiusKm = 6371.0;
  static const double geoOrbitRadiusKm = 42164.0; // From Earth center

  /// Calculates azimuth, elevation, and range for a geostationary satellite
  /// Returns a map with 'azimuth' (deg), 'elevation' (deg), and 'range' (km).
  static Map<String, double> calculate({
    required double observerLat,
    required double observerLng,
    required double satelliteLat,
    required double satelliteLng,
    required double satelliteAltitudeKm,
  }) {
    final rSat = earthRadiusKm + satelliteAltitudeKm;

    final latRad = observerLat * math.pi / 180.0;
    final lngRad = observerLng * math.pi / 180.0;
    final satLatRad = satelliteLat * math.pi / 180.0;
    final satLngRad = satelliteLng * math.pi / 180.0;

    // Sat ECEF
    final xs = rSat * math.cos(satLatRad) * math.cos(satLngRad);
    final ys = rSat * math.cos(satLatRad) * math.sin(satLngRad);
    final zs = rSat * math.sin(satLatRad);
    
    // Obs ECEF
    final xo = earthRadiusKm * math.cos(latRad) * math.cos(lngRad);
    final yo = earthRadiusKm * math.cos(latRad) * math.sin(lngRad);
    final zo = earthRadiusKm * math.sin(latRad);
    
    // Range Vector (Sat - Obs)
    final rx = xs - xo;
    final ry = ys - yo;
    final rz = zs - zo;
    
    // ENU (East, North, Up) Rotation Setup
    final sinLat = math.sin(latRad);
    final cosLat = math.cos(latRad);
    final sinLng = math.sin(lngRad);
    final cosLng = math.cos(lngRad);
    
    // Extract ENU components
    final east = -sinLng * rx + cosLng * ry;
    final north = -sinLat * cosLng * rx - sinLat * sinLng * ry + cosLat * rz;
    final up = cosLat * cosLng * rx + cosLat * sinLng * ry + sinLat * rz;
    
    // Formulate final look angles
    final rangeKm = math.sqrt(east*east + north*north + up*up);
    final elevationRad = math.asin(up / rangeKm);
    
    // azimuth logic
    double azimuthRad = math.atan2(east, north);
    double azimuthDeg = azimuthRad * 180.0 / math.pi;
    if (azimuthDeg < 0) azimuthDeg += 360.0;
    
    double elevationDeg = elevationRad * 180.0 / math.pi;

    return {
      'azimuth': azimuthDeg,
      'elevation': elevationDeg,
      'range': rangeKm,
    };
  }
}
