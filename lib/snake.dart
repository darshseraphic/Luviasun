import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'main.dart';

// --- 1. LOCAL THEME MATRIX SPECIFICATION ---
class SnakeUiTheme {
  final bool isDark;
  late final Color canvasBg;
  late final Color textMain;
  late final Color textSub;
  late final Color ruleBorder;
  late final Color panelBg;
  final Color accentCrimson = const Color(0xFF5F0E0D);

  SnakeUiTheme(this.isDark) {
    canvasBg = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    textMain = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    textSub = isDark ? const Color(0xFF737373) : const Color(0xFF404040);
    ruleBorder = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5);
    // Updated to pure black and pure white
    panelBg = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
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
    final double cellSize = size.width / gridSizeX;

    final gridPaint = Paint()
      ..color = theme.ruleBorder.withOpacity(0.4)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= gridSizeX; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, size.height), gridPaint);
    }
    for (int i = 0; i <= gridSizeY; i++) {
      canvas.drawLine(Offset(0, i * cellSize), Offset(size.width, i * cellSize), gridPaint);
    }

    final snakePaint = Paint()
      ..color = theme.textMain
      ..style = PaintingStyle.fill;

    for (final point in snake) {
      canvas.drawRect(
        Rect.fromLTWH(point.x * cellSize, point.y * cellSize, cellSize, cellSize),
        snakePaint,
      );
    }

    if (fruit != null) {
      final fruitPaint = Paint()
        ..color = theme.accentCrimson
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(fruit!.x * cellSize, fruit!.y * cellSize, cellSize, cellSize),
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
  static const int _gridSizeY = 28;
  static const String _boxName = 'Luviasun';

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

  void _spawnFruit() {
    final random = Random();
    Point<int> newFruit;
    do {
      newFruit = Point(random.nextInt(_gridSizeX), random.nextInt(_gridSizeY));
    } while (_snake.contains(newFruit));
    _fruit = newFruit;
  }

  void _initializeBoard() {
    _snake = [
      const Point(6, 14),
      const Point(5, 14),
    ];
    _currentDirection = SnakeDirection.right;
    _nextDirection = SnakeDirection.right;
    _score = 0;
    _spawnFruit();
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

    if (nextHead.x < 0 || nextHead.x >= _gridSizeX || nextHead.y < 0 || nextHead.y >= _gridSizeY) {
      _gameOver();
      return;
    }

    if (_snake.contains(nextHead)) {
      _gameOver();
      return;
    }

    setState(() {
      _snake.insert(0, nextHead);

      if (nextHead == _fruit) {
        _score++;
        _spawnFruit();
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

    String buttonText = 'START ARCADE ENGINE';
    VoidCallback buttonAction = _startGame;

    if (_isGameOver) {
      buttonText = 'REBOOT ENGINE';
      buttonAction = _startGame;
    } else if (_isPlaying) {
      buttonText = 'PAUSE';
      buttonAction = _stopGame;
    } else if (_score > 0) {
      buttonText = 'RESUME ENGINE';
      buttonAction = _startGame;
    }

    return Scaffold(
      backgroundColor: theme.canvasBg,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            if (!_isPlaying || _isGameOver) return;
            final double dx = details.delta.dx;
            final double dy = details.delta.dy;

            if (dx.abs() > dy.abs()) {
              if (dx > 4.0) {
                _handleDirectionInput(SnakeDirection.right);
              } else if (dx < -4.0) {
                _handleDirectionInput(SnakeDirection.left);
              }
            } else {
              if (dy > 4.0) {
                _handleDirectionInput(SnakeDirection.down);
              } else if (dy < -4.0) {
                _handleDirectionInput(SnakeDirection.up);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SNAKE',
                  style: TextStyle(
                    color: theme.textMain,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'SCORE: ${_score.toString().padLeft(3, '0')}',
                      style: TextStyle(
                        color: theme.textMain,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    Text(
                      'BEST: ${_highScore.toString().padLeft(3, '0')}',
                      style: TextStyle(color: theme.textSub, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.05),
                    ),
                  ],
                ),

                Divider(color: theme.ruleBorder, height: 20, thickness: 0.8),

                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _gridSizeX / _gridSizeY,
                      child: Container(
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
                  ),
                ),

                const SizedBox(height: 16),
                GestureDetector(
                  onTap: buttonAction,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.textMain,
                      border: Border.all(color: theme.textMain, width: 1.0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      buttonText,
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
            ),
          ),
        ),
      ),
    );
  }
}