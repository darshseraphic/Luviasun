import 'dart:io';
import 'dart:convert';
import 'dart:math' as math; // Required for geometric coordinate calculations
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

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * 3.14159 / 180;
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

    canvas.drawLine(Offset(w * 0.25, h * 0.55), Offset(w * 0.75, h * 0.55), paint);
    canvas.drawArc(Rect.fromLTWH(w * 0.25, h * 0.35, w * 0.25, h * 0.25), 3.14, 1.8, false, paint);
    canvas.drawArc(Rect.fromLTWH(w * 0.4, h * 0.25, w * 0.3, h * 0.3), 3.4, 2.0, false, paint);

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

      if (i % 4 == 0 || i == temperatures.length - 1) {
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 3, height: 3), Paint()..color = theme.accentCrimson);

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

// --- 4. ENGINE CONTROLLER LOGIC HUB ---
class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _telemetryData;

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

    final HttpClient client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      const String url = 'https://api.open-meteo.com/v1/forecast?'
          'latitude=19.0728&longitude=72.8826'
          '&current=temperature_2m,relative_humidity_2m,is_day,weather_code,wind_speed_10m,wind_direction_10m'
          '&hourly=temperature_2m'
          '&daily=temperature_2m_max,temperature_2m_min,weather_code'
          '&past_days=3'
          '&forecast_days=3'
          '&timezone=auto';

      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(responseBody);

        if (mounted) {
          setState(() {
            _telemetryData = data;
            _isLoading = false;
          });
        }
      } else {
        throw HttpException('SERVER REJECTED DATALINK TERMINAL WITH STATUS: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().toUpperCase();
          _isLoading = false;
        });
      }
    } finally {
      client.close();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 0.8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'METEOROLOGICAL TELEMETRY SYSTEM',
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
    if (_telemetryData == null) return Container();

    final current = _telemetryData!['current'] ?? {};
    final hourly = _telemetryData!['hourly'] ?? {};
    final daily = _telemetryData!['daily'] ?? {};

    final double currentTemp = (current['temperature_2m'] ?? 0.0).toDouble();
    final int humidity = (current['relative_humidity_2m'] ?? 0).toInt();
    final double windSpeed = (current['wind_speed_10m'] ?? 0.0).toDouble();
    final int windDir = (current['wind_direction_10m'] ?? 0).toInt();
    final int weatherCode = (current['weather_code'] ?? 0).toInt();
    final int isDay = (current['is_day'] ?? 1).toInt();

    String conditionSignature = 'CLEAR';
    if (weatherCode >= 51) {
      conditionSignature = 'RAINY';
    } else if (weatherCode >= 1 && weatherCode <= 3) {
      conditionSignature = 'CLOUDY';
    } else if (isDay == 0) {
      conditionSignature = 'NIGHT';
    }

    final List<dynamic> rawHourlyTimes = hourly['time'] ?? [];
    final String? currentHourStr = current['time'];
    int currentIndex = 0;
    if (currentHourStr != null) {
      final int idx = rawHourlyTimes.indexOf(currentHourStr);
      if (idx != -1) currentIndex = idx;
    }

    final List<double> dayHourlyChartTemps = [];
    final List<dynamic> rawHourlyTemps = hourly['temperature_2m'] ?? [];
    for (int i = 0; i < 24; i++) {
      int targetIdx = currentIndex + i;
      if (targetIdx < rawHourlyTemps.length) {
        dayHourlyChartTemps.add((rawHourlyTemps[targetIdx] as num).toDouble());
      }
    }

    final List<dynamic> dailyTimes = daily['time'] ?? [];
    int targetedIndexOffset = dailyTimes.length > 3 ? 3 : (dailyTimes.length - 1);
    if (targetedIndexOffset < 0) targetedIndexOffset = 0;

    String maxDayTemp = "N/A";
    String minDayTemp = "N/A";
    if (daily['temperature_2m_max'] != null && daily['temperature_2m_max'].length > targetedIndexOffset) {
      maxDayTemp = daily['temperature_2m_max'][targetedIndexOffset].toString();
    }
    if (daily['temperature_2m_min'] != null && daily['temperature_2m_min'].length > targetedIndexOffset) {
      minDayTemp = daily['temperature_2m_min'][targetedIndexOffset].toString();
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                          conditionSignature,
                          style: TextStyle(
                            color: theme.textMain,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.05,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'MAX: $maxDayTemp°C / MIN: $minDayTemp°C',
                          style: TextStyle(color: theme.textSub, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            children: [
              _buildMetricTile('AIR MOISTURE', '$humidity%', 'RELATIVE HYGROMETER INDEX', theme),
              _buildMetricTile('VECTOR SPEED', '${windSpeed.toStringAsFixed(1)} KM/H', 'SURFACE WIND MAGNITUDE', theme),
              _buildMetricTile('VECTOR HEADING', '$windDir°', 'BAROMETRIC COMPASS AZIMUTH', theme),
              _buildMetricTile('SYNOPTIC CORE', 'WMO $weatherCode', 'SYNOPTIC CODE SPECS SIGNATURE', theme),
            ],
          ),
          if (dayHourlyChartTemps.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.ruleBorder, width: 0.8),
                  bottom: BorderSide(color: theme.ruleBorder, width: 0.8),
                ),
                color: theme.panelBg,
              ),
              child: Text(
                '24-HOUR RADIAL TEMPERATURE TIMELINE MONITOR',
                style: TextStyle(color: theme.textMain, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.05),
              ),
            ),
            Container(
              height: 120,
              width: double.infinity,
              padding: const EdgeInsets.only(top: 24, bottom: 12, left: 16, right: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 0.8)),
              ),
              child: CustomPaint(
                painter: HourlyChartPainter(temperatures: dayHourlyChartTemps, theme: theme),
              ),
            ),
          ],
          // FIXED PARAMETER HERE (Line 549 Error Resolution): Wrapped inside proper Box Border object
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 0.8)),
              color: theme.panelBg,
            ),
            child: Text(
              '7-DAY LONG RANGE FORECAST PLOTS',
              style: TextStyle(color: theme.textMain, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.05),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dailyTimes.length,
            itemBuilder: (context, index) {
              final String rawDate = dailyTimes[index];
              final double maxT = (daily['temperature_2m_max']?[index] as num? ?? 0.0).toDouble();
              final double minT = (daily['temperature_2m_min']?[index] as num? ?? 0.0).toDouble();
              final int code = (daily['weather_code']?[index] as num? ?? 0).toInt();

              String dayCondition = 'CLEAR';
              if (code >= 51) {
                dayCondition = 'RAINY';
              } else if (code >= 1 && code <= 3) {
                dayCondition = 'CLOUDY';
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 0.8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      rawDate.toUpperCase(),
                      style: TextStyle(color: theme.textMain, fontSize: 9, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                    ),
                    Text(
                      dayCondition,
                      style: TextStyle(color: theme.textSub, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${maxT.toStringAsFixed(0)}° / ${minT.toStringAsFixed(0)}°C',
                      style: TextStyle(color: theme.textMain, fontSize: 9, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                    ),
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
          finalTextElement(label, theme.textSub, 8, FontWeight.bold, letterSpacing: 0.04),
          const SizedBox(height: 3),
          finalTextElement(value.toUpperCase(), theme.textMain, 13, FontWeight.w900),
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

  Widget finalTextElement(String data, Color color, double size, FontWeight weight, {double? letterSpacing}) {
    return Text(
      data,
      style: TextStyle(color: color, fontSize: size, fontWeight: weight, letterSpacing: letterSpacing),
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
        return Container();
    }
  }
}