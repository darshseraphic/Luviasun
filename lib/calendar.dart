import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main.dart'; // Imports your global themeProvider flag

// --- 1. ENGINE CONTROLLER SYSTEM ---
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static const int _matrixColumns = 7;
  static const List<String> _monthNames = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
  ];
  static const List<String> _dayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  int _getTotalDaysInYear(int year) {
    bool isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    return isLeapYear ? 366 : 365;
  }

  List<int> _getDaysInMonths(int year) {
    bool isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    return [31, isLeapYear ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  }

  int _getDayOfYear(int monthIndex, int day, List<int> daysInMonths) {
    int dayOfYear = day;
    for (int i = 0; i < monthIndex; i++) {
      dayOfYear += daysInMonths[i];
    }
    return dayOfYear;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final now = DateTime.now();
    final currentYear = now.year;

    final int totalDaysInYear = _getTotalDaysInYear(currentYear);
    final List<int> daysInMonths = _getDaysInMonths(currentYear);

    // Calculate current running day index for telemetry data metrics
    int currentDayOfYear = 0;
    for (int i = 0; i < now.month - 1; i++) {
      currentDayOfYear += daysInMonths[i];
    }
    currentDayOfYear += now.day;
    double completionPercentage = (currentDayOfYear / totalDaysInYear) * 100;

    final textMain = isDark ? Colors.white : Colors.black;
    final textSub = isDark ? const Color(0xFF737373) : const Color(0xFF888888);
    final ruleBorder = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5);
    final filledColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP HUD TELEMETRY DATA STRIP
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'CALENDAR',
                    style: TextStyle(color: textMain, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                  ),
                  Text(
                    '$currentDayOfYear / $totalDaysInYear DAYS (${completionPercentage.toStringAsFixed(1)}%)',
                    style: TextStyle(color: textSub, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.01),
                  ),
                ],
              ),
            ),

            Divider(color: ruleBorder, height: 1, thickness: 0.8),

            // HIGH-FIDELITY 2-COLUMN BRUTALIST GRID ARRAY
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: GridView.builder(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18.0,
                    mainAxisSpacing: 24.0,
                    childAspectRatio: 0.76,
                  ),
                  itemBuilder: (context, monthIndex) {
                    final String monthName = _monthNames[monthIndex];
                    final int totalDaysInMonth = daysInMonths[monthIndex];

                    final DateTime firstDayOfMonth = DateTime(currentYear, monthIndex + 1, 1);
                    final int startingWeekday = firstDayOfMonth.weekday;
                    final int leadingBlanks = startingWeekday - 1;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthName,
                          style: TextStyle(color: textMain, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.04),
                        ),
                        const SizedBox(height: 8),

                        Expanded(
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _matrixColumns,
                              crossAxisSpacing: 3.5,
                              mainAxisSpacing: 3.5,
                            ),
                            itemCount: _matrixColumns + leadingBlanks + totalDaysInMonth,
                            itemBuilder: (context, index) {
                              if (index < _matrixColumns) {
                                return Center(
                                  child: Text(
                                    _dayHeaders[index],
                                    style: TextStyle(color: textSub, fontSize: 7.5, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }

                              final int gridIndex = index - _matrixColumns;

                              if (gridIndex < leadingBlanks) {
                                return const SizedBox.shrink();
                              }

                              final int day = gridIndex - leadingBlanks + 1;
                              final int dayOfYear = _getDayOfYear(monthIndex, day, daysInMonths);

                              Color boxColor;
                              Color borderColor;
                              Color textColor;

                              if (dayOfYear == currentDayOfYear) {
                                // TODAY LOCK: Highlights the current chronological anchor coordinate in crimson
                                boxColor = const Color(0xFF5F0E0D);
                                borderColor = const Color(0xFF5F0E0D);
                                textColor = Colors.white;
                              } else if (dayOfYear < currentDayOfYear) {
                                // ELAPSED METRIC: SOLID BLOCK COMPLIANCE
                                boxColor = filledColor;
                                borderColor = filledColor;
                                textColor = isDark ? Colors.black : Colors.white;
                              } else {
                                // REMAINING METRIC: HOLLOW BLOCK COMPLIANCE
                                boxColor = Colors.transparent;
                                borderColor = ruleBorder;
                                textColor = textMain;
                              }

                              return Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: boxColor,
                                  border: Border.all(
                                    color: borderColor,
                                    width: 0.7,
                                  ),
                                  borderRadius: BorderRadius.circular(1.0),
                                ),
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 6.8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            Divider(color: ruleBorder, height: 1, thickness: 0.8),

            // LOWER LEGEND MATRIX STATUS HUD
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 16.0),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: filledColor,
                      borderRadius: BorderRadius.circular(1.0),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('ELAPSED', style: TextStyle(color: textSub, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.02)),
                  const SizedBox(width: 16),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: ruleBorder, width: 0.7),
                      borderRadius: BorderRadius.circular(1.0),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('REMAINING', style: TextStyle(color: textSub, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.02)),
                  const SizedBox(width: 16),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5F0E0D),
                      borderRadius: BorderRadius.circular(1.0),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('CURRENT', style: TextStyle(color: textSub, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.02)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}