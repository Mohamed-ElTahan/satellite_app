import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/utils/theme.dart';
import '../../logic/calculator_cubit.dart';
import '../../logic/calculator_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InputPanel extends StatefulWidget {
  final CalculatorCubit cubit;

  const InputPanel({super.key, required this.cubit});

  @override
  State<InputPanel> createState() => _InputPanelState();
}

class _InputPanelState extends State<InputPanel> {
  final _satLatCtrl = TextEditingController(text: '0.0');
  final _satLngCtrl = TextEditingController(text: '0.0');
  final _satAltCtrl = TextEditingController(text: '35000');
  final _satSpeedCtrl = TextEditingController(text: '0.0');
  final _obsLatCtrl = TextEditingController(text: '0.0');
  final _obsLngCtrl = TextEditingController(text: '0.0');

  void _submit() {
      final sLat = double.tryParse(_satLatCtrl.text);
      final sLng = double.tryParse(_satLngCtrl.text);
      final sAlt = double.tryParse(_satAltCtrl.text);
      final sSpeed = double.tryParse(_satSpeedCtrl.text);
      final oLat = double.tryParse(_obsLatCtrl.text);
      final oLng = double.tryParse(_obsLngCtrl.text);

      if (oLat != null && oLng != null) {
        context.read<CalculatorCubit>().updateInputs(
          satelliteLat: sLat ?? 0.0,
          satelliteLng: sLng ?? 0.0,
          satelliteAltitudeKm: sAlt ?? 35000.0,
          satelliteSpeed: sSpeed ?? 0.0,
          observerLat: oLat,
          observerLng: oLng,
      );
    }
  }

  @override
  void dispose() {
    _satLatCtrl.dispose();
    _satLngCtrl.dispose();
    _satAltCtrl.dispose();
    _satSpeedCtrl.dispose();
    _obsLatCtrl.dispose();
    _obsLngCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.25,
          height: MediaQuery.sizeOf(context).height * 0.25,
          constraints: const BoxConstraints(minWidth: 250, minHeight: 200), // safety bound for edge cases
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
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'PARAMETERS',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  BlocBuilder<CalculatorCubit, CalculatorState>(
                    buildWhen: (p, c) => p.isTrackingISS != c.isTrackingISS,
                    builder: (context, state) {
                      return Row(
                        children: [
                          Text('ISS LIVE', style: TextStyle(color: state.isTrackingISS ? Colors.greenAccent : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                          Switch(
                            value: state.isTrackingISS,
                            activeTrackColor: Colors.greenAccent,
                            onChanged: (val) {
                               context.read<CalculatorCubit>().toggleISSTracking(val);
                            },
                          ),
                        ],
                      );
                    },
                  )
                ]
              ),
              const SizedBox(height: 8),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      BlocBuilder<CalculatorCubit, CalculatorState>(
                builder: (context, state) {
                  // If tracking ISS, sync UI text fields with live data securely
                  if (state.isTrackingISS) {
                     _satLatCtrl.text = state.inputs.satelliteLat.toStringAsFixed(2);
                     _satLngCtrl.text = state.inputs.satelliteLng.toStringAsFixed(2);
                     _satAltCtrl.text = state.inputs.satelliteAltitudeKm.toStringAsFixed(0);
                  }
                  
                  return Column(
                    children: [
                      _buildField('Sat Latitude (°)', _satLatCtrl, disabled: state.isTrackingISS),
                      const SizedBox(height: 12),
                      _buildField('Sat Longitude (°)', _satLngCtrl, disabled: state.isTrackingISS),
                      const SizedBox(height: 12),
                      _buildField('Sat Altitude (km)', _satAltCtrl, disabled: state.isTrackingISS),
                      const SizedBox(height: 12),
                    ]
                  );
                }
              ),
              _buildField('Orbital Speed (°/sec)', _satSpeedCtrl),
              const SizedBox(height: 12),
              _buildField('Observer Latitude (°)', _obsLatCtrl),
              const SizedBox(height: 12),
              _buildField('Observer Longitude (°)', _obsLngCtrl),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SatelliteTheme.earthLines.withValues(
                      alpha: 0.2,
                    ),
                    side: const BorderSide(color: SatelliteTheme.earthLines),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _submit,
                  child: Text(
                    'CALCULATE',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: SatelliteTheme.earthLines,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
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

  Widget _buildField(String label, TextEditingController controller, {bool disabled = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: !disabled,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'RobotoMono',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: disabled ? Colors.black38 : Colors.white10,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}
