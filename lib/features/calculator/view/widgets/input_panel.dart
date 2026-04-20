import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/utils/theme.dart';
import '../../logic/calculator_cubit.dart';

class InputPanel extends StatefulWidget {
  final CalculatorCubit cubit;

  const InputPanel({super.key, required this.cubit});

  @override
  State<InputPanel> createState() => _InputPanelState();
}

class _InputPanelState extends State<InputPanel> {
  late final TextEditingController _obsLatCtrl;
  late final TextEditingController _obsLngCtrl;
  late final TextEditingController _satLatCtrl;
  late final TextEditingController _satLngCtrl;

  @override
  void initState() {
    super.initState();
    _obsLatCtrl = TextEditingController(
      text: widget.cubit.state.inputs.observerLat.toString(),
    );
    _obsLngCtrl = TextEditingController(
      text: widget.cubit.state.inputs.observerLng.toString(),
    );
    _satLatCtrl = TextEditingController(
      text: widget.cubit.state.inputs.satelliteLat.toString(),
    );
    _satLngCtrl = TextEditingController(
      text: widget.cubit.state.inputs.satelliteLng.toString(),
    );
  }

  void _onChanged() {
    final oLat = double.tryParse(_obsLatCtrl.text);
    final oLng = double.tryParse(_obsLngCtrl.text);
    final sLat = double.tryParse(_satLatCtrl.text);
    final sLng = double.tryParse(_satLngCtrl.text);

    if (oLat != null && oLng != null && sLat != null && sLng != null) {
      widget.cubit.updateInputs(
        observerLat: oLat,
        observerLng: oLng,
        satelliteLat: sLat,
        satelliteLng: sLng,
      );
    }
  }

  @override
  void dispose() {
    _obsLatCtrl.dispose();
    _obsLngCtrl.dispose();
    _satLatCtrl.dispose();
    _satLngCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.98,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: SatelliteTheme.panelGlass,
            border: Border.all(color: SatelliteTheme.panelBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                'Observer & Satellite',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: Colors.white70),
              ),
              const Spacer(),
              _buildCompactField('Obs Lat', _obsLatCtrl),
              const SizedBox(width: 4),
              _buildCompactField('Obs Lng', _obsLngCtrl),
              const SizedBox(width: 4),
              _buildCompactField('Sat Lat', _satLatCtrl),
              const SizedBox(width: 4),
              _buildCompactField('Sat Lng', _satLngCtrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactField(String label, TextEditingController controller) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),

          TextField(
            controller: controller,
            onChanged: (_) => _onChanged(),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'RobotoMono',
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 6,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
