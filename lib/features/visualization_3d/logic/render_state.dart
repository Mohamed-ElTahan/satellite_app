import 'package:equatable/equatable.dart';

class RenderState extends Equatable {
  final double pan;
  final double tilt;
  final double zoom; // Added zoom

  const RenderState({
    required this.pan,
    required this.tilt,
    required this.zoom,
  });

  factory RenderState.initial() {
    return const RenderState(pan: 0.0, tilt: 0.2, zoom: 1.0);
  }

  RenderState copyWith({
    double? pan,
    double? tilt,
    double? zoom,
  }) {
    return RenderState(
      pan: pan ?? this.pan,
      tilt: tilt ?? this.tilt,
      zoom: zoom ?? this.zoom,
    );
  }

  @override
  List<Object?> get props => [pan, tilt, zoom];
}
