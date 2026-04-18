import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

class CoordinateConverter {
  /// Converts Latitude, Longitude, and internal unit Radius into a 3D Cartesian vector.
  /// Standard 3D system:
  /// Y-axis is UP (North Pole)
  /// X-axis is Right
  /// Z-axis is towards the viewer (Prime Meridian when viewed from X=0).
  static Vector3 latLngToVector3(double latDeg, double lngDeg, double radius) {
    final latRad = latDeg * math.pi / 180.0;
    final lngRad = lngDeg * math.pi / 180.0;

    // Y is the vertical axis
    final y = radius * math.sin(latRad);
    
    // Project radius onto horizontal XZ plane
    final rxz = radius * math.cos(latRad);
    
    // X and Z coordinates
    final x = rxz * math.sin(lngRad);
    final z = rxz * math.cos(lngRad);

    return Vector3(x, y, z);
  }
}
