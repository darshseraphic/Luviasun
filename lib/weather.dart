import 'dart:io';
import 'dart:convert';
import 'dart:math' as math; // ADDED: Required for geometric coordinate calculations
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main.dart'; // Imports your global themeProvider flag

// --- 1. LOCAL THEME MATRIX SPECIFICATION ---
class WeatherUiTheme {
  final bool isDark;
  late final Color canvasBg;
  late final Color textMain;
  late final Color textSub;
  late final Color ruleBorder;
  late final Color panelBg;
  final Color accentCrimson = const Color(0xFF5F0E0D);

  WeatherUiTheme(this.isDark) {
    canvasBg = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    textMain = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    textSub = isDark ? const Color(0xFF737373) : const Color(0xFF404040);
    ruleBorder = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5);
    panelBg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
  }
}

// --- 2. BRUTALIST PRIMITIVE ICON CUSTOM PAINTERS ---
class ClearIconPainter extends CustomPainter {
  final Color color;
  ClearIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 4;
    canvas.drawCircle(center, radius, paint);

    // Draw solar coordinate ray ticks
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * 3.14159 / 180;
      // FIXED: Added math. prefix to trigonometric functions
      final start = Offset(center.dx + (radius + 4) * math.cos(angle), center.dy + (radius + 4) * math.sin(angle));
      final end = Offset(center.dx + (radius + 10) * math.cos(angle), center.dy + (radius + 10) * math.sin(angle));
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CloudyIconPainter extends CustomPainter {
  final Color color;
  CloudyIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final w = size.width;
    final h = size.height;

    // Brutalist segmented cloud lines
    canvas.drawLine(Offset(w * 0.25, h * 0.65), Offset(w * 0.75, h * 0.65), paint);
    canvas.drawArc(Rect.fromLTWH(w * 0.25, h * 0.4, w * 0.25, h * 0.3), 3.14, 1.8, false, paint);
    canvas.drawArc(Rect.fromLTWH(w * 0.4, h * 0.3, w * 0.3, h * 0.35), 3.4, 2.0, false, paint);
    canvas.drawArc(Rect.fromLTWH(w * 0.6, h * 0.45, w * 0.18, h * 0.2), -1.0, 2.2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RainyIconPainter extends CustomPainter {
  final Color color;
  RainyIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final w = size.width;
    final h = size.height;

    // Draw core base cloud
    canvas.drawLine(Offset(w * 0.25, h * 0.55), Offset(w * 0.75, h * 0.55), paint);
    canvas.drawArc(Rect.fromLTWH(w * 0.25, h * 0.35, w * 0.25, h * 0.25), 3.14, 1.8, false, paint);
    canvas.drawArc(Rect.fromLTWH(w * 0.4, h * 0.25, w * 0.3, h * 0.3), 3.4, 2.0, false, paint);

    // Linear brutalist raindrops
    canvas.drawLine(Offset(w * 0.35, h * 0.65), Offset(w * 0.3, h * 0.75), paint);
    canvas.drawLine(Offset(w * 0.5, h * 0.65), Offset(w * 0.45, h * 0.75), paint);
    canvas.drawLine(Offset(w * 0.65, h * 0.65), Offset(w * 0.6, h * 0.75), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NightIconPainter extends CustomPainter {
  final Color color;
  NightIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.3, h * 0.3)
      ..quadraticBezierTo(w * 0.7, h * 0.3, w * 0.7, h * 0.7)
      ..quadraticBezierTo(w * 0.4, h * 0.8, w * 0.3, h * 0.3)
      ..moveTo(w * 0.3, h * 0.3)
      ..quadraticBezierTo(w * 0.55, h * 0.45, w * 0.7, h * 0.7);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- 3. HORIZONTAL TELEMETRY CHART PAINTER ---
class HourlyChartPainter extends CustomPainter {
  final List<double> temperatures;
  final WeatherUiTheme theme;

  HourlyChartPainter({required this.temperatures, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (temperatures.isEmpty) return;

    final linePaint = Paint()
      ..color = theme.textMain
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final gridPaint = Paint()
      ..color = theme.ruleBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    double maxTemp = temperatures.reduce((a, b) => a > b ? a : b);
    double minTemp = temperatures.reduce((a, b) => a < b ? a : b);
    if (maxTemp == minTemp) {
      maxTemp += 1.0;
      minTemp -= 1.0;
    }

    final double tempRange = maxTemp - minTemp;
    final double segmentWidth = size.width / (temperatures.length - 1);

    // Render underlying brutalist tracking horizontal baseline grid meshes
    for (int i = 0; i <= 4; i++) {
      final double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    for (int i = 0; i < temperatures.length; i++) {
      final double x = i * segmentWidth;
      final double normalizedY = (temperatures[i] - minTemp) / tempRange;
      final double y = size.height - (normalizedY * (size.height - 20)) - 10;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Render structural tick point node coordinate boundaries
      if (i % 4 == 0 || i == temperatures.length - 1) {
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 3, height: 3), Paint()..color = theme.accentCrimson);

        // Dynamic node metric text data labels (Sans-Serif Forced)
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${temperatures[i].toStringAsFixed(1)}°',
            style: TextStyle(color: theme.textMain, fontSize: 7, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(x - (textPainter.width / 2), y - 12));
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- 4. ENGINE CONTROLLER SYSTEM ---
class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _weatherData;

  @override
  void initState() {
    super.initState();
    _fetchTelemetryData();
  }

  Future<void> _fetchTelemetryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = HttpClient();
      const url = 'https://api.open-meteo.com/v1/forecast?latitude=19.0728&longitude=72.8826&daily=sunrise,sunset,weather_code,temperature_2m_max,temperature_2m_min&hourly=temperature_2m,relative_humidity_2m,apparent_temperature,rain,visibility,cloud_cover_low,cloud_cover_mid,cloud_cover_high,is_day,sunshine_duration,wind_direction_180m,wind_speed_180m&current=temperature_2m,relative_humidity_2m,rain,is_day,apparent_temperature&past_days=3&forecast_days=3';

      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        if (mounted) {
          setState(() {
            _weatherData = json.decode(responseBody);
            _isLoading = false;
          });
        }
      } else {
        throw HttpException('SYSTEM ERROR PORT CODE: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().toUpperCase();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = ref.watch(themeProvider);
    final theme = WeatherUiTheme(isDark);

    return Scaffold(
      backgroundColor: theme.canvasBg,
      body: SafeArea(
        child: Column(
          children: [
            // TOP GLOBAL TRACKBAR BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 0.8)),
                color: theme.panelBg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WEATHER TELEMETRY SYSTEM',
                        style: TextStyle(
                          color: theme.textMain,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.08,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'LOC: MUMBAI / 19.0728°N 72.8826°E',
                        style: TextStyle(
                          color: theme.textSub,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _fetchTelemetryData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.ruleBorder, width: 0.8),
                        color: theme.canvasBg,
                      ),
                      child: Text(
                        _isLoading ? 'FETCHING' : 'REFRESH',
                        style: TextStyle(
                          color: theme.textMain,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // SYSTEM METRICS CONTROLLER DISPATCHER VIEW
            Expanded(
              child: _isLoading
                  ? Center(
                child: Text(
                  'INITIALIZING DATALINK CONE...',
                  style: TextStyle(color: theme.textSub, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
                  : _errorMessage != null
                  ? Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CRITICAL DATALINK FAILURE',
                      style: TextStyle(color: theme.accentCrimson, fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.textSub, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
                  : _buildSystemTelemetryDashboard(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemTelemetryDashboard(WeatherUiTheme theme) {
    final current = _weatherData!['current'];
    final hourly = _weatherData!['hourly'];
    final daily = _weatherData!['daily'];

    // DYNAMIC CURRENT TIME MATRIX ALIGNMENT MATCHING
    final String? currentTimeStr = current['time'] as String?;
    final List<dynamic> hourlyTimes = hourly['time'] ?? [];
    int currentIndex = currentTimeStr != null ? hourlyTimes.indexOf(currentTimeStr) : -1;
    if (currentIndex == -1) currentIndex = 0;

    final double currentTemp = (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
    final double apparentTemp = (current['apparent_temperature'] as num?)?.toDouble() ?? 0.0;
    final int isDay = (current['is_day'] as num?)?.toInt() ?? 1;
    final double currentRain = (current['rain'] as num?)?.toDouble() ?? 0.0;
    final int currentHumidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 0;

    // Resolve structural current index allocations safely
    final int cloudCover = currentIndex < (hourly['cloud_cover_low'] as List).length
        ? ((hourly['cloud_cover_low'][currentIndex] as num?)?.toInt() ?? 0)
        : 0;
    final double windSpeed = currentIndex < (hourly['wind_speed_180m'] as List).length
        ? ((hourly['wind_speed_180m'][currentIndex] as num?)?.toDouble() ?? 0.0)
        : 0.0;
    final int windDir = currentIndex < (hourly['wind_direction_180m'] as List).length
        ? ((hourly['wind_direction_180m'][currentIndex] as num?)?.toInt() ?? 0)
        : 0;
    final double visibility = currentIndex < (hourly['visibility'] as List).length
        ? ((hourly['visibility'][currentIndex] as num?)?.toDouble() ?? 0.0)
        : 0.0;

    // Safe inference matching system condition structures
    String conditionSignature = 'CLEAR';
    if (currentRain > 0) {
      conditionSignature = 'RAINY';
    } else if (cloudCover > 50) {
      conditionSignature = 'CLOUDY';
    } else if (isDay == 0) {
      conditionSignature = 'NIGHT';
    }

    // Extract next 24 consecutive forecast segments from current pointer index
    final List<double> dayHourlyChartTemps = [];
    final List<dynamic> rawHourlyTemps = hourly['temperature_2m'] ?? [];
    for (int i = 0; i < 24; i++) {
      int targetIdx = currentIndex + i;
      if (targetIdx < rawHourlyTemps.length) {
        dayHourlyChartTemps.add((rawHourlyTemps[targetIdx] as num).toDouble());
      }
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CORE SIGNATURE MONITOR BOX
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 0.8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: theme.ruleBorder, width: 0.8)),
                    color: theme.panelBg,
                  ),
                  alignment: Alignment.center,
                  child: _buildPrimitiveWeatherIcon(conditionSignature, theme.textMain),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    height: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${currentTemp.toStringAsFixed(1)}°C',
                          style: TextStyle(
                            color: theme.textMain,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.05,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SURFACE STATUS // $conditionSignature',
                          style: TextStyle(
                            color: theme.accentCrimson,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.05,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ALIGNED DATASTREAM RESPONSE CODE 200',
                          style: TextStyle(color: theme.textSub, fontSize: 7, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),

          // QUAD STRUCTURE TELEMETRY GRID
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: [
              _buildMetricTile('TEMPERATURE ENVELOPE', '${currentTemp.toStringAsFixed(1)}°C', 'MAX: ${daily['temperature_2m_max'][3]}°C / MIN: ${daily['temperature_2m_min'][3]}°C', theme),
              _buildMetricTile('APPARENT PERCEPTION', '${apparentTemp.toStringAsFixed(1)}°C', 'FEELS LIKE MATRIX TEMPERATURE', theme),
              _buildMetricTile('RELATIVE ATMOSPHERE', '$currentHumidity%', 'HUMIDITY LEVEL WATER SATURATION', theme),
              _buildMetricTile('HYDROMETRIC DISCHARGE', '${currentRain.toStringAsFixed(1)} MM', 'TOTAL PRECIPITATION PRECIP QUANT', theme),
              _buildMetricTile('WIND VELOCITY FIELD', '${windSpeed.toStringAsFixed(1)} KM/H', 'BEARING DIR VECTOR: $windDir° NNE', theme),
              _buildMetricTile('OPTICAL VISIBILITY', '${(visibility / 1000).toStringAsFixed(1)} KM', 'RADAR RAY PATH GAP COMPUTE', theme),
            ],
          ),

          // HOURLY TRACK PLOT FRAME
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.ruleBorder, width: 0.8), bottom: BorderSide(color: theme.ruleBorder, width: 0.8)),
              color: theme.panelBg,
            ),
            child: Text(
              'HOURLY RUN TIMELINE MATRIX (24 HOUR PERIOD)',
              style: TextStyle(color: theme.textMain, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.05),
            ),
          ),
          Container(
            width: double.infinity,
            height: 120,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 0.8)),
            ),
            child: CustomPaint(
              painter: HourlyChartPainter(temperatures: dayHourlyChartTemps, theme: theme),
            ),
          ),

          // VERTICAL DATALIST MATRIX
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 0.8)),
              color: theme.panelBg,
            ),
            child: Text(
              '7-DAY LONG range forecast PLOTS',
              style: TextStyle(color: theme.textMain, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.05),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: (daily['time'] as List).length,
            itemBuilder: (context, index) {
              final String rawDate = daily['time'][index];
              final double maxT = (daily['temperature_2m_max'][index] as num).toDouble();
              final double minT = (daily['temperature_2m_min'][index] as num).toDouble();

              // Highlight signature tracking index markers (Today is index 3 because past_days=3)
              final bool isToday = index == 3;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 0.8)),
                  color: isToday ? theme.textMain.withOpacity(0.04) : Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          color: isToday ? theme.accentCrimson : theme.ruleBorder,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isToday ? 'TODAY // $rawDate' : 'MATRIX // $rawDate',
                          style: TextStyle(
                            color: isToday ? theme.textMain : theme.textSub,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '${maxT.toStringAsFixed(0)}°',
                          style: TextStyle(color: theme.textMain, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${minT.toStringAsFixed(0)}°',
                          style: TextStyle(color: theme.textSub, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, String description, WeatherUiTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.ruleBorder, width: 0.8),
          right: BorderSide(color: theme.ruleBorder, width: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(color: theme.textSub, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.04),
          ),
          const SizedBox(height: 3),
          Text(
            value.toUpperCase(),
            style: TextStyle(color: theme.textMain, fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            description.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.textSub, fontSize: 6.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimitiveWeatherIcon(String status, Color color) {
    switch (status) {
      case 'CLEAR':
        return SizedBox(
          width: 50,
          height: 50,
          child: CustomPaint(painter: ClearIconPainter(color: color)),
        );
      case 'CLOUDY':
        return SizedBox(
          width: 50,
          height: 50,
          child: CustomPaint(painter: CloudyIconPainter(color: color)),
        );
      case 'RAINY':
        return SizedBox(
          width: 50,
          height: 50,
          child: CustomPaint(painter: RainyIconPainter(color: color)),
        );
      case 'NIGHT':
        return SizedBox(
          width: 50,
          height: 50,
          child: CustomPaint(painter: NightIconPainter(color: color)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}