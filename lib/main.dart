import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/utils/theme.dart';
import 'features/calculator/logic/calculator_cubit.dart';
import 'features/visualization_3d/logic/render_cubit.dart';
import 'features/calculator/view/calculator_screen.dart';

void main() {
  runApp(const SatelliteApp());
}

class SatelliteApp extends StatelessWidget {
  const SatelliteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CalculatorCubit()),
        BlocProvider(create: (_) => RenderCubit()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Satellite Tracker',
        theme: SatelliteTheme.themeData,
        home: const CalculatorScreen(),
      ),
    );
  }
}

