import 'package:equatable/equatable.dart';

class RenderState extends Equatable {
  final double pan;
  final double tilt;
  final double zoom;
  final bool isFollowing;

  const RenderState({
    required this.pan,
    required this.tilt,
    required this.zoom,
    this.isFollowing = false,
  });

  factory RenderState.initial() {
    return const RenderState(
      pan: -0.012,
      tilt: 0.550,
      zoom: 0.307,
      isFollowing: false,
    );
  }

  RenderState copyWith({
    double? pan,
    double? tilt,
    double? zoom,
    bool? isFollowing,
  }) {
    return RenderState(
      pan: pan ?? this.pan,
      tilt: tilt ?? this.tilt,
      zoom: zoom ?? this.zoom,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  @override
  List<Object?> get props => [pan, tilt, zoom, isFollowing];
}
