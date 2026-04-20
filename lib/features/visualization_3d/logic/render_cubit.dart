import 'package:flutter_bloc/flutter_bloc.dart';
import 'render_state.dart';

class RenderCubit extends Cubit<RenderState> {
  RenderCubit() : super(RenderState.initial());

  void updateRotation(double deltaPan, double deltaTilt) {
    emit(state.copyWith(
      pan: state.pan + deltaPan,
      tilt: (state.tilt + deltaTilt).clamp(-1.5, 1.5),
      isFollowing: false, // Manual rotation breaks focus
    ));
  }

  void updateZoom(double deltaZoom) {
    emit(state.copyWith(
      zoom: (state.zoom * deltaZoom).clamp(0.2, 5.0),
    ));
  }

  void toggleFollow({double? syncPan, double? syncTilt}) {
    emit(state.copyWith(
      isFollowing: !state.isFollowing,
      pan: syncPan ?? state.pan,
      tilt: syncTilt ?? state.tilt,
    ));
  }

  void resetCamera() {
    emit(RenderState.initial());
  }
}
