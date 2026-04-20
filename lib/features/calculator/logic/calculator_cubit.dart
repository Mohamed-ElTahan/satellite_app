import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/math/look_angle_calculator.dart';
import '../../../../core/models/location_data.dart';
import 'calculator_state.dart';

class CalculatorCubit extends Cubit<CalculatorState> {
  CalculatorCubit() : super(const CalculatorState(inputs: LocationData())) {
    _updateCalculations(state.inputs);
  }

  void updateInputs({
    double? observerLat,
    double? observerLng,
    double? satelliteLat,
    double? satelliteLng,
  }) {
    final newInputs = state.inputs.copyWith(
      observerLat: observerLat,
      observerLng: observerLng,
      satelliteLat: satelliteLat,
      satelliteLng: satelliteLng,
    );

    _updateCalculations(newInputs);
  }

  void _updateCalculations(LocationData inputs) {
    // Calculate Look Angles
    final lookAngles = LookAngleCalculator.calculate(inputs: inputs);

    emit(state.copyWith(inputs: inputs, output: lookAngles));
  }
}
