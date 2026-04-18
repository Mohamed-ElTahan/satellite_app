import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
              padding: const EdgeInsets.all(24.0),
              child: BlocBuilder<CalculatorCubit, CalculatorState>(
                builder: (context, state) {
                  return Stack(
                    children: [
                      // Responsive Panels Overlay
                      Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: InputPanel(cubit: context.read<CalculatorCubit>()),
                          ),
                          if (state.rangeKm > 0)
                            Align(
                              alignment: Alignment.topRight,
                              child: DataPanel(state: state),
                            ),
                        ],
                      ),
                      
                      // Bottom center controls label
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "DRAG TO PAN • BUTTONS TO ZOOM",
                            style: const TextStyle(color: Colors.white54, letterSpacing: 1.5, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      // Bottom right Zoom Controls
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                              child: const Icon(Icons.remove, color: Colors.white),
                              onPressed: () {
                                context.read<RenderCubit>().updateZoom(0.8);
                              },
                            ),
                          ],
                        ),
                      )
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
