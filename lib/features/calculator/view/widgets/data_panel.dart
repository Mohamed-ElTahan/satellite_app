import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/utils/theme.dart';
import '../../logic/calculator_state.dart';

class DataPanel extends StatelessWidget {
  final CalculatorState state;

  const DataPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.95,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: SatelliteTheme.panelGlass,
            border: Border.all(color: SatelliteTheme.panelBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(
                context,
                'AZIMUTH',
                '${state.output.azimuth.toStringAsFixed(2)}°',
              ),
              _buildVerticalDivider(),
              _buildMetric(
                context,
                'ELEVATION',
                '${state.output.elevation.toStringAsFixed(2)}°',
                color: state.output.elevation >= 0
                    ? Colors.greenAccent
                    : Colors.redAccent,
              ),
              _buildVerticalDivider(),
              _buildMetric(
                context,
                'RANGE',
                '${state.output.rangeKm.toStringAsFixed(0)} km',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 16,
            fontFamily: 'RobotoMono',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 24, width: 1, color: Colors.white10);
  }
}
