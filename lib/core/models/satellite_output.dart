import 'package:equatable/equatable.dart';

class SatelliteOutput extends Equatable {
  final double azimuth;
  final double elevation;
  final double rangeKm;

  const SatelliteOutput({
    this.azimuth = 0.0,
    this.elevation = 0.0,
    this.rangeKm = 0.0,
  });

  @override
  List<Object> get props => [azimuth, elevation, rangeKm];
}
