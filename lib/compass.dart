import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// --- 2. HIGH-FIDELITY BRUTALIST DIAL PAINTER ---
class BrutalistCompassPainter extends CustomPainter {
  final double heading;
  final CompassUiTheme theme;

  BrutalistCompassPainter({required this.heading, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.4;

    final finePaint = Paint()
      ..color = theme.ruleBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final mainPaint = Paint()
      ..color = theme.textMain
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final crimsonPaint = Paint()
      ..color = theme.accentCrimson
      ..style = PaintingStyle.fill;

    // Draw structural radar grid lines (Static crosshairs)
    canvas.drawLine(Offset(center.dx - radius - 20, center.dy), Offset(center.dx + radius + 20, center.dy), finePaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius - 20), Offset(center.dx, center.dy + radius + 20), finePaint);
    canvas.drawCircle(center, radius, finePaint);
    canvas.drawCircle(center, radius * 0.6, finePaint);

    // Save canvas to perform heading rotation operations
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Convert degrees to radians and invert rotation to match real world alignment
    final double headingRadians = -heading * (math.pi / 180);
    canvas.rotate(headingRadians);

    // Draw cardinal direction indicator blocks & tick arrays
    final List<String> cardinals = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 24; i++) {
      final double angle = (i * 15) * (math.pi / 180);
      final isCardinal = i % 6 == 0;
      final double startLen = radius;
      final double endLen = isCardinal ? radius - 12 : radius - 6;

      canvas.drawLine(
        Offset(startLen * math.cos(angle), startLen * math.sin(angle)),
        Offset(endLen * math.cos(angle), endLen * math.sin(angle)),
        isCardinal ? mainPaint : finePaint,
      );

      if (isCardinal) {
        final String text = cardinals[i ~/ 6];
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: text == 'N' ? theme.accentCrimson : theme.textMain,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final double textRadius = radius - 24;
        final double textAngle = angle - (math.pi / 2);

        canvas.save();
        canvas.translate(textRadius * math.cos(angle), textRadius * math.sin(angle));
        canvas.rotate(angle + (math.pi / 2));
        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        canvas.restore();
      }
    }

    final Offset nodeOffset = Offset(0, -radius);
    canvas.drawRect(
      Rect.fromCenter(center: nodeOffset, width: 8, height: 8),
      crimsonPaint,
    );

    canvas.restore();

    final path = Path()
      ..moveTo(center.dx, center.dy - radius - 15)
      ..lineTo(center.dx - 5, center.dy - radius - 25)
      ..lineTo(center.dx + 5, center.dy - radius - 25)
      ..close();
    canvas.drawPath(path, Paint()..color = theme.textMain);
  }

  @override
  bool shouldRepaint(covariant BrutalistCompassPainter oldDelegate) {
    return oldDelegate.heading != heading || oldDelegate.theme != theme;
  }
}

// --- 3. ENGINE CONTROLLER SYSTEM ---
class CompassScreen extends ConsumerWidget {
  const CompassScreen({super.key});

  String _getHeadingDirection(double heading) {
    final double norm = (heading % 360 + 360) % 360;
    if (norm >= 337.5 || norm < 22.5) return 'NORTH // ALPHA SEC';
    if (norm >= 22.5 && norm < 67.5) return 'NORTH-EAST // QUAD BRV';
    if (norm >= 67.5 && norm < 112.5) return 'EAST // CHARLIE SEC';
    if (norm >= 112.5 && norm < 157.5) return 'SOUTH-EAST // QUAD DELTA';
    if (norm >= 157.5 && norm < 202.5) return 'SOUTH // ECHO SEC';
    if (norm >= 202.5 && norm < 247.5) return 'SOUTH-WEST // QUAD FOXTROT';
    if (norm >= 247.5 && norm < 292.5) return 'WEST // GOLF SEC';
    return 'NORTH-WEST // QUAD HOTEL';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = ref.watch(themeProvider);
    final theme = CompassUiTheme(isDark);

    // SIMULATED HARDWARE STREAM (Guarantees compilation without flutter_compass package)
    final Stream<double> simulatedHeadingStream = Stream.periodic(
      const Duration(milliseconds: 50),
          (count) => (count * 1.5) % 360,
    ).asBroadcastStream();

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
                    'STREAMING SIMULATED HARWARE COORDINATE DATA LINK',
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
              child: StreamBuilder<double>(
                stream: simulatedHeadingStream, // <--- Swap this to FlutterCompass.events later
                initialData: 0.0,
                builder: (context, snapshot) {
                  final double heading = snapshot.data ?? 0.0;

                  return Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.all(24),
                            child: CustomPaint(
                              painter: BrutalistCompassPainter(heading: heading, theme: theme),
                            ),
                          ),
                        ),
                      ),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.8,
                        children: [
                          _buildTelemetryTile('ABSOLUTE HEADING', '${heading.toStringAsFixed(1)}°', 'AZIMUTH LOG MATRIX RAD', theme),
                          _buildTelemetryTile('BEARING VECTOR', _getHeadingDirection(heading), 'COMPASS SYSTEM TRACKING POSITION', theme),
                          _buildTelemetryTile('ACCURACY THRESHOLD', 'SIMULATED', 'HARDWARE DATALINK BYPASSED', theme),
                          _buildTelemetryTile('AXIS STATUS', 'HEADING RESOLVED', 'SYSTEM STREAM ATTITUDE LOCK', theme),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryTile(String label, String value, String description, CompassUiTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.ruleBorder, width: 0.8),
          right: BorderSide(color: theme.ruleBorder, width: 0.8),
        ),
        color: theme.panelBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(color: theme.textSub, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.04),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.textMain, fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.textSub, fontSize: 6.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}