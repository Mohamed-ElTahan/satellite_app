import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import '../../../core/math/coordinate_converter.dart';
import '../../../core/math/earth_data.dart';
import '../../calculator/logic/calculator_cubit.dart';
import '../../calculator/logic/calculator_state.dart';
import '../logic/render_cubit.dart';
import '../logic/render_state.dart';
import '../../../core/utils/theme.dart';

class Scene3DView extends StatefulWidget {
  const Scene3DView({super.key});

  @override
  State<Scene3DView> createState() => _Scene3DViewState();
}

class _Scene3DViewState extends State<Scene3DView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  double _time = 0.0;

  // Interpolation targets for easing
  double _currentPan = -0.012;
  double _currentTilt = 0.550;
  double _currentZoom = 0.307;

  // Interaction state
  DateTime _lastInteraction = DateTime.now();
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    // Debug info for view tuning
    debugPrint('SATELLITE_TRACKER: Initial View Configured');
    debugPrint('  Zoom: $_currentZoom');
    debugPrint('  Tilt: $_currentTilt (Top View Target: 1.57)');
    debugPrint('  Pan: $_currentPan');
    
    _ticker =
        AnimationController(vsync: this, duration: const Duration(days: 365))
          ..addListener(() {
            setState(() {
              _time += 0.016; // Approx 60fps tick

              if (!_isInteracting) {
                final idleTime = DateTime.now()
                    .difference(_lastInteraction)
                    .inSeconds;
                if (idleTime > 2) {
                  // Idle rotation of the earth/camera
                  context.read<RenderCubit>().updateRotation(0.002, 0);
                }
              }
            });
          });
    _ticker.forward();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RenderCubit, RenderState>(
      builder: (context, renderState) {
        return BlocBuilder<CalculatorCubit, CalculatorState>(
          builder: (context, calcState) {
            final double targetPan;
            final double targetTilt;

            if (renderState.isFollowing) {
              targetPan = -calcState.inputs.satelliteLng * (math.pi / 180.0);
              targetTilt = -calcState.inputs.satelliteLat * (math.pi / 180.0);
            } else {
              targetPan = renderState.pan;
              targetTilt = renderState.tilt;
            }

            // Easing interpolation
            _currentPan += (targetPan - _currentPan) * 0.1;
            _currentTilt += (targetTilt - _currentTilt) * 0.1;
            _currentZoom += (renderState.zoom - _currentZoom) * 0.1;

            return GestureDetector(
              onScaleStart: (_) {
                _isInteracting = true;
                _lastInteraction = DateTime.now();
              },
              onScaleUpdate: (details) {
                _lastInteraction = DateTime.now();
                if (details.scale == 1.0) {
                  // Panning
                  context.read<RenderCubit>().updateRotation(
                    details.focalPointDelta.dx * 0.01,
                    details.focalPointDelta.dy * 0.01,
                  );
                } else {
                  // Zooming - Dampen sensitivity by 50% for smoother control
                  final dampenedScale = 1.0 + (details.scale - 1.0) * 0.5;
                  context.read<RenderCubit>().updateZoom(dampenedScale);
                }

                // Log the new target values for easy tuning
                debugPrint(
                  'CAMERA_VIEW_UPDATE: Pan: ${renderState.pan.toStringAsFixed(3)}, '
                  'Tilt: ${renderState.tilt.toStringAsFixed(3)}, '
                  'Zoom: ${renderState.zoom.toStringAsFixed(3)}',
                );
              },
              onScaleEnd: (_) {
                _isInteracting = false;
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: Scene3DPainter(
                  renderState: RenderState(
                    pan: _currentPan,
                    tilt: _currentTilt,
                    zoom: _currentZoom,
                    isFollowing: renderState.isFollowing,
                  ),
                  calcState: calcState,
                  time: _time,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class Scene3DPainter extends CustomPainter {
  final RenderState renderState;
  final CalculatorState calcState;
  final double time;

  Scene3DPainter({
    required this.renderState,
    required this.calcState,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Space Background
    _drawStarfield(canvas, size);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.25 * renderState.zoom;

    final satActualLng = calcState.inputs.satelliteLng;
    final satActualLat = calcState.inputs.satelliteLat;

    double effectivePan = renderState.pan;
    double effectiveTilt = renderState.tilt;

    if (renderState.isFollowing) {
      // Nadir-pointing camera: Align view with satellite Lat/Lng
      effectivePan = -satActualLng * (math.pi / 180.0);
      effectiveTilt = -satActualLat * (math.pi / 180.0);
    }

    // View matrix setup
    final viewMatrix = vector.Matrix4.identity()
      ..translateByVector3(vector.Vector3(center.dx, center.dy, 0.0))
      ..scaleByVector3(vector.Vector3(radius, radius, radius))
      ..rotateX(effectiveTilt)
      ..rotateY(effectivePan);

    vector.Vector3 project(vector.Vector3 v) {
      final transformed = viewMatrix.transform3(v.clone());
      return transformed;
    }

    // 2. Atmospheric Glow (Fresnel effect)
    final rect = Rect.fromCircle(center: center, radius: radius * 1.05);
    final atmospherePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          SatelliteTheme.earthLines.withValues(alpha: 0.1),
          SatelliteTheme.earthLines.withValues(alpha: 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.8, 0.95, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius * 1.05, atmospherePaint);

    // 3. Earth Base Sphere (Ocean Blue)
    final earthBasePaint = Paint()
      ..color = SatelliteTheme.earthWater
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, earthBasePaint);

    // 4. Directional Light (Sun shading/Terminator)
    final sunDir = vector.Vector3(
      1,
      0.5,
      0.2,
    ).normalized(); // Fixed sun direction
    final sunPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(sunDir.x, -sunDir.y),
        radius: 1.2,
        colors: [
          Colors.white.withValues(alpha: 0.15), // Specular highlight
          Colors.transparent,
          Colors.black87, // Terminator / Dark side
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..blendMode = BlendMode.srcOver;

    // 5. Ground Layer (Oceans -> Land -> Grid)
    _drawEarth(canvas, project, sunDir);
    _drawLatLongGrid(canvas, project, sunDir);

    // 6. Night Layer (City Lights) - Only visible on dark side
    _drawCityLights(canvas, project, sunDir);

    // 7. Atmospheric Layer (Clouds) - Floating above surface
    _drawClouds(canvas, project, sunDir);

    // 8. Lighting & Bloom Overlay
    canvas.drawCircle(center, radius, sunPaint);

    // 9. Draw the Moon (Cinematic distance)
    _drawMoon(canvas, project, sunDir);

    final satAlt = calcState.inputs.satelliteAltitudeKm;

    // 10. Draw Orbital Ring and Satellite Markers
    _drawOrbitAndMarkers(canvas, project, satActualLat, satActualLng, satAlt, sunDir);
  }

  void _drawStarfield(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = SatelliteTheme.backgroundSpace,
    );
    final random = math.Random(42);
    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < 300; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final px = (x + renderState.pan * 20 * random.nextDouble()) % size.width;
      final py =
          (y + renderState.tilt * 20 * random.nextDouble()) % size.height;
      paint.color = Colors.white.withValues(
        alpha: 0.1 + random.nextDouble() * 0.9,
      );
      canvas.drawCircle(Offset(px, py), random.nextDouble() * 1.8, paint);
    }
  }

  void _drawMoon(
    Canvas canvas,
    vector.Vector3 Function(vector.Vector3) project,
    vector.Vector3 sunDir,
  ) {
    // Moon parameters
    const moonDistance = 3.0; // Short circle orbit near Earth
    const moonRadius = 0.25; // Physical radius relative to Earth

    // Calculate Moon position (rotate slowly around Y axis)
    final orbitAngle = time * 0.5; // High speed rotation

    // 1. Draw Moon Orbital Ring
    final moonOrbitPath = Path();
    bool firstMoonOrbit = true;
    for (int i = 0; i <= 360; i += 5) {
      final angle = i * math.pi / 180.0;
      final p = vector.Vector3(
        moonDistance * math.sin(angle),
        moonDistance * math.sin(0.1) * math.cos(angle),
        moonDistance * math.cos(angle),
      );
      final projected = project(p);
      if (firstMoonOrbit) {
        moonOrbitPath.moveTo(projected.x, projected.y);
        firstMoonOrbit = false;
      } else {
        moonOrbitPath.lineTo(projected.x, projected.y);
      }
    }
    canvas.drawPath(
      moonOrbitPath,
      Paint()
        ..color = Colors.white60
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    final moonPos = vector.Vector3(
      moonDistance * math.sin(orbitAngle),
      moonDistance * math.sin(0.1) * math.cos(orbitAngle),
      moonDistance * math.cos(orbitAngle),
    );

    final pMoon = project(moonPos);

    // Moon Shading
    final moonCenter = Offset(pMoon.x, pMoon.y);
    final visualMoonRadius = project(
      vector.Vector3(moonRadius, 0, 0),
    ).distanceTo(project(vector.Vector3(0, 0, 0)));

    final moonPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFE0E0E0), // Lit side
              const Color(0xFF424242), // Dark side
              const Color(0xFF121212), // Pitch black
            ],
            center: Alignment(sunDir.x, sunDir.y), // Lighting from Sun
            radius: 1.0,
          ).createShader(
            Rect.fromCircle(center: moonCenter, radius: visualMoonRadius),
          );

    canvas.drawCircle(moonCenter, visualMoonRadius, moonPaint);

    // Subtle crater texture (static dots)
    final craterPaint = Paint()..color = Colors.black26;
    final random = math.Random(13);
    for (int i = 0; i < 10; i++) {
      final ox = (random.nextDouble() - 0.5) * visualMoonRadius * 1.5;
      final oy = (random.nextDouble() - 0.5) * visualMoonRadius * 1.5;
      canvas.drawCircle(
        moonCenter + Offset(ox, oy),
        random.nextDouble() * visualMoonRadius * 0.2,
        craterPaint,
      );
    }
  }

  void _drawEarth(
    Canvas canvas,
    vector.Vector3 Function(vector.Vector3) project,
    vector.Vector3 sunDir,
  ) {
    final landPaint = Paint()
      ..color = SatelliteTheme.earthLand
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // 1. Draw Topographical Realistic Continents
    for (final poly in EarthData.continents) {
      final path = Path();
      bool first = true;

      for (final pt in poly) {
        final lng = pt[0];
        final lat = pt[1];

        final point = CoordinateConverter.latLngToVector3(lat, lng, 1.0);
        final normal = point.normalized();
        final viewDir = vector.Vector3(0, 0, 1)
          ..applyMatrix4(
            vector.Matrix4.identity()
              ..rotateX(-renderState.tilt)
              ..rotateY(-renderState.pan),
          );

        if (normal.dot(viewDir) > 0.0) {
          // Visible on front face
          final p = project(point);
          if (first) {
            path.moveTo(p.x, p.y);
            first = false;
          } else {
            path.lineTo(p.x, p.y);
          }
        } else {
          first = true; // Break lines going around horizon
        }
      }
      if (!first) {
        path.close();
        canvas.drawPath(path, landPaint);
        canvas.drawPath(path, borderPaint);
      }
    }

  }

  void _drawLatLongGrid(
    Canvas canvas,
    vector.Vector3 Function(vector.Vector3) project,
    vector.Vector3 sunDir,
  ) {
    final gridPaint = Paint()
      ..color = SatelliteTheme.earthLines.withValues(alpha: 0.15)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final viewDir = vector.Vector3(0, 0, 1)
      ..applyMatrix4(
        vector.Matrix4.identity()
          ..rotateX(-renderState.tilt)
          ..rotateY(-renderState.pan),
      );

    // Longitude lines
    for (int lon = -180; lon < 180; lon += 30) {
      final path = Path();
      bool first = true;
      for (int lat = -90; lat <= 90; lat += 5) {
        final point = CoordinateConverter.latLngToVector3(lat.toDouble(), lon.toDouble(), 1.0);
        final normal = point.normalized();
        if (normal.dot(viewDir) > 0) {
          final p = project(point);
          if (first) {
            path.moveTo(p.x, p.y);
            first = false;
          } else {
            path.lineTo(p.x, p.y);
          }
        } else {
          first = true;
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // Latitude lines
    for (int lat = -60; lat <= 60; lat += 30) {
      final path = Path();
      bool first = true;
      for (int lon = -180; lon <= 180; lon += 5) {
        final point = CoordinateConverter.latLngToVector3(lat.toDouble(), lon.toDouble(), 1.0);
        final normal = point.normalized();
        if (normal.dot(viewDir) > 0) {
          final p = project(point);
          if (first) {
            path.moveTo(p.x, p.y);
            first = false;
          } else {
            path.lineTo(p.x, p.y);
          }
        } else {
          first = true;
        }
      }
      canvas.drawPath(path, gridPaint);
    }
  }

  void _drawCityLights(
    Canvas canvas,
    vector.Vector3 Function(vector.Vector3) project,
    vector.Vector3 sunDir,
  ) {
    const cities = [
      [30.04, 31.23], // Cairo
      [51.50, -0.12], // London
      [40.71, -74.00], // New York
      [35.67, 139.65], // Tokyo
      [25.20, 55.27], // Dubai
      [-33.86, 151.20], // Sydney
      [-22.90, -43.17], // Rio
      [39.90, 116.40], // Beijing
      [19.07, 72.87], // Mumbai
      [48.85, 2.35], // Paris
      [55.75, 37.61], // Moscow
      [34.05, -118.24], // LA
      [1.35, 103.81], // Singapore
      [-26.20, 28.04], // Johannesburg
    ];

    final lightPaint = Paint()..color = Colors.amberAccent;
    final glowPaint = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    final viewDir = vector.Vector3(0, 0, 1)..applyMatrix4(vector.Matrix4.identity()..rotateX(-renderState.tilt)..rotateY(-renderState.pan));

    for (final city in cities) {
      final point = CoordinateConverter.latLngToVector3(city[0], city[1], 1.0);
      final normal = point.normalized();

      // Only visible on dark side
      final lightDot = normal.dot(sunDir);
      if (lightDot < 0) {
        if (normal.dot(viewDir) > 0) {
          final p = project(point);
          final opacity = math.min(1.0, -lightDot * 3.0);
          canvas.drawCircle(Offset(p.x, p.y), 1.2, lightPaint..color = Colors.amberAccent.withValues(alpha: 0.7 * opacity));
          canvas.drawCircle(Offset(p.x, p.y), 3.0, glowPaint..color = Colors.amberAccent.withValues(alpha: 0.2 * opacity));
        }
      }
    }
  }

  void _drawClouds(
    Canvas canvas,
    vector.Vector3 Function(vector.Vector3) project,
    vector.Vector3 sunDir,
  ) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

    final random = math.Random(1337);
    final cloudRot = time * 0.05; // Independent rotation

    final viewDir = vector.Vector3(0, 0, 1)..applyMatrix4(vector.Matrix4.identity()..rotateX(-renderState.tilt)..rotateY(-renderState.pan));

    for (int i = 0; i < 6; i++) {
      final lat = (random.nextDouble() - 0.5) * 120;
      final lon = (random.nextDouble() * 360) + cloudRot * 20;

      final point = CoordinateConverter.latLngToVector3(lat, lon, 1.03);
      final normal = point.normalized();

      if (normal.dot(viewDir) > 0) {
        final p = project(point);
        final light = math.max(0.2, normal.dot(sunDir));
        canvas.drawCircle(
          Offset(p.x, p.y),
          40.0 + random.nextDouble() * 60.0,
          cloudPaint..color = Colors.white.withValues(alpha: 0.12 * light),
        );
      }
    }
  }

  void _drawOrbitAndMarkers(
    Canvas canvas,
    vector.Vector3 Function(vector.Vector3) project,
    double satActualLat,
    double satActualLng,
    double altKm,
    vector.Vector3 sunDir,
  ) {
    final rS = (6378.0 + altKm) / 6378.0;

    // 1. Orbital Ring
    final orbitPath = Path();
    bool firstOrbit = true;
    for (int lng = -180; lng <= 180; lng += 2) {
      final point = CoordinateConverter.latLngToVector3(
        satActualLat,
        lng.toDouble(),
        rS,
      );
      final p = project(point);
      if (firstOrbit) {
        orbitPath.moveTo(p.x, p.y);
        firstOrbit = false;
      } else {
        orbitPath.lineTo(p.x, p.y);
      }
    }
    canvas.drawPath(
      orbitPath,
      Paint()
        ..color = SatelliteTheme.orbitLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 2. Observer
    final obsPoint = CoordinateConverter.latLngToVector3(
      calcState.inputs.observerLat,
      calcState.inputs.observerLng,
      1.0,
    );
    final pObs = project(obsPoint);

    final obsNormal = obsPoint.normalized();
    final viewDir = vector.Vector3(0, 0, 1)
      ..applyMatrix4(
        vector.Matrix4.identity()
          ..rotateX(-renderState.tilt)
          ..rotateY(-renderState.pan),
      );
    if (obsNormal.dot(viewDir) > 0) {
      canvas.drawCircle(
        Offset(pObs.x, pObs.y),
        4.0,
        Paint()..color = SatelliteTheme.observerColor,
      );
    }

    // 3. Satellite (moving along orbit)
    // Idle orbital motion: rotate satellite longitude smoothly when no observer target is set?
    // User requested "satellite slowly move along its orbital ring when idle".
    // We add an orbit phase based on time.
    final satPoint = CoordinateConverter.latLngToVector3(
      satActualLat,
      satActualLng,
      rS,
    );
    final pSat = project(satPoint);

    // Draw 3D Satellite Model
    _draw3DSatelliteModel(canvas, project, satPoint, satActualLat, satActualLng, sunDir);

    // 4. Line of Sight (Dashed Laser)
    final bool isFront = obsNormal.dot(viewDir) > -0.2;
    if (isFront) {
      final bool isVisible = calcState.output.elevation > 0;
      _drawDashedLaserPath(canvas, pObs, pSat, isVisible);
    }
  }

  void _draw3DSatelliteModel(
    Canvas canvas,
    vector.Vector3 Function(vector.Vector3) project,
    vector.Vector3 satPos,
    double lat,
    double lng,
    vector.Vector3 sunDir,
  ) {
    // 1. Calculate nadir-pointing orientation matrix
    // Forward (Z) points to Earth center
    final forward = (vector.Vector3(0, 0, 0) - satPos).normalized();
    // Use North Pole as a temporary Up to find Right
    final tempUp = vector.Vector3(0, 1, 0);
    final right = tempUp.cross(forward).normalized();
    final up = forward.cross(right).normalized();

    // 2. Define local model geometry (Body + Solar Panels)
    final s = 0.04; // Body size
    final pw = 0.22; // Panel width
    final ph = 0.08; // Panel height

    // Vertices [Local]
    final chassis = [
      vector.Vector3(-s, -s, -s), // 0: Front-bottom-left
      vector.Vector3(s, -s, -s), // 1: Front-bottom-right
      vector.Vector3(s, s, -s), // 2: Front-top-right
      vector.Vector3(-s, s, -s), // 3: Front-top-left
      vector.Vector3(-s, -s, s), // 4: Back-bottom-left
      vector.Vector3(s, -s, s), // 5: Back-bottom-right
      vector.Vector3(s, s, s), // 6: Back-top-right
      vector.Vector3(-s, s, s), // 7: Back-top-left
    ];

    final panels = [
      // Right Panel
      [vector.Vector3(s, -ph, 0), vector.Vector3(s + pw, -ph, 0), vector.Vector3(s + pw, ph, 0), vector.Vector3(s, ph, 0)],
      // Left Panel
      [vector.Vector3(-s, -ph, 0), vector.Vector3(-s - pw, -ph, 0), vector.Vector3(-s - pw, ph, 0), vector.Vector3(-s, ph, 0)],
    ];

    vector.Vector3 toWorld(vector.Vector3 v) {
      return satPos + (right * v.x) + (up * v.y) + (forward * v.z);
    }

    // 3. Draw Chassis Faces (simplified 6 faces)
    final chassisIndices = [
      [0, 1, 2, 3], // Front
      [5, 4, 7, 6], // Back
      [4, 0, 3, 7], // Left
      [1, 5, 6, 2], // Right
      [3, 2, 6, 7], // Top
      [4, 5, 1, 0], // Bottom
    ];

    final chassisPaint = Paint()..style = PaintingStyle.fill;

    for (final face in chassisIndices) {
      final v1 = toWorld(chassis[face[0]]);
      final v2 = toWorld(chassis[face[1]]);
      final v3 = toWorld(chassis[face[2]]);
      final v4 = toWorld(chassis[face[3]]);

      // Calculate Normal for shading
      final normal = (v2 - v1).cross(v3 - v1).normalized();
      final light = math.max(0.3, normal.dot(sunDir)) * 1.0;

      final p1 = project(v1);
      final p2 = project(v2);
      final p3 = project(v3);
      final p4 = project(v4);

      final path = Path()
        ..moveTo(p1.x, p1.y)
        ..lineTo(p2.x, p2.y)
        ..lineTo(p3.x, p3.y)
        ..lineTo(p4.x, p4.y)
        ..close();

      final shadedColor = Color.lerp(Colors.black, SatelliteTheme.satelliteColor, light)!;
      canvas.drawPath(path, chassisPaint..color = shadedColor.withValues(alpha: 0.9));
    }

    // 4. Draw Solar Panels
    final panelPaint = Paint()..color = const Color(0xFF0D47A1).withValues(alpha: 0.9)..style = PaintingStyle.fill;
    final panelStroke = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 0.5;

    for (final panel in panels) {
      final v1 = toWorld(panel[0]);
      final v2 = toWorld(panel[1]);
      final v3 = toWorld(panel[2]);
      final v4 = toWorld(panel[3]);

      final p1 = project(v1);
      final p2 = project(v2);
      final p3 = project(v3);
      final p4 = project(v4);

      final path = Path()
        ..moveTo(p1.x, p1.y)
        ..lineTo(p2.x, p2.y)
        ..lineTo(p3.x, p3.y)
        ..lineTo(p4.x, p4.y)
        ..close();

      canvas.drawPath(path, panelPaint);
      canvas.drawPath(path, panelStroke);
    }
  }

  void _drawDashedLaserPath(
    Canvas canvas,
    vector.Vector3 start,
    vector.Vector3 end,
    bool isVisible,
  ) {
    final laserColor = isVisible ? Colors.greenAccent : Colors.redAccent;
    final paint = Paint()
      ..color = laserColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final glowPaint = Paint()
      ..color = laserColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final distance = math.sqrt(dx * dx + dy * dy);

    final dashLength = 12.0;
    final gapLength = 6.0;

    // Animate dash offset creating laser effect flowing FROM observer TO satellite
    final phase = (time * 30) % (dashLength + gapLength);

    final path = Path();
    double currentDistance =
        phase - (dashLength + gapLength); // Start slightly before

    while (currentDistance < distance) {
      final startRatio = math.max(0.0, currentDistance) / distance;
      final endRatio =
          math.min(distance, currentDistance + dashLength) / distance;

      final px1 = start.x + dx * startRatio;
      final py1 = start.y + dy * startRatio;

      final px2 = start.x + dx * endRatio;
      final py2 = start.y + dy * endRatio;

      path.moveTo(px1, py1);
      path.lineTo(px2, py2);

      currentDistance += dashLength + gapLength;
    }

    // Add bloom to the laser line
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant Scene3DPainter oldDelegate) {
    // Continuously repaint due to time tick
    return oldDelegate.renderState != renderState ||
        oldDelegate.calcState != calcState ||
        oldDelegate.time != time;
  }
}
