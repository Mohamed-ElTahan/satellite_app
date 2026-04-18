class LocationData {
  final double observerLat;
  final double observerLng;
  final double satelliteLat;
  final double satelliteLng;
  final double satelliteAltitudeKm;
  final double satelliteSpeed; // in degrees per second
  final double minElevation;

  const LocationData({
    this.observerLat = 0.0,
    this.observerLng = 0.0,
    this.satelliteLat = 0.0,
    this.satelliteLng = 0.0,
    this.satelliteAltitudeKm = 35000.0,
    this.satelliteSpeed = 0.0,
    this.minElevation = 0.0,
  });

  LocationData copyWith({
    double? observerLat,
    double? observerLng,
    double? satelliteLat,
    double? satelliteLng,
    double? satelliteAltitudeKm,
    double? satelliteSpeed,
    double? minElevation,
  }) {
    return LocationData(
      observerLat: observerLat ?? this.observerLat,
      observerLng: observerLng ?? this.observerLng,
      satelliteLat: satelliteLat ?? this.satelliteLat,
      satelliteLng: satelliteLng ?? this.satelliteLng,
      satelliteAltitudeKm: satelliteAltitudeKm ?? this.satelliteAltitudeKm,
      satelliteSpeed: satelliteSpeed ?? this.satelliteSpeed,
      minElevation: minElevation ?? this.minElevation,
    );
  }
}
