import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'main.dart'; // Imports global themeProvider flag

// --- 1. LOCAL THEME MATRIX SPECIFICATION ---
class SnakeUiTheme {
  final bool isDark;
  late final Color canvasBg;
  late final Color textMain;
  late final Color textSub;
  late final Color ruleBorder;
  late final Color panelBg;
  final Color accentCrimson = const Color(0xFF5F0E0D); // Strict fruit color

  SnakeUiTheme(this.isDark) {
    canvasBg = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    textMain = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    textSub = isDark ? const Color(0xFF737373) : const Color(0xFF404040);
    ruleBorder = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5);
    panelBg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
  }
}

// --- 2. ARCADE STATE ENUMS & PAINTER ---
enum SnakeDirection { up, down, left, right }

class SnakePainter extends CustomPainter {
  final int gridSizeX;
  final int gridSizeY;
  final List<Point<int>> snake;
  final Point<int>? fruit;
  final SnakeUiTheme theme;

  SnakePainter({
    required this.gridSizeX,
    required this.gridSizeY,
    required this.snake,
    required this.fruit,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSizeX = size.width / gridSizeX;
    final double cellSizeY = size.height / gridSizeY;

    // Draw faint structural coordinate grid lines across full screen bounds
    final gridPaint = Paint()
      ..color = theme.ruleBorder.withOpacity(0.4)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= gridSizeX; i++) {
      canvas.drawLine(Offset(i * cellSizeX, 0), Offset(i * cellSizeX, size.height), gridPaint);
    }
    for (int i = 0; i <= gridSizeY; i++) {
      canvas.drawLine(Offset(0, i * cellSizeY), Offset(size.width, i * cellSizeY), gridPaint);
    }

    // Paint the Snake Segments (Pure Squares)
    final snakePaint = Paint()
      ..color = theme.textMain
      ..style = PaintingStyle.fill;

    for (final point in snake) {
      canvas.drawRect(
        Rect.fromLTWH(point.x * cellSizeX, point.y * cellSizeY, cellSizeX, cellSizeY),
        snakePaint,
      );
    }

    // Paint the Fruit Segment (Deep Crimson Square)
    if (fruit != null) {
      final fruitPaint = Paint()
        ..color = theme.accentCrimson
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(fruit!.x * cellSizeX, fruit!.y * cellSizeY, cellSizeX, cellSizeY),
        fruitPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SnakePainter oldDelegate) => true;
}

// --- 3. ENGINE CONTROLLER LOGIC ---
class SnakeScreen extends ConsumerStatefulWidget {
  const SnakeScreen({super.key});

  @override
  ConsumerState<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends ConsumerState<SnakeScreen> {
  static const int _gridSizeX = 20;
  static const int _gridSizeY = 28; // Expanded matrix limits to fill full screen real estate
  static const String _boxName = 'rocen_settings_box';

  Timer? _gameLoop;
  bool _isPlaying = false;
  bool _isGameOver = false;

  List<Point<int>> _snake = [];
  Point<int>? _fruit;
  SnakeDirection _currentDirection = SnakeDirection.right;
  SnakeDirection _nextDirection = SnakeDirection.right;

  int _score = 0;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _initializeBoard();
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    super.dispose();
  }

  void _loadHighScore() {
    final box = Hive.box(_boxName);
    _highScore = box.get('snake_best_score', defaultValue: 0);
  }

  void _saveHighScore() {
    if (_score > _highScore) {
      _highScore = _score;
      Hive.box(_boxName).put('snake_best_score', _highScore);
    }
  }

  void _initializeBoard() {
    // Starting coordinates initialized at exactly 2 blocks length
    _snake = [
      const Point(6, 14),
      const Point(5, 14),
    ];
    _currentDirection = SnakeDirection.right;
    _nextDirection = SnakeDirection.right;
    _score = 0;
    _spawnFruit();
  }

  void _spawnFruit() {
    final random = Random();
    Point<int> newFruit;
    do {
      newFruit = Point(random.nextInt(_gridSizeX), random.nextInt(_gridSizeY));
    } while (_snake.contains(newFruit));
    _fruit = newFruit;
  }

  void _startGame() {
    if (_isPlaying) return;

    if (_isGameOver) {
      _initializeBoard();
      _isGameOver = false;
    }

    setState(() => _isPlaying = true);

    _gameLoop = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      _tick();
    });
  }

  void _stopGame() {
    _gameLoop?.cancel();
    setState(() => _isPlaying = false);
  }

  void _gameOver() {
    _stopGame();
    _saveHighScore();
    setState(() => _isGameOver = true);
  }

  void _tick() {
    _currentDirection = _nextDirection;
    final head = _snake.first;
    Point<int> nextHead;

    switch (_currentDirection) {
      case SnakeDirection.up:
        nextHead = Point(head.x, head.y - 1);
        break;
      case SnakeDirection.down:
        nextHead = Point(head.x, head.y + 1);
        break;
      case SnakeDirection.left:
        nextHead = Point(head.x - 1, head.y);
        break;
      case SnakeDirection.right:
        nextHead = Point(head.x + 1, head.y);
        break;
    }

    // Dynamic Full Screen Wall Collision Boundaries
    if (nextHead.x < 0 || nextHead.x >= _gridSizeX || nextHead.y < 0 || nextHead.y >= _gridSizeY) {
      _gameOver();
      return;
    }

    // Self Collision Failsafe Loops
    if (_snake.contains(nextHead)) {
      _gameOver();
      return;
    }

    setState(() {
      _snake.insert(0, nextHead);

      if (nextHead == _fruit) {
        _score++;
        _spawnFruit(); // Grows naturally by omitting the tail truncation logic step
      } else {
        _snake.removeLast();
      }
    });
  }

  void _handleDirectionInput(SnakeDirection newDir) {
    if ((_currentDirection == SnakeDirection.up && newDir == SnakeDirection.down) ||
        (_currentDirection == SnakeDirection.down && newDir == SnakeDirection.up) ||
        (_currentDirection == SnakeDirection.left && newDir == SnakeDirection.right) ||
        (_currentDirection == SnakeDirection.right && newDir == SnakeDirection.left)) {
      return;
    }
    _nextDirection = newDir;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final theme = SnakeUiTheme(isDark);

    return Scaffold(
      backgroundColor: theme.canvasBg,
      body: SafeArea(
        child: GestureDetector(
          // Immersive Telemetry Pan Tracker converting finger swipes directly to coordinates
          onPanUpdate: (details) {
            if (!_isPlaying || _isGameOver) return;
            final double dx = details.delta.dx;
            final double dy = details.delta.dy;

            if (dx.abs() > dy.abs()) {
              if (dx > 1.5) {
                _handleDirectionInput(SnakeDirection.right);
              } else if (dx < -1.5) {
                _handleDirectionInput(SnakeDirection.left);
              }
            } else {
              if (dy > 1.5) {
                _handleDirectionInput(SnakeDirection.down);
              } else if (dy < -1.5) {
                _handleDirectionInput(SnakeDirection.up);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // METRIC SYSTEM HEADER HUD
                Text(
                  'LUVIASUN INSTRUMENTATION // ARCADE',
                  style: TextStyle(color: theme.textSub, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.06),
                ),
                const SizedBox(height: 2),
                Text(
                  'FULLSCREEN SNAKE ENGINE',
                  style: TextStyle(color: theme.textMain, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.02),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'SCORE: ${_score.toString().padLeft(3, '0')}',
                      style: TextStyle(color: theme.textMain, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.05),
                    ),
                    Text(
                      'BEST: ${_highScore.toString().padLeft(3, '0')}',
                      style: TextStyle(color: theme.textSub, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.05),
                    ),
                  ],
                ),

                Divider(color: theme.ruleBorder, height: 20, thickness: 0.8),

                // UNBOUNDED FULL SCREEN ENGINE GRAPHICS MESH
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: _isGameOver ? theme.accentCrimson : theme.textMain, width: 1.2),
                      color: theme.panelBg,
                    ),
                    child: CustomPaint(
                      painter: SnakePainter(
                        gridSizeX: _gridSizeX,
                        gridSizeY: _gridSizeY,
                        snake: _snake,
                        fruit: _fruit,
                        theme: theme,
                      ),
                    ),
                  ),
                ),

                // COLD REBOOT / LAUNCH SYSTEM FOOTER MODALS (Vanishes cleanly during execution loops)
                if (!_isPlaying) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _startGame,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.textMain,
                        border: Border.all(color: theme.textMain, width: 1.0),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _isGameOver ? 'REBOOT ENGINE' : 'START ARCADE ENGINE',
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.08,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}