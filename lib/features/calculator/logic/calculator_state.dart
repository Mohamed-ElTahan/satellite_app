import 'package:equatable/equatable.dart';
import '../../../../core/models/location_data.dart';
import '../../../../core/models/satellite_output.dart';

class CalculatorState extends Equatable {
  final LocationData inputs;
  final SatelliteOutput output;

  const CalculatorState({
    required this.inputs,
    this.output = const SatelliteOutput(),
  });

  CalculatorState copyWith({
    LocationData? inputs,
    SatelliteOutput? output,
  }) {
    return CalculatorState(
      inputs: inputs ?? this.inputs,
      output: output ?? this.output,
    );
  }

  @override
  List<Object> get props => [inputs, output];
}
