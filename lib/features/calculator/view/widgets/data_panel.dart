import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/utils/theme.dart';
import '../../logic/calculator_state.dart';

class DataPanel extends StatelessWidget {
  final CalculatorState state;

  const DataPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.rangeKm <= 0.0) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.25,
          height: MediaQuery.sizeOf(context).height * 0.25,
          constraints: const BoxConstraints(minWidth: 250, minHeight: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SatelliteTheme.panelGlass,
            border: Border.all(color: SatelliteTheme.panelBorder),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TELEMETRY DATA', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: state.signalAcquired ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: state.signalAcquired ? Colors.greenAccent : Colors.redAccent),
                ),
                child: Center(
                  child: Text(
                    state.signalAcquired ? 'SIGNAL ACQUIRED' : 'LOS OBSTRUCTED',
                    style: TextStyle(
                      color: state.signalAcquired ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildDataRow(context, 'SAT LAT', '${state.inputs.satelliteLat.toStringAsFixed(2)}°'),
              const SizedBox(height: 8),
              _buildDataRow(context, 'SAT LNG', '${state.inputs.satelliteLng.toStringAsFixed(2)}°'),
              const SizedBox(height: 8),
              _buildDataRow(context, 'ALTITUDE', '${state.inputs.satelliteAltitudeKm.toStringAsFixed(0)} km'),
              const SizedBox(height: 8),
              _buildDataRow(context, 'SPEED', '${(state.inputs.satelliteSpeed * 3600.0).toStringAsFixed(2)} °/hr'),
              const SizedBox(height: 8),
              _buildDataRow(context, 'AZIMUTH (TRUE)', '${state.azimuth.toStringAsFixed(2)}°'),
              const SizedBox(height: 8),
              _buildDataRow(context, 'ELEVATION', '${state.elevation.toStringAsFixed(2)}°', 
                  color: state.elevation >= 0 ? SatelliteTheme.observerColor : Colors.redAccent),
              const SizedBox(height: 8),
                      _buildDataRow(context, 'RANGE', '${state.rangeKm.toStringAsFixed(0)} km'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60)),
        Text(
          value, 
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          )
        ),
      ],
    );
  }
}
