import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import local instrument views
import 'weather.dart';
import 'compass.dart';
import 'calendar.dart';
import 'snake.dart';
import 'settings.dart';

// --- 1. GLOBAL STATE PROVIDERS ---
class ThemeNotifier extends Notifier<bool> {
  static const String _boxName = 'luviasun'; // Updated storage name signature
  static const String _key = 'is_dark_mode';

  @override
  bool build() {
    // Default to absolute dark mode if no state signature is found
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

// --- 2. GLOBAL SYSTEM INITIALIZATION ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local disk registry partitions
  await Hive.initFlutter();
  await Hive.openBox('luviasun');

  runApp(
    const ProviderScope(
      child: LuviasunAppEngine(),
    ),
  );
}

// --- 3. ROOT APPLICATION WIDGET ---
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
        // Removed monospace property to guarantee global system sans-serif presentation
      ),
      home: const MainNavigationShell(),
    );
  }
}

// --- 4. CORE NAVIGATION INTERFACE SHELL ---
class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentViewIndex = 0;

  // Registered application modules
  final List<Widget> _instrumentViews = [
    const WeatherScreen(),
    const MapScreen(),
    const CalendarScreen(),
    const SnakeScreen(),
    const SettingsScreen(),
  ];

  final List<String> _navigationLabels = [
    'WX',
    'COMPASS',
    'CALENDAR',
    'ARCADE',
    'SYS',
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