import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'main.dart'; // Imports your global themeProvider flag

// --- 1. LOCAL THEME MATRIX SPECIFICATION ---
class CompassUiTheme {
  final bool isDark;
  late final Color canvasBg;
  late final Color textMain;
  late final Color textSub;
  late final Color ruleBorder;
  late final Color panelBg;
  final Color accentCrimson = const Color(0xFF5F0E0D);

  CompassUiTheme(this.isDark) {
    canvasBg = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    textMain = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    textSub = isDark ? const Color(0xFF737373) : const Color(0xFF404040);
    ruleBorder = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5);
    panelBg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
  }
}

// --- 2. MINIMAL BRUTALIST DIAL PAINTER ---
class BrutalistCompassPainter extends CustomPainter {
  final double heading;
  final CompassUiTheme theme;

  BrutalistCompassPainter({required this.heading, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;

    final finePaint = Paint()
      ..color = theme.ruleBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final crimsonPaint = Paint()
      ..color = theme.accentCrimson
      ..style = PaintingStyle.fill;

    // Minimal outer structural framework rings
    canvas.drawCircle(center, radius, finePaint);
    canvas.drawCircle(center, radius * 0.85, finePaint);

    // Save canvas matrix state to process heading orientation
    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Convert degrees to radians and invert rotation
    final double headingRadians = -heading * (math.pi / 180);
    canvas.rotate(headingRadians);

    // TARGET INDICATOR: Minimal dot tracked far away from center
    final double indicatorOrbitDistance = radius * 0.925;
    canvas.drawCircle(
      Offset(0, -indicatorOrbitDistance),
      5.0, // Tracking dot size
      crimsonPaint,
    );

    canvas.restore();

    // Static upper indexing alignment pointer at top edge boundary
    final path = Path()
      ..moveTo(center.dx, center.dy - radius - 8)
      ..lineTo(center.dx - 4, center.dy - radius - 16)
      ..lineTo(center.dx + 4, center.dy - radius - 16)
      ..close();
    canvas.drawPath(path, Paint()..color = theme.textMain);
  }

  @override
  bool shouldRepaint(covariant BrutalistCompassPainter oldDelegate) {
    return oldDelegate.heading != heading || oldDelegate.theme != theme;
  }
}

// --- 3. ENGINE CONTROLLER LOGIC HUB ---
class CompassScreen extends ConsumerStatefulWidget {
  const CompassScreen({super.key});

  @override
  ConsumerState<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends ConsumerState<CompassScreen> {
  // Vectors for smoothing matrix filter
  List<double> _accelerometerValues = [0.0, 0.0, 0.0];
  List<double> _magnetometerValues = [0.0, 0.0, 0.0];

  bool _hasAccelerometerData = false;
  bool _hasMagnetometerData = false;

  double _heading = 0.0;
  String _hardwareStatus = "INITIALIZING CORE DATA SYNCHRONIZATION...";

  // Smoothing factor alpha (Lower values = smoother but slightly slower response, 0.15 is ideal)
  final double _alpha = 0.15;

  @override
  void initState() {
    super.initState();
    _initHybridSensorSystem();
  }

  Future<void> _initHybridSensorSystem() async {
    // 1. Verify and establish runtime location services
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 2. Continuous Hardware Streams Setup
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          // Apply low-pass exponential filter to raw accelerometer array
          _accelerometerValues[0] = _accelerometerValues[0] + _alpha * (event.x - _accelerometerValues[0]);
          _accelerometerValues[1] = _accelerometerValues[1] + _alpha * (event.y - _accelerometerValues[1]);
          _accelerometerValues[2] = _accelerometerValues[2] + _alpha * (event.z - _accelerometerValues[2]);
          _hasAccelerometerData = true;
          _calculateVectorHeading();
        });
      }
    });

    magnetometerEvents.listen((MagnetometerEvent event) {
      if (mounted) {
        setState(() {
          // Apply low-pass exponential filter to raw magnetometer array
          _magnetometerValues[0] = _magnetometerValues[0] + _alpha * (event.x - _magnetometerValues[0]);
          _magnetometerValues[1] = _magnetometerValues[1] + _alpha * (event.y - _magnetometerValues[1]);
          _magnetometerValues[2] = _magnetometerValues[2] + _alpha * (event.z - _magnetometerValues[2]);
          _hasMagnetometerData = true;
          _calculateVectorHeading();
        });
      }
    });
  }

  void _calculateVectorHeading() {
    if (!_hasAccelerometerData || !_hasMagnetometerData) {
      _hardwareStatus = "AWAITING SENSOR CALIBRATION MATRIX...";
      return;
    }

    // Mathematical calculations using smoothed values
    final double ax = _accelerometerValues[0];
    final double ay = _accelerometerValues[1];
    final double az = _accelerometerValues[2];

    final double mx = _magnetometerValues[0];
    final double my = _magnetometerValues[1];
    final double mz = _magnetometerValues[2];

    // Compute coordinate fields across planar projections
    double hx = mx * az - mz * ax;
    double hy = my * az - mz * ay;

    double azimuth = math.atan2(hy, hx) * (180 / math.pi);

    // Normalize into complete 360 degree space
    azimuth = (azimuth + 360) % 360;

    // Apply a final layer of smoothing directly to the heading variable to stop small text jitters
    if ((azimuth - _heading).abs() < 180) {
      _heading = _heading + _alpha * (azimuth - _heading);
    } else {
      // Handle degree overflow boundary wrapping smoothly
      if (azimuth > _heading) {
        _heading = _heading + _alpha * (azimuth - 360 - _heading);
        _heading = (_heading + 360) % 360;
      } else {
        _heading = _heading + _alpha * (azimuth + 360 - _heading);
        _heading = _heading % 360;
      }
    }

    _hardwareStatus = "LIVE HARDWARE TELEMETRY LINKED";
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = ref.watch(themeProvider);
    final theme = CompassUiTheme(isDark);

    return Scaffold(
      backgroundColor: theme.canvasBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 0.8)),
                color: theme.panelBg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COMPASS TELEMETRY SYSTEM',
                    style: TextStyle(
                      color: theme.textMain,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.08,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _hardwareStatus.toUpperCase(),
                    style: TextStyle(
                      color: theme.textSub,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(24),
                  child: CustomPaint(
                    painter: BrutalistCompassPainter(heading: _heading, theme: theme),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}