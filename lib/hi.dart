import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
// --- CONSTANTS ---
const double FORWARD_SLASH_ANGLE = pi / 4;
const double BACKWARD_SLASH_ANGLE = 3 * pi / 4;
const List<Color> colorPalette = [
  Color(0xfff72585), Color(0xff7209b7), Color(0xff3a0ca3),
  Color(0xff4361ee), Color(0xff4cc9f0),
];

// --- SLASH (CELL) CLASS ---
class Slash {
  bool isAlive = true;
  double _fade = 1.0;
  double _fadeTarget = 1.0;
  double _energy = 0.0;
  late double _startAngle;
  late double _targetAngle;
  late Color _startColor;
  late Color _targetColor;
  double _animationStartValue;

  Slash() : _animationStartValue = -1.0 {
    final initialAngle = Random().nextBool() ? FORWARD_SLASH_ANGLE : BACKWARD_SLASH_ANGLE;
    _startAngle = initialAngle;
    _targetAngle = initialAngle;
    final initialColor = colorPalette[Random().nextInt(colorPalette.length)];
    _startColor = initialColor;
    _targetColor = initialColor;
  }

  void kill() { _fadeTarget = 0.0; }
  void revive() {
    _fadeTarget = 1.0;
    _startColor = colorPalette[Random().nextInt(colorPalette.length)];
    _targetColor = _startColor;
    _startAngle = Random().nextBool() ? FORWARD_SLASH_ANGLE : BACKWARD_SLASH_ANGLE;
    _targetAngle = _startAngle;
  }

  void updateFade() {
    if ((_fade - _fadeTarget).abs() > 0.01) {
      _fade += (_fadeTarget - _fade) * 0.1;
    } else {
      _fade = _fadeTarget;
      if (_fade == 0.0) isAlive = false;
      if (_fade == 1.0) isAlive = true;
    }
  }

  double get opacity => _fade;
  void addEnergy(double amount) { _energy = (_energy + amount).clamp(0.0, 1.0); }
  void decay() {
    _energy *= 0.94;
    if (_energy < 0.01) _energy = 0.0;
  }
  double get energy => _energy;

  void flip(double currentAnimationValue) {
    if (!isAlive || _fade < 1.0) return;
    _startAngle = getAngle(currentAnimationValue);
    _startColor = getColor(currentAnimationValue);
    _targetAngle = (_targetAngle == FORWARD_SLASH_ANGLE) ? BACKWARD_SLASH_ANGLE : FORWARD_SLASH_ANGLE;
    Color newColor;
    do { newColor = colorPalette[Random().nextInt(colorPalette.length)]; } while (newColor == _targetColor);
    _targetColor = newColor;
    _animationStartValue = currentAnimationValue;
  }

  Color getColor(double animationProgress) {
    if (_animationStartValue < 0) return _targetColor;
    double progress = animationProgress - _animationStartValue;
    if (progress < 0) progress += 1.0;
    const flipDuration = 0.1;
    if (progress >= flipDuration) return _targetColor;
    final t = progress / flipDuration;
    final easedT = Curves.easeInOut.transform(t);
    return Color.lerp(_startColor, _targetColor, easedT)!;
  }

  double getAngle(double animationProgress) {
    if (_animationStartValue < 0) return _targetAngle;
    double progress = animationProgress - _animationStartValue;
    if (progress < 0) progress += 1.0;
    const flipDuration = 0.1;
    if (progress >= flipDuration) {
      _animationStartValue = -1.0;
      _startAngle = _targetAngle;
      return _targetAngle;
    }
    final t = progress / flipDuration;
    final easedT = Curves.easeInOut.transform(t);
    return _startAngle + (_targetAngle - _startAngle) * easedT;
  }
}

// --- STATEFUL WIDGET ---
class Animated10Print extends StatefulWidget {
  const Animated10Print({Key? key}) : super(key: key);
  @override
  _Animated10PrintState createState() => _Animated10PrintState();
}

class _Animated10PrintState extends State<Animated10Print> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _flipTimer;
  Timer? _generationTimer;
  bool _runGeneration = false;
  final List<Slash> _slashes = [];
  final int _gridSize = 35;
  Offset? _touchPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _flipTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (_slashes.isNotEmpty && mounted) {
        _slashes[Random().nextInt(_slashes.length)].flip(_controller.value);
      }
    });
    _generationTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (mounted) setState(() => _runGeneration = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _flipTimer?.cancel();
    _generationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1a1a1a),
      body: GestureDetector(
        onPanStart: (details) => setState(() => _touchPosition = details.localPosition),
        onPanUpdate: (details) => setState(() => _touchPosition = details.localPosition),
        onPanEnd: (_) => setState(() => _touchPosition = null),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: MediaQuery.of(context).size,
              painter: TenPrintPainter(
                slashes: _slashes,
                gridSize: _gridSize,
                animationValue: _controller.value,
                touchPosition: _touchPosition,
                runGeneration: _runGeneration,
                onGenerationComplete: () => _runGeneration = false,
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- CUSTOM PAINTER ---
class TenPrintPainter extends CustomPainter {
  final List<Slash> slashes;
  final int gridSize;
  final double animationValue;
  final Offset? touchPosition;
  final bool runGeneration;
  final VoidCallback onGenerationComplete;
  int? _numX;

  TenPrintPainter({
    required this.slashes,
    required this.gridSize,
    required this.animationValue,
    this.touchPosition,
    required this.runGeneration,
    required this.onGenerationComplete,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (slashes.isEmpty && size.width > 0) {
      final step = size.width / gridSize;
      _numX = (size.width / step).floor();
      if (_numX == null || _numX == 0) return;
      final numY = (size.height / step).floor();
      for (int i = 0; i < _numX! * numY; i++) {
        slashes.add(Slash());
      }
    }

    if (runGeneration && slashes.isNotEmpty) {
      _runGameOfLife();
      onGenerationComplete();
    }
    
    final paint = Paint()..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    final step = size.width / gridSize;
    final double influenceRadius = 15;
    const rippleColor = Colors.white;
    
    int index = 0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        if (index >= slashes.length) break;
        final slash = slashes[index];
        slash.updateFade();

        if (slash.opacity > 0) {
          final slashCenter = Offset(x + step / 2, y + step / 2);
          
          if (touchPosition != null) {
            final distance = (slashCenter - touchPosition!).distance;
            if (distance < influenceRadius) {
              final energyToAdd = (1.0 - (distance / influenceRadius));
              slash.addEnergy(energyToAdd * 0.5);
              if (slash.energy > 0.8) slash.kill();
            }
          }

          final angle = slash.getAngle(animationValue);
          final baseColor = slash.getColor(animationValue);
          final displayColor = Color.lerp(baseColor, rippleColor, slash.energy)!;
          paint.color = displayColor.withOpacity(slash.opacity * 0.8);
          slash.decay();

          final lineLength = step * 0.5;
          final startX = slashCenter.dx - cos(angle) * lineLength;
          final startY = slashCenter.dy - sin(angle) * lineLength;
          final endX = slashCenter.dx + cos(angle) * lineLength;
          final endY = slashCenter.dy + sin(angle) * lineLength;
          canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
        }
        index++;
      }
    }
  }

  void _runGameOfLife() {
    if (slashes.isEmpty || _numX == null) return;
    final List<bool> nextGeneration = List.generate(slashes.length, (i) => slashes[i].isAlive);
    for (int i = 0; i < slashes.length; i++) {
      final neighbors = _countLivingNeighbors(i);
      if (slashes[i].isAlive && (neighbors < 2 || neighbors > 3)) {
        nextGeneration[i] = false;
      } else if (!slashes[i].isAlive && neighbors == 3) {
        nextGeneration[i] = true;
      }
    }
    for (int i = 0; i < slashes.length; i++) {
      if (nextGeneration[i] && !slashes[i].isAlive) {
        slashes[i].revive();
      } else if (!nextGeneration[i] && slashes[i].isAlive) {
        slashes[i].kill();
      }
    }
  }

  int _countLivingNeighbors(int index) {
    if (_numX == null) return 0;
    int count = 0;
    final int x = index % _numX!;
    final int y = index ~/ _numX!;
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        final int nx = x + i;
        final int ny = y + j;
        if (nx >= 0 && nx < _numX!) {
          final int neighborIndex = ny * _numX! + nx;
          if (neighborIndex >= 0 && neighborIndex < slashes.length && slashes[neighborIndex].isAlive) {
            count++;
          }
        }
      }
    }
    return count;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}