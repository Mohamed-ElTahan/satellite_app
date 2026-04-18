import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/math/look_angle_calculator.dart';
import '../../../../core/math/footprint_calculator.dart';
import '../../../../core/models/location_data.dart';
import 'calculator_state.dart';

class CalculatorCubit extends Cubit<CalculatorState> {
  Timer? _trackingTimer;

  CalculatorCubit() : super(const CalculatorState(inputs: LocationData()));

  @override
  Future<void> close() {
    _trackingTimer?.cancel();
    return super.close();
  }

  void toggleISSTracking(bool isTracking) {
    _trackingTimer?.cancel();
    emit(state.copyWith(isTrackingISS: isTracking));

    if (isTracking) {
      // Periodic fetch for ISS Telemetry every 2 seconds
      _trackingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchISS());
      _fetchISS(); // Fetch immediately
    } else {
      // Revert to manual speed tracking
      updateInputs(satelliteSpeed: state.inputs.satelliteSpeed); 
    }
  }

  Future<void> _fetchISS() async {
    try {
      final response = await http.get(Uri.parse('http://api.open-notify.org/iss-now.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final position = data['iss_position'];
        final double lat = double.parse(position['latitude']);
        final double lng = double.parse(position['longitude']);

        final trackedInputs = state.inputs.copyWith(
          satelliteLat: lat,
          satelliteLng: lng,
          satelliteAltitudeKm: 420.0, // Fixed average ISS altitude
        );
        _updateCalculations(trackedInputs);
      }
    } catch (e) {
      // Handle silently for now or emit error state
    }
  }

  void updateInputs({
    double? observerLat,
    double? observerLng,
    double? satelliteLat,
    double? satelliteLng,
    double? satelliteAltitudeKm,
    double? satelliteSpeed,
    double? minElevation,
  }) {
    if (state.isTrackingISS && (satelliteLng != null || satelliteLat != null || satelliteAltitudeKm != null)) {
      // Ignore manual overrides for satellite coordinates when tracking ISS
      return;
    }

    final newInputs = state.inputs.copyWith(
      observerLat: observerLat,
      observerLng: observerLng,
      satelliteLat: satelliteLat,
      satelliteLng: satelliteLng,
      satelliteAltitudeKm: satelliteAltitudeKm,
      satelliteSpeed: satelliteSpeed,
      minElevation: minElevation,
    );

    _updateCalculations(newInputs);

    // Restart timer if speed is set and not tracking API
    if (!state.isTrackingISS) {
      _trackingTimer?.cancel();
      if (newInputs.satelliteSpeed != 0.0) {
        _trackingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
          // Update satellite longitude based on speed (degrees per second -> per 50ms is / 20)
          double updatedLng = state.inputs.satelliteLng + (state.inputs.satelliteSpeed / 20.0);
          if (updatedLng > 180) updatedLng -= 360;
          if (updatedLng < -180) updatedLng += 360;

          final trackedInputs = state.inputs.copyWith(satelliteLng: updatedLng);
          _updateCalculations(trackedInputs);
        });
      }
    }
  }

  void _updateCalculations(LocationData inputs) {
    // Calculate Look Angles
    final lookAngles = LookAngleCalculator.calculate(
      observerLat: inputs.observerLat,
      observerLng: inputs.observerLng,
      satelliteLat: inputs.satelliteLat,
      satelliteLng: inputs.satelliteLng,
      satelliteAltitudeKm: inputs.satelliteAltitudeKm,
    );

    // Calculate Footprint Central Angle Limit (Gamma)
    final gammaRad = FootprintCalculator.calculateFootprintCentralAngleRad(inputs.minElevation, inputs.satelliteAltitudeKm);

    // Determines if the observer is physically within the transmission cone of the satellite
    final bool signalAcquired = lookAngles['elevation']! >= inputs.minElevation;

    emit(state.copyWith(
      inputs: inputs,
      azimuth: lookAngles['azimuth'],
      elevation: lookAngles['elevation'],
      rangeKm: lookAngles['range'],
      footprintCentralAngleRad: gammaRad,
      signalAcquired: signalAcquired,
    ));
  }
}
