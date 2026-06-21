import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'main.dart'; // Imports your global themeProvider flag

// --- 1. LOCAL STRUCTURAL THEME SPECIFICATION ---
class WeatherUiTheme {
  final bool isDark;
  late final Color canvasBg;
  late final Color textMain;
  late final Color oppositeColor;
  late final Color ruleBorder;

  WeatherUiTheme(this.isDark) {
    canvasBg = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    textMain = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    oppositeColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    ruleBorder = isDark ? const Color(0xFF333333) : const Color(0xFFBBBBBB);
  }
}

// --- 2. SWISS BRUTALIST GEOMETRIC PRIMITIVE ICON PAINTERS ---
class BrutalistClearDayPainter extends CustomPainter {
  final Color fillColors;
  BrutalistClearDayPainter({required this.fillColors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColors
      ..style = PaintingStyle.fill;

    final double side = size.width * 0.40;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: side, height: side),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BrutalistClearNightPainter extends CustomPainter {
  final Color fillColors;
  final Color borderColors;
  BrutalistClearNightPainter({required this.fillColors, required this.borderColors});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fillColors
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = borderColors
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final double side = size.width * 0.40;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(center: center, width: side, height: side);

    canvas.drawRect(rect, strokePaint);

    // Exact half-square filled segment to code for night phase configuration
    final halfRect = Rect.fromLTWH(rect.left, rect.top, rect.width / 2, rect.height);
    canvas.drawRect(halfRect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BrutalistCloudyPainter extends CustomPainter {
  final Color color;
  BrutalistCloudyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final double rectWidth = size.width * 0.55;
    final double rectHeight = size.height * 0.30;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: rectWidth, height: rectHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BrutalistRainyPainter extends CustomPainter {
  final Color color;
  BrutalistRainyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5; // Bold slash execution logic

    final double center = size.width / 2;
    final double topY = size.height * 0.35;
    final double bottomY = size.height * 0.65;
    final double spacing = 20.0;

    // Renders exactly 3 bold separate backslashes (\ \ \) centered geometrically
    canvas.drawLine(Offset(center - spacing - 6, topY), Offset(center - spacing + 6, bottomY), paint);
    canvas.drawLine(Offset(center - 6, topY), Offset(center + 6, bottomY), paint);
    canvas.drawLine(Offset(center + spacing - 6, topY), Offset(center + spacing + 6, bottomY), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- 3. HIGH VISIBILITY GRAPH INFRASTRUCTURE ---
class BrutalistTelemetryChartPainter extends CustomPainter {
  final List<double> temperatures;
  final WeatherUiTheme theme;

  BrutalistTelemetryChartPainter({required this.temperatures, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (temperatures.isEmpty) return;

    final linePaint = Paint()
      ..color = theme.textMain
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final axisPaint = Paint()
      ..color = theme.ruleBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    double maxTemp = temperatures.reduce((a, b) => a > b ? a : b);
    double minTemp = temperatures.reduce((a, b) => a < b ? a : b);
    if (maxTemp == minTemp) {
      maxTemp += 1.0;
      minTemp -= 1.0;
    }

    final double range = maxTemp - minTemp;
    final double stepX = size.width / (temperatures.length - 1);

    // Grid baseline markers
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), axisPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), axisPaint);

    final path = Path();
    for (int i = 0; i < temperatures.length; i++) {
      final double x = i * stepX;
      final double normalizedY = (temperatures[i] - minTemp) / range;
      final double y = size.height - (normalizedY * (size.height - 32)) - 16;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Explicit numeric point annotations for instant scannability
      if (i == 0 || i == temperatures.length - 1 || i == (temperatures.length / 2).floor()) {
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 6, height: 6), Paint()..color = theme.textMain);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${temperatures[i].toStringAsFixed(0)}°',
            style: TextStyle(color: theme.textMain, fontSize: 10, fontWeight: FontWeight.w900),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        // Dynamic node positioning boundary safety calculation
        double textOffset = y - 14;
        if (textOffset < 2) textOffset = y + 6;
        textPainter.paint(canvas, Offset(x - (textPainter.width / 2), textOffset));
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant BrutalistTelemetryChartPainter oldDelegate) => true;
}

// --- 4. CORE CONTROLLER HUB ---
class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _telemetryData;

  final List<String> _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  void initState() {
    super.initState();
    _loadCacheOrFetch();
  }

  String _convertToDayName(String rawDateString) {
    try {
      final parsedDate = DateTime.parse(rawDateString);
      return _weekdays[parsedDate.weekday - 1];
    } catch (_) {
      return "DAT";
    }
  }

  Future<void> _loadCacheOrFetch() async {
    try {
      final box = await Hive.openBox('weather_cache');
      final String todayKey = DateTime.now().toIso8601String().substring(0, 10);

      final String? cachedDate = box.get('last_fetch_day');
      final String? cachedJson = box.get('payload_string');

      if (cachedDate == todayKey && cachedJson != null) {
        setState(() {
          _telemetryData = json.decode(cachedJson);
          _isLoading = false;
        });
      } else {
        _fetchTelemetryData(forced: false);
      }
    } catch (_) {
      _fetchTelemetryData(forced: false);
    }
  }

  Future<void> _fetchTelemetryData({bool forced = true}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final HttpClient client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 12);

    try {
      const String url = 'https://api.open-meteo.com/v1/forecast?'
          'latitude=19.0728&longitude=72.8826'
          '&daily=sunrise,sunset,weather_code,temperature_2m_max,temperature_2m_min'
          '&hourly=temperature_2m,relative_humidity_2m,apparent_temperature,rain,visibility,cloud_cover_low,cloud_cover_mid,cloud_cover_high,is_day,sunshine_duration,wind_direction_180m,wind_speed_180m'
          '&current=temperature_2m,relative_humidity_2m,rain,is_day,apparent_temperature'
          '&past_days=3'
          '&forecast_days=3'
          '&timezone=auto';

      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(responseBody);

        final box = await Hive.openBox('weather_cache');
        final String todayKey = DateTime.now().toIso8601String().substring(0, 10);
        await box.put('last_fetch_day', todayKey);
        await box.put('payload_string', responseBody);

        if (mounted) {
          setState(() {
            _telemetryData = data;
            _isLoading = false;
          });
        }
      } else {
        throw HttpException('HTTP METRIC ACCESS FAULT: STATUS ${response.statusCode}');
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
            // Clean, Compact Header Layout
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 1.0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      'WEATHER',
                      style: TextStyle(
                        color: theme.textMain,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _fetchTelemetryData(forced: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Minimal height specification
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: theme.ruleBorder, width: 1.0)),
                        color: theme.canvasBg,
                      ),
                      child: Text(
                        _isLoading ? '...' : 'REFRESH',
                        style: TextStyle(
                          color: theme.textMain,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
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
                  'PROCESSING TELEMETRY VECTOR DATA...',
                  style: TextStyle(color: theme.textMain, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              )
                  : _errorMessage != null
                  ? Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Text(
                  'ERROR RETRIEVING POOL LOGS: $_errorMessage',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.textMain, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              )
                  : _buildFullyScrollableWorkspace(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullyScrollableWorkspace(WeatherUiTheme theme) {
    if (_telemetryData == null) return Container();

    final current = _telemetryData!['current'] ?? {};
    final hourly = _telemetryData!['hourly'] ?? {};
    final daily = _telemetryData!['daily'] ?? {};

    final double currentTemp = (current['temperature_2m'] ?? 0.0).toDouble();
    final double apparentTemp = (current['apparent_temperature'] ?? 0.0).toDouble();
    final int humidity = (current['relative_humidity_2m'] ?? 0).toInt();
    final double currentRain = (current['rain'] ?? 0.0).toDouble();
    final int isDay = (current['is_day'] ?? 1).toInt();

    final List<dynamic> hourlyTimes = hourly['time'] ?? [];
    final String? currentHourStr = current['time'];
    int hourIdx = 0;
    if (currentHourStr != null) {
      final int idx = hourlyTimes.indexOf(currentHourStr);
      if (idx != -1) hourIdx = idx;
    }

    final double visibility = (hourly['visibility']?[hourIdx] ?? 0.0).toDouble();
    final double cloudLow = (hourly['cloud_cover_low']?[hourIdx] ?? 0.0).toDouble();
    final double cloudMid = (hourly['cloud_cover_mid']?[hourIdx] ?? 0.0).toDouble();
    final double cloudHigh = (hourly['cloud_cover_high']?[hourIdx] ?? 0.0).toDouble();
    final double sunshineDuration = (hourly['sunshine_duration']?[hourIdx] ?? 0.0).toDouble();
    final double windSpeed = (hourly['wind_speed_180m']?[hourIdx] ?? 0.0).toDouble();
    final int windDir = (hourly['wind_direction_180m']?[hourIdx] ?? 0).toInt();
    final int weatherCode = (daily['weather_code']?[0] ?? 0).toInt();

    String status = 'CLEAR';
    if (weatherCode >= 51) {
      status = 'RAINY';
    } else if (weatherCode >= 1 && weatherCode <= 3) {
      status = 'CLOUDY';
    }

    final List<double> chartTemps = [];
    final List<dynamic> rawHourlyTemps = hourly['temperature_2m'] ?? [];
    for (int i = 0; i < 24; i += 2) { // Captures clean alternating steps across 24 hours
      int target = hourIdx + i;
      if (target < rawHourlyTemps.length) {
        chartTemps.add((rawHourlyTemps[target] as num).toDouble());
      }
    }

    final String sunriseTime = (daily['sunrise']?[0] ?? "N/A").toString().split("T").last;
    final String sunsetTime = (daily['sunset']?[0] ?? "N/A").toString().split("T").last;

    final Size layoutSize = MediaQuery.of(context).size;
    final double dynamicVisualHeight = layoutSize.height * 0.33; // Exactly 1/3 viewport target layout scale

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SCROLLABLE VIEWPORT GRAPHIC LAYER - Moves up natively with swipe interactions
          Container(
            width: double.infinity,
            height: dynamicVisualHeight,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 1.0)),
              color: theme.canvasBg,
            ),
            child: _buildViewportWeatherGraphic(status, isDay, theme),
          ),

          // 2. MAIN READABLE HEADING BLOCK
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 1.0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentTemp.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    color: theme.textMain,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2.0,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$status STATE / APPARENT METRIC HOLDS AT ${apparentTemp.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    color: theme.textMain,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // 3. TABLE LAYOUT MATRIX STRUCTURE
          Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: theme.ruleBorder, width: 1.0),
              verticalInside: BorderSide(color: theme.ruleBorder, width: 1.0),
              bottom: BorderSide(color: theme.ruleBorder, width: 1.0),
            ),
            children: [
              TableRow(children: [
                _buildTableCell('HUMIDITY DATA', '$humidity%', theme),
                _buildTableCell('PRECIPITATION', '${currentRain.toStringAsFixed(1)} MM', theme),
              ]),
              TableRow(children: [
                _buildTableCell('WIND VELOCITY', '${windSpeed.toStringAsFixed(1)} KM/H', theme),
                _buildTableCell('WIND BEARING', '$windDir°', theme),
              ]),
              TableRow(children: [
                _buildTableCell('VISIBILITY SCALE', '${(visibility / 1000).toStringAsFixed(1)} KM', theme),
                _buildTableCell('SUNSHINE SPAN', '${(sunshineDuration / 60).toStringAsFixed(0)} MIN', theme),
              ]),
              TableRow(children: [
                _buildTableCell('LOW CLOUD COVER', '$cloudLow%', theme),
                _buildTableCell('MID CLOUD COVER', '$cloudMid%', theme),
              ]),
              TableRow(children: [
                _buildTableCell('HIGH CLOUD COVER', '$cloudHigh%', theme),
                _buildTableCell('DAYLIGHT BINARY', '$isDay (1=YES)', theme),
              ]),
              TableRow(children: [
                _buildTableCell('SUNRISE INDEX', sunriseTime, theme),
                _buildTableCell('SUNSET INDEX', sunsetTime, theme),
              ]),
            ],
          ),

          // 4. DATA PLOT GRAPH TIMELINE CONTAINER
          if (chartTemps.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 1.0)),
                color: theme.canvasBg,
              ),
              child: Text(
                '24-HOUR RADIAL TIMELINE VECTOR TRACKING',
                style: TextStyle(color: theme.textMain, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
            Container(
              height: 140, // Increased tracking canvas allocation size for legibility
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 1.0)),
              ),
              child: CustomPaint(
                painter: BrutalistTelemetryChartPainter(temperatures: chartTemps, theme: theme),
              ),
            ),
          ],

          // 5. LONG-RANGE SEQUENTIAL FORECAST LOGS TABLE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 1.0)),
              color: theme.canvasBg,
            ),
            child: Text(
              'FORECAST INDEX MATRIX',
              style: TextStyle(color: theme.textMain, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),

          Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: theme.ruleBorder, width: 1.0),
              bottom: BorderSide(color: theme.ruleBorder, width: 1.0),
            ),
            children: List.generate((daily['time'] as List? ?? []).length, (index) {
              final String date = daily['time'][index];
              final double max = (daily['temperature_2m_max']?[index] ?? 0.0).toDouble();
              final double min = (daily['temperature_2m_min']?[index] ?? 0.0).toDouble();
              final int code = (daily['weather_code']?[index] ?? 0).toInt();

              String dayCondition = 'CLEAR';
              if (code >= 51) {
                dayCondition = 'RAINY';
              } else if (code >= 1 && code <= 3) {
                dayCondition = 'CLOUDY';
              }

              // Conversion process transforms '2026-06-22' into localized day string: 'MON'
              final String resolvedDayName = _convertToDayName(date);

              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      resolvedDayName,
                      style: TextStyle(color: theme.textMain, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      dayCondition,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.textMain, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${max.toStringAsFixed(0)}° / ${min.toStringAsFixed(0)}°C',
                      textAlign: TextAlign.end,
                      style: TextStyle(color: theme.textMain, fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String labels, String rawValue, WeatherUiTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labels,
            style: TextStyle(color: theme.textMain, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            rawValue,
            style: TextStyle(color: theme.textMain, fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildViewportWeatherGraphic(String status, int isDay, WeatherUiTheme theme) {
    switch (status) {
      case 'CLEAR':
        if (isDay == 1) {
          return CustomPaint(
            painter: BrutalistClearDayPainter(fillColors: theme.oppositeColor),
          );
        } else {
          return CustomPaint(
            painter: BrutalistClearNightPainter(fillColors: theme.oppositeColor, borderColors: theme.textMain),
          );
        }
      case 'CLOUDY':
        return CustomPaint(
          painter: BrutalistCloudyPainter(color: theme.textMain),
        );
      case 'RAINY':
        return CustomPaint(
          painter: BrutalistRainyPainter(color: theme.textMain),
        );
      default:
        return CustomPaint(
          painter: BrutalistClearDayPainter(fillColors: theme.oppositeColor),
        );
    }
  }
}