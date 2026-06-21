import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'main.dart';

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
      ..strokeWidth = 12.0;

    final double center = size.width / 2;
    final double topY = size.height * 0.35;
    final double bottomY = size.height * 0.65;
    final double spacing = 32.0;

    canvas.drawLine(Offset(center - spacing - 36, topY), Offset(center - spacing + 36, bottomY), paint);
    canvas.drawLine(Offset(center - 36, topY), Offset(center + 36, bottomY), paint);
    canvas.drawLine(Offset(center + spacing - 36, topY), Offset(center + spacing + 36, bottomY), paint);
  }

  @override
  bool shouldRepaint(covariant BrutalistRainyPainter oldDelegate) => false;
}

class BrutalistTelemetryChartPainter extends CustomPainter {
  final List<double> temperatures;
  final List<String> dayLabels;
  final WeatherUiTheme theme;

  BrutalistTelemetryChartPainter({required this.temperatures, required this.dayLabels, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (temperatures.isEmpty) return;

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
    final double paddingLeft = 24.0;
    final double paddingRight = 24.0;
    final double paddingBottom = 32.0;
    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingBottom;

    final double stepX = temperatures.length > 1 ? chartWidth / (temperatures.length - 1) : chartWidth;

    canvas.drawLine(Offset(paddingLeft, chartHeight), Offset(size.width - paddingRight, chartHeight), axisPaint);

    for (int i = 0; i < temperatures.length; i++) {
      final double x = paddingLeft + (i * stepX);
      final double normalizedY = range > 0 ? (temperatures[i] - minTemp) / range : 0.5;

      final double barHeight = 20 + (normalizedY * (chartHeight - 60));
      final double y = chartHeight - barHeight;

      final barPaint = Paint()
        ..color = theme.textMain
        ..style = PaintingStyle.fill;

      final double barWidth = 24.0;
      final rect = Rect.fromLTRB(x - barWidth / 2, y, x + barWidth / 2, chartHeight);
      canvas.drawRect(rect, barPaint);

      final nodeText = TextPainter(
        text: TextSpan(
          text: '${temperatures[i].toStringAsFixed(0)}°',
          style: TextStyle(color: theme.textMain, fontSize: 10, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      nodeText.paint(canvas, Offset(x - (nodeText.width / 2), y - 16));

      if (i < dayLabels.length) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: dayLabels[i],
            style: TextStyle(color: theme.textMain, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        labelPainter.paint(canvas, Offset(x - (labelPainter.width / 2), chartHeight + 8));
      }
    }
  }

  @override
  bool shouldRepaint(covariant BrutalistTelemetryChartPainter oldDelegate) => true;
}

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  bool _isLoading = true;
  bool _isBackgroundRefreshing = false;
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

  // --- LIFECYCLE MANAGEMENT LAYER ---
  Future<void> _loadCacheOrFetch() async {
    try {
      final box = await Hive.openBox('weather_cache');
      final String todayKey = DateTime.now().toIso8601String().substring(0, 10);

      final String? cachedDate = box.get('last_fetch_day');
      final String? cachedJson = box.get('payload_string');

      if (cachedDate == todayKey && cachedJson != null) {
        // Cache exists (either old or freshly grabbed by main.dart pre-fetch loop)
        if (mounted) {
          setState(() {
            _telemetryData = json.decode(cachedJson);
            _isLoading = false;
          });
        }
      } else {
        // Fallback option: if background pre-fetch hasn't updated yet, execute direct API lookup here.
        await _fetchTelemetryData(forced: false);
      }
    } catch (_) {
      _fetchTelemetryData(forced: false);
    }
  }

  // --- CENTRAL DISPATCHER ENGINE ---
  Future<void> _fetchTelemetryData({bool forced = true}) async {
    if (_telemetryData != null) {
      setState(() {
        _isBackgroundRefreshing = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

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

        // Lock in persistent storage parameters immediately upon successful network return
        final box = await Hive.openBox('weather_cache');
        final String todayKey = DateTime.now().toIso8601String().substring(0, 10);
        await box.put('last_fetch_day', todayKey);
        await box.put('payload_string', responseBody);

        if (mounted) {
          setState(() {
            _telemetryData = data;
            _isLoading = false;
            _isBackgroundRefreshing = false;
          });
        }
      } else {
        throw HttpException('ERROR STATUS: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().toUpperCase();
          _isLoading = false;
          _isBackgroundRefreshing = false;
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
              height: 48,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  GestureDetector(
                    // FORCED PARAMETER BYPASSES MIDNIGHT TIMESTAMPS FOR MANUALLY TRIGGERED REFRESHES
                    onTap: () => _fetchTelemetryData(forced: true),
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      child: Text(
                        (_isLoading || _isBackgroundRefreshing) ? '...' : 'REFRESH',
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
                  ? Container(
                // Pure dark container matching background signature to completely hide millisecond cache parsing re-renders
                color: theme.canvasBg,
                child: const Center(
                  child: Text(
                    '',
                    style: TextStyle(fontSize: 0),
                  ),
                ),
              )
                  : _errorMessage != null
                  ? Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Text(
                  'FAULT DETECTED: $_errorMessage',
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

    final List<double> dailyChartTemps = [];
    final List<String> dailyChartDays = [];
    final List<dynamic> dailyTimes = daily['time'] ?? [];
    final List<dynamic> dailyMaxTemps = daily['temperature_2m_max'] ?? [];

    for (int i = 0; i < dailyTimes.length; i++) {
      if (i < dailyMaxTemps.length) {
        dailyChartTemps.add((dailyMaxTemps[i] as num).toDouble());
        dailyChartDays.add(_convertToDayName(dailyTimes[i].toString()));
      }
    }

    final String sunriseTime = (daily['sunrise']?[0] ?? "N/A").toString().split("T").last;
    final String sunsetTime = (daily['sunset']?[0] ?? "N/A").toString().split("T").last;

    final Size layoutSize = MediaQuery.of(context).size;
    final double dynamicVisualHeight = layoutSize.height * 0.33;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: dynamicVisualHeight,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 1.0)),
              color: theme.canvasBg,
            ),
            child: _buildViewportWeatherGraphic(status, isDay, theme),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 1.0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${currentTemp.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    color: theme.textMain,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$status / APPARENT UNIFIED SCALE ${apparentTemp.toStringAsFixed(1)}°C',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textMain,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: theme.ruleBorder, width: 1.0),
                verticalInside: BorderSide(color: theme.ruleBorder, width: 1.0),
                top: BorderSide(color: theme.ruleBorder, width: 1.0),
                left: BorderSide(color: theme.ruleBorder, width: 1.0),
                right: BorderSide(color: theme.ruleBorder, width: 1.0),
                bottom: BorderSide(color: theme.ruleBorder, width: 1.0),
              ),
              children: [
                _buildStructuralRow('HUMIDITY DATA', '$humidity%', theme),
                _buildStructuralRow('PRECIPITATION', '${currentRain.toStringAsFixed(1)} MM', theme),
                _buildStructuralRow('WIND VELOCITY', '${windSpeed.toStringAsFixed(1)} KM/H', theme),
                _buildStructuralRow('WIND BEARING', '$windDir°', theme),
                _buildStructuralRow('VISIBILITY SCALE', '${(visibility / 1000).toStringAsFixed(1)} KM', theme),
                _buildStructuralRow('SUNSHINE INDEX', '${(sunshineDuration / 60).toStringAsFixed(0)} MIN', theme),
                _buildStructuralRow('LOW CLOUD LAYER', '$cloudLow%', theme),
                _buildStructuralRow('MID CLOUD LAYER', '$cloudMid%', theme),
                _buildStructuralRow('HIGH CLOUD LAYER', '$cloudHigh%', theme),
                _buildStructuralRow('DAYLIGHT BINARY', '$isDay', theme),
                _buildStructuralRow('SUNRISE INDEX', sunriseTime, theme),
                _buildStructuralRow('SUNSET INDEX', sunsetTime, theme),
              ],
            ),
          ),

          if (dailyChartTemps.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.ruleBorder, width: 1.0),
                  bottom: BorderSide(color: theme.ruleBorder, width: 1.0),
                ),
                color: theme.canvasBg,
              ),
              child: Center(
                child: Text(
                  'TIMELINE',
                  style: TextStyle(color: theme.textMain, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ),
            Container(
              height: 240,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 1.0)),
              ),
              child: CustomPaint(
                painter: BrutalistTelemetryChartPainter(
                  temperatures: dailyChartTemps,
                  dayLabels: dailyChartDays,
                  theme: theme,
                ),
              ),
            ),
          ],

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.ruleBorder, width: 1.0)),
              color: theme.canvasBg,
            ),
            child: Center(
              child: Text(
                'DATA',
                style: TextStyle(color: theme.textMain, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: theme.ruleBorder, width: 1.0),
                verticalInside: BorderSide(color: theme.ruleBorder, width: 1.0),
                top: BorderSide(color: theme.ruleBorder, width: 1.0),
                left: BorderSide(color: theme.ruleBorder, width: 1.0),
                right: BorderSide(color: theme.ruleBorder, width: 1.0),
                bottom: BorderSide(color: theme.ruleBorder, width: 1.0),
              ),
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'DAY',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.textMain, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'CLIMATE',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.textMain, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'DATA/DATA',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.textMain, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                    ),
                  ],
                ),
                ...List.generate((daily['time'] as List? ?? []).length, (index) {
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

                  final String resolvedDayName = _convertToDayName(date);

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          resolvedDayName,
                          textAlign: TextAlign.center,
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
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.textMain, fontSize: 13, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildStructuralRow(String keys, String dataValue, WeatherUiTheme theme) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            keys,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textMain, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            dataValue,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textMain, fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ),
      ],
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