import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/theme.dart';
import '../../visualization_3d/logic/render_state.dart';
import '../logic/calculator_cubit.dart';
import '../logic/calculator_state.dart';
import 'widgets/input_panel.dart';
import 'widgets/data_panel.dart';
import '../../visualization_3d/view/scene_3d_view.dart';
import '../../visualization_3d/logic/render_cubit.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 3D Background - Receives gestures
          const Scene3DView(),

          // Floating UI Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: BlocBuilder<CalculatorCubit, CalculatorState>(
                builder: (context, state) {
                  return Stack(
                    children: [
                      // Top-aligned minimalist panels
                      Align(
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InputPanel(cubit: context.read<CalculatorCubit>()),
                            const SizedBox(height: 2),
                            DataPanel(state: state),
                          ],
                        ),
                      ),

                      // Bottom center controls label
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "DRAG TO PAN • BUTTONS TO ZOOM",
                            style: TextStyle(
                              color: Colors.white54,
                              letterSpacing: 1.5,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      // Bottom right Controls
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BlocBuilder<RenderCubit, RenderState>(
                              builder: (context, renderState) {
                                return FloatingActionButton(
                                  heroTag: "follow_toggle",
                                  mini: true,
                                  backgroundColor: renderState.isFollowing
                                      ? SatelliteTheme.panelBorder
                                      : Colors.black45,
                                  child: Icon(
                                    renderState.isFollowing
                                        ? Icons.gps_fixed
                                        : Icons.gps_not_fixed,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    final inputs =
                                        context.read<CalculatorCubit>().state.inputs;
                                    final targetPan =
                                        -inputs.satelliteLng * (math.pi / 180.0);
                                    final targetTilt =
                                        -inputs.satelliteLat * (math.pi / 180.0);

                                    context.read<RenderCubit>().toggleFollow(
                                      syncPan: targetPan,
                                      syncTilt: targetTilt,
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            FloatingActionButton(
                              heroTag: "zoom_in",
                              mini: true,
                              backgroundColor: Colors.black45,
                              child: const Icon(Icons.add, color: Colors.white),
                              onPressed: () {
                                context.read<RenderCubit>().updateZoom(1.2);
                              },
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton(
                              heroTag: "zoom_out",
                              mini: true,
                              backgroundColor: Colors.black45,
                              child: const Icon(
                                Icons.remove,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                context.read<RenderCubit>().updateZoom(0.8);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
