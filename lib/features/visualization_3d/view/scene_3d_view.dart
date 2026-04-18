import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import '../../../core/math/coordinate_converter.dart';
import '../../../core/math/earth_data.dart';
import '../../../core/math/footprint_calculator.dart';
import '../../../core/utils/theme.dart';
import '../../calculator/logic/calculator_cubit.dart';
import '../../calculator/logic/calculator_state.dart';
import '../logic/render_cubit.dart';
import '../logic/render_state.dart';

class Scene3DView extends StatefulWidget {
  const Scene3DView({super.key});

  @override
  State<Scene3DView> createState() => _Scene3DViewState();
}

class _Scene3DViewState extends State<Scene3DView> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  double _time = 0.0;
  
  // Interpolation targets for easing
  double _currentPan = 0.0;
  double _currentTilt = 0.2;
  double _currentZoom = 1.0;
  
  // Interaction state
  DateTime _lastInteraction = DateTime.now();
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
       vsync: this,
       duration: const Duration(days: 365),
    )..addListener(() {
        setState(() {
          _time += 0.016; // Approx 60fps tick
          
          if (!_isInteracting) {
            final idleTime = DateTime.now().difference(_lastInteraction).inSeconds;
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
            
            // Easing interpolation
            _currentPan += (renderState.pan - _currentPan) * 0.1;
            _currentTilt += (renderState.tilt - _currentTilt) * 0.1;
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
                  // Zooming
                  context.read<RenderCubit>().updateZoom(details.scale);
                }
              },
              onScaleEnd: (_) {
                _isInteracting = false;
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: Scene3DPainter(
                  renderState: RenderState(pan: _currentPan, tilt: _currentTilt, zoom: _currentZoom),
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

    // View matrix setup
    final viewMatrix = vector.Matrix4.identity()
      ..translate(vector.Vector3(center.dx, center.dy, 0.0))
      ..scale(vector.Vector3(radius, radius, radius))
      ..rotateX(renderState.tilt)
      ..rotateY(renderState.pan);

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

    // 3. Earth Base Sphere (Solid black to hide back-facing lines)
    final earthBasePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, earthBasePaint);

    // 4. Directional Light (Sun shading/Terminator)
    final sunDir = vector.Vector3(1, 0.5, 0.2).normalized(); // Fixed sun direction
    final sunPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(sunDir.x, -sunDir.y),
        radius: 1.2,
        colors: [
          Colors.white.withValues(alpha: 0.15), // Specular highlight
          Colors.transparent,
          Colors.black87, // Terminator / Dark side
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..blendMode = BlendMode.srcOver;

    // 5. Wireframe/Grids (Holographic tech overlay)
    _drawEarthGrid(canvas, project, sunDir);
    
    // Apply shading over the grid
    canvas.drawCircle(center, radius, sunPaint);

    // 6. Draw the Satellite's Footprint
    final satActualLng = calcState.inputs.satelliteLng;
    final satActualLat = calcState.inputs.satelliteLat;
    final satAlt = calcState.inputs.satelliteAltitudeKm;

    if (calcState.inputs.satelliteAltitudeKm > 0.0) {
      _drawFootprint(canvas, project, center, radius, sunDir, satActualLat, satActualLng, satAlt);
    }

    // 7. Draw Orbital Ring and Satellite Markers
    _drawOrbitAndMarkers(canvas, project, satActualLat, satActualLng, satAlt);
  }

  void _drawStarfield(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = SatelliteTheme.backgroundSpace);
    final random = math.Random(42); // Fixed seed for persistence
    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < 200; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        // Pseudo-parallax using pan and tilt
        final px = (x + renderState.pan * 20 * random.nextDouble()) % size.width;
        final py = (y + renderState.tilt * 20 * random.nextDouble()) % size.height;
        paint.color = Colors.white.withValues(alpha: 0.2 + random.nextDouble() * 0.8);
        canvas.drawCircle(Offset(px, py), random.nextDouble() * 1.5, paint);
    }
  }

  void _drawEarthGrid(Canvas canvas, vector.Vector3 Function(vector.Vector3) project, vector.Vector3 sunDir) {
    // 1. Draw solid dark background for Earth to prevent see-through to stars
    final earthBgPaint = Paint()..color = const Color(0xFF030A14);
    final earthCenter = project(vector.Vector3(0, 0, 0));
    final earthRadius = project(vector.Vector3(1, 0, 0)).distanceTo(earthCenter);
    canvas.drawCircle(Offset(earthCenter.x, earthCenter.y), earthRadius, earthBgPaint);

    final landPaint = Paint()
      ..color = SatelliteTheme.earthLines.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // 2. Draw Topographical Realistic Continents
    for (final poly in EarthData.continents) {
      final path = Path();
      bool first = true;
      
      for (final pt in poly) {
        final lng = pt[0];
        final lat = pt[1];
        
        final point = CoordinateConverter.latLngToVector3(lat, lng, 1.0);
        final normal = point.normalized();
        final viewDir = vector.Vector3(0,0,1)
          ..applyMatrix4(vector.Matrix4.identity()..rotateX(-renderState.tilt)..rotateY(-renderState.pan));
          
        if (normal.dot(viewDir) > 0.0) { // Visible on front face
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
      canvas.drawPath(path, landPaint);
    }
    
    // Draw explicit dashed equator to anchor spatial awareness
    final equatorPaint = Paint()
      ..color = SatelliteTheme.earthLines.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final equatorPath = Path();
    bool eqFirst = true;
    for (int lon = -180; lon <= 180; lon += 5) {
      final point = CoordinateConverter.latLngToVector3(0.0, lon.toDouble(), 1.0);
      final normal = point.normalized();
      final viewDir = vector.Vector3(0,0,1)..applyMatrix4(vector.Matrix4.identity()..rotateX(-renderState.tilt)..rotateY(-renderState.pan));
      
      if (normal.dot(viewDir) > 0) { 
        final p = project(point);
        if (eqFirst) { equatorPath.moveTo(p.x, p.y); eqFirst = false; }
        else { equatorPath.lineTo(p.x, p.y); }
      } else {
        eqFirst = true;
      }
    }
    canvas.drawPath(equatorPath, equatorPaint);
  }

  void _drawFootprint(Canvas canvas, vector.Vector3 Function(vector.Vector3) project, Offset center, double radius, vector.Vector3 sunDir, double satLat, double satLng, double altKm) {
    final footprintRadiusAngle = FootprintCalculator.calculateFootprintCentralAngleRad(0.0, altKm);

    final path = Path();
    bool first = true;

    // Pulsing effect
    final pulse = 0.3 + 0.2 * math.sin(time * 3);

    for (int angle = 0; angle <= 360; angle += 5) {
      final latRad = footprintRadiusAngle * math.cos(angle * math.pi / 180) + (satLat * math.pi / 180);
      final lngRad = footprintRadiusAngle * math.sin(angle * math.pi / 180) + (satLng * math.pi / 180);
      
      final lat = latRad * 180 / math.pi;
      final lng = lngRad * 180 / math.pi;

      final point = CoordinateConverter.latLngToVector3(lat, lng, 1.01);
      final p = project(point);

      final normal = point.normalized();
      final viewDir = vector.Vector3(0,0,1)
        ..applyMatrix4(vector.Matrix4.identity()..rotateX(-renderState.tilt)..rotateY(-renderState.pan));

      if (normal.dot(viewDir) > 0) {
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

    path.close();

    final fillPaint = Paint()
      ..color = SatelliteTheme.footprintFill.withValues(alpha: pulse)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = SatelliteTheme.footprintEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawOrbitAndMarkers(Canvas canvas, vector.Vector3 Function(vector.Vector3) project, double satActualLat, double satActualLng, double altKm) {
    final rS = (6371.0 + altKm) / 6371.0; 
    
    // 1. Orbital Ring
    final orbitPath = Path();
    bool firstOrbit = true;
    for (int lng = -180; lng <= 180; lng += 2) {
      final point = CoordinateConverter.latLngToVector3(0.0, lng.toDouble(), rS);
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
        ..strokeWidth = 1.0
    );

    // 2. Observer
    final obsPoint = CoordinateConverter.latLngToVector3(
      calcState.inputs.observerLat, 
      calcState.inputs.observerLng, 
      1.0
    );
    final pObs = project(obsPoint);
    
    final obsNormal = obsPoint.normalized();
    final viewDir = vector.Vector3(0,0,1)..applyMatrix4(vector.Matrix4.identity()..rotateX(-renderState.tilt)..rotateY(-renderState.pan));
    if (obsNormal.dot(viewDir) > 0) {
      canvas.drawCircle(Offset(pObs.x, pObs.y), 4.0, Paint()..color = SatelliteTheme.observerColor);
    }

    // 3. Satellite (moving along orbit)
    // Idle orbital motion: rotate satellite longitude smoothly when no observer target is set?
    // User requested "satellite slowly move along its orbital ring when idle".
    // We add an orbit phase based on time.
    final satPoint = CoordinateConverter.latLngToVector3(
      satActualLat, 
      satActualLng, 
      rS
    );
    final pSat = project(satPoint);
    
    // Draw Satellite Bloom Marker
    final bloomPaint = Paint()
      ..shader = RadialGradient(
        colors: [SatelliteTheme.satelliteColor, SatelliteTheme.satelliteColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(pSat.x, pSat.y), radius: 15))
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(Offset(pSat.x, pSat.y), 15.0, bloomPaint);
    canvas.drawCircle(Offset(pSat.x, pSat.y), 3.0, Paint()..color = Colors.white); // Core

    // 4. Line of Sight (Dashed Laser)
    final bool isFront = obsNormal.dot(viewDir) > -0.2;
    if (isFront) {
      _drawDashedLaserPath(canvas, pObs, pSat, calcState.signalAcquired);
    }
  }

  void _drawDashedLaserPath(Canvas canvas, vector.Vector3 start, vector.Vector3 end, bool signalAcquired) {
    final laserColor = signalAcquired ? Colors.greenAccent : Colors.redAccent;
    final paint = Paint()
      ..color = laserColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Glowing blur effect for laser feel
    final glowPaint = Paint()
      ..color = laserColor.withValues(alpha: 0.5)
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
    double currentDistance = phase - (dashLength + gapLength); // Start slightly before
    
    while (currentDistance < distance) {
      final startRatio = math.max(0.0, currentDistance) / distance;
      final endRatio = math.min(distance, currentDistance + dashLength) / distance;
      
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
