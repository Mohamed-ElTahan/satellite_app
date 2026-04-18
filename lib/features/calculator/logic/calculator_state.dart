import 'package:equatable/equatable.dart';
import '../../../../core/models/location_data.dart';

class CalculatorState extends Equatable {
  final LocationData inputs;
  final double azimuth;
  final double elevation;
  final double rangeKm;
  final double footprintCentralAngleRad;
  final bool isTrackingISS;
  final bool signalAcquired;

  const CalculatorState({
    required this.inputs,
    this.azimuth = 0.0,
    this.elevation = 0.0,
    this.rangeKm = 0.0,
    this.footprintCentralAngleRad = 0.0,
    this.isTrackingISS = false,
    this.signalAcquired = false,
  });

  CalculatorState copyWith({
    LocationData? inputs,
    double? azimuth,
    double? elevation,
    double? rangeKm,
    double? footprintCentralAngleRad,
    bool? isTrackingISS,
    bool? signalAcquired,
  }) {
    return CalculatorState(
      inputs: inputs ?? this.inputs,
      azimuth: azimuth ?? this.azimuth,
      elevation: elevation ?? this.elevation,
      rangeKm: rangeKm ?? this.rangeKm,
      footprintCentralAngleRad: footprintCentralAngleRad ?? this.footprintCentralAngleRad,
      isTrackingISS: isTrackingISS ?? this.isTrackingISS,
      signalAcquired: signalAcquired ?? this.signalAcquired,
    );
  }

  @override
  List<Object> get props => [inputs, azimuth, elevation, rangeKm, footprintCentralAngleRad, isTrackingISS, signalAcquired];
}
