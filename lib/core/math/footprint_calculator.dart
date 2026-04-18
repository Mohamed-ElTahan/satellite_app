import 'dart:math' as math;
import 'look_angle_calculator.dart';

class FootprintCalculator {
  /// Calculates the Earth central angle limit (gamma) for a given minimum elevation.
  /// This determines the size of the footprint cap on the sphere.
  static double calculateFootprintCentralAngleRad(double minElevationDeg, double satelliteAltitudeKm) {
    final minElRad = minElevationDeg * math.pi / 180.0;
    
    // Using law of sines / geometry:
    // gamma = acos(Re / Rs * cos(El)) - El
    final rs = LookAngleCalculator.earthRadiusKm + satelliteAltitudeKm;
    final ratio = LookAngleCalculator.earthRadiusKm / rs;
    double gammaRad = math.acos(ratio * math.cos(minElRad)) - minElRad;
    
    return gammaRad;
  }

  /// Calculates the bounds of the footprint area (max lat, min lat, max lng, min lng).
  /// For a geostationary satellite, it's a symmetrical bounding box around the sub-satellite point.
  static Map<String, double> getFootprintBounds(double satelliteLng, double gammaRad) {
    final gammaDeg = gammaRad * 180.0 / math.pi;
    return {
      'maxLat': gammaDeg,
      'minLat': -gammaDeg,
      'maxLng': satelliteLng + gammaDeg,
      'minLng': satelliteLng - gammaDeg,
    };
  }
}
