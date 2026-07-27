import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'dart:convert';
import 'weather.dart';
import 'compass.dart';
import 'calendar.dart';
import 'snake.dart';
import 'settings.dart';
import 'splashscreen.dart';

// --- GLOBAL STATE PROVIDERS ---
class ThemeNotifier extends Notifier<bool> {
  static const String _boxName = 'luviasun';
  static const String _key = 'is_dark_mode';

  @override
  bool build() {
    return Hive.box(_boxName).get(_key, defaultValue: true);
  }

  void toggleTheme() {
    state = !state;
    Hive.box(_boxName).put(_key, state);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, bool>(() {
  return ThemeNotifier();
});

final coordinateProvider = StateProvider<LatLng>((ref) {
  return const LatLng(18.5204, 73.8567);
});

// --- GLOBAL PRE-FETCH CACHE MATRIX ---
// This method runs in parallel behind the splash screen animation sequence
Future<void> preFetchWeatherTelemetry() async {
  try {
    final box = await Hive.openBox('weather_cache');
    final String todayKey = DateTime.now().toIso8601String().substring(0, 10);
    final String? cachedDate = box.get('last_fetch_day');
    final String? cachedJson = box.get('payload_string');

    // If cache is valid for today, skip hitting the network entirely
    if (cachedDate == todayKey && cachedJson != null) {
      debugPrint("PRE-FETCH SYSTEM: Valid local cache verified.");
      return;
    }

    debugPrint("PRE-FETCH SYSTEM: Fetching data in background behind splash screen...");
    final HttpClient client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

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
      await box.put('last_fetch_day', todayKey);
      await box.put('payload_string', responseBody);
      debugPrint("PRE-FETCH SYSTEM: Network cache successfully updated.");
    }
    client.close();
  } catch (e) {
    debugPrint("PRE-FETCH SYSTEM WARNING: Background fetch error ($e)");
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Core Storage
  await Hive.initFlutter();
  await Hive.openBox('luviasun');

  // Trigger background network fetch. It runs *while* the UI boots up.
  preFetchWeatherTelemetry();

  runApp(
    const ProviderScope(
      child: LuviasunAppEngine(),
    ),
  );
}

class LuviasunAppEngine extends ConsumerWidget {
  const LuviasunAppEngine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    return MaterialApp(
      title: 'LUVIASUN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      home: const AnimatedSplashScreen(
        child: MainNavigationShell(),
      ),
    );
  }
}

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentViewIndex = 0;

  final List<Widget> _instrumentViews = [
    const WeatherScreen(),
    const MapScreen(),
    const CalendarScreen(),
    const SnakeScreen(),
    const SettingsScreen(),
  ];

  final List<String> _navigationLabels = [
    'WEATHER',
    'COMPASS',
    'CALENDAR',
    'ARCADE',
    'SETTING',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);

    final canvasBg = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final textMain = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final textSub = isDark ? const Color(0xFF737373) : const Color(0xFF404040);
    final ruleBorder = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5);

    return Scaffold(
      backgroundColor: canvasBg,
      body: IndexedStack(
        index: _currentViewIndex,
        children: _instrumentViews,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: ruleBorder, width: 0.8)),
          color: canvasBg,
        ),
        child: SafeArea(
          child: Row(
            children: List.generate(_navigationLabels.length, (index) {
              final bool isSelected = _currentViewIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentViewIndex = index;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? textMain.withOpacity(0.05) : Colors.transparent,
                      border: index < _navigationLabels.length - 1
                          ? Border(right: BorderSide(color: ruleBorder, width: 0.8))
                          : null,
                    ),
                    child: Text(
                      _navigationLabels[index],
                      style: TextStyle(
                        color: isSelected ? textMain : textSub,
                        fontSize: 9,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}