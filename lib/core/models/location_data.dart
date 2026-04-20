import 'package:equatable/equatable.dart';

class LocationData extends Equatable {
  final double observerLat;
  final double observerLng;
  final double satelliteLat;
  final double satelliteLng;
  final double satelliteAltitudeKm;

  const LocationData({
    this.observerLat = 30.0,
    this.observerLng = 31.0,
    this.satelliteLat = 0.0,
    this.satelliteLng = -7.0,
    this.satelliteAltitudeKm = 35786.0,
  });

  LocationData copyWith({
    double? observerLat,
    double? observerLng,
    double? satelliteLat,
    double? satelliteLng,
    double? satelliteAltitudeKm,
  }) {
    return LocationData(
      observerLat: observerLat ?? this.observerLat,
      observerLng: observerLng ?? this.observerLng,
      satelliteLat: satelliteLat ?? this.satelliteLat,
      satelliteLng: satelliteLng ?? this.satelliteLng,
      satelliteAltitudeKm: satelliteAltitudeKm ?? this.satelliteAltitudeKm,
    );
  }

  @override
  List<Object?> get props => [
        observerLat,
        observerLng,
        satelliteLat,
        satelliteLng,
        satelliteAltitudeKm,
      ];
}
