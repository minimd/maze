import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

const List<Color> colorPalette = [
  Color(0xfff72585), // Pink
  Color(0xff7209b7), // Purple
  Color(0xff3a0ca3), // Indigo
  Color(0xff4361ee), // Blue
  Color(0xff4cc9f0), // Light Blue
];
// The two possible angles for our slashes
const double FORWARD_SLASH_ANGLE = pi / 4; // 45 degrees
const double BACKWARD_SLASH_ANGLE = 3 * pi / 4; // 135 degrees

class Slash {
  // Angle properties
  late double _startAngle;
  late double _targetAngle;
  // --- NEW: Add color properties ---
  late Color _startColor;
  late Color _targetColor;

  double _animationStartValue;
  double _energy = 0.0;
  bool isControlled = false;

  Slash() : _animationStartValue = -1.0 {
    // Initialize angle
    final initialAngle =
        Random().nextBool() ? FORWARD_SLASH_ANGLE : BACKWARD_SLASH_ANGLE;
    _startAngle = initialAngle;
    _targetAngle = initialAngle;

    // --- NEW: Initialize color ---
    final initialColor = colorPalette[Random().nextInt(colorPalette.length)];
    _startColor = initialColor;
    _targetColor = initialColor;
  }
  void addEnergy(double amount) {
    // Add the new energy and clamp the value between 0.0 and 1.0
    _energy = (_energy + amount).clamp(0.0, 1.0);
  }

  void decay() {
    // This makes the energy fade over time. A lower number means faster decay.
    _energy *= 0.94;
    // If energy is very low, snap to 0 to prevent tiny calculations
    if (_energy < 0.01) _energy = 0.0;
  }

  double get energy => _energy;
  void orientTowards(
    Offset myPosition,
    Offset targetPosition,
    double animationValue,
  ) {
    isControlled = true; // Take control

    // Calculate the angle from my position to the target
    final double dx = targetPosition.dx - myPosition.dx;
    final double dy = targetPosition.dy - myPosition.dy;
    // atan2 gives us the angle in radians, perfect for our use case
    final newTargetAngle = atan2(dy, dx);

    // Only start a new animation if the target is different
    if ((newTargetAngle - _targetAngle).abs() > 0.1) {
      _startAngle = getAngle(animationValue);
      _targetAngle = newTargetAngle;
      _animationStartValue = animationValue;
    }
  }

  void flip(double currentAnimationValue) {
    if (isControlled) return;

    // Set start values from the current state
    _startAngle = getAngle(currentAnimationValue);
    _startColor = getColor(currentAnimationValue); // --- NEW ---

    // Set new target angle
    _targetAngle =
        (_targetAngle == FORWARD_SLASH_ANGLE)
            ? BACKWARD_SLASH_ANGLE
            : FORWARD_SLASH_ANGLE;

    // --- NEW: Set new target color (ensuring it's a different color) ---
    Color newColor;
    do {
      newColor = colorPalette[Random().nextInt(colorPalette.length)];
    } while (newColor == _targetColor);
    _targetColor = newColor;

    // Start the animation
    _animationStartValue = currentAnimationValue;
  }

  void releaseControl() {
    isControlled = false;
  }

  // --- NEW: Add getColor method ---
  Color getColor(double animationProgress) {
    if (_animationStartValue < 0) {
      return _targetColor;
    }

    double progress = animationProgress - _animationStartValue;
    if (progress < 0) progress += 1.0;

    const flipDuration = 0.2;

    if (progress >= flipDuration) {
      return _targetColor;
    } else {
      final double t = progress / flipDuration;
      final double easedT = Curves.easeInOut.transform(t);
      // Color.lerp is the perfect tool for smoothly interpolating between two colors.
      return Color.lerp(_startColor, _targetColor, easedT)!;
    }
  }

  double getAngle(double animationProgress) {
    if (_animationStartValue < 0) {
      return _targetAngle;
    }

    double progress = animationProgress - _animationStartValue;
    if (progress < 0) progress += 1.0;

    const flipDuration = 0.1;

    if (progress >= flipDuration) {
      _animationStartValue = -1.0;
      _startAngle = _targetAngle;
      return _targetAngle;
    } else {
      final double t = progress / flipDuration;
      final double easedT = Curves.easeInOut.transform(t);
      return _startAngle + (_targetAngle - _startAngle) * easedT;
    }
  }
}

class Animated10Print extends StatefulWidget {
  const Animated10Print({Key? key}) : super(key: key);

  @override
  _Animated10PrintState createState() => _Animated10PrintState();
}

class _Animated10PrintState extends State<Animated10Print>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;
  final List<Slash> _slashes = [];
  final int _gridSize = 20;
  Offset? _touchPosition;

  @override
  void initState() {
    super.initState();
    // The main ticker that drives all animations on screen
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Periodically tell a random slash to flip
    _timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (_slashes.isNotEmpty && mounted) {
        final index = Random().nextInt(_slashes.length);
        _slashes[index].flip(_controller.value);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
    Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1a1a1a),
      body: GestureDetector(
        // --- MODIFIED: We now use onPanStart to detect the initial touch ---
        onPanStart: (details) {
          setState(() {
            _touchPosition = details.localPosition;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _touchPosition = details.localPosition;
          });
        },
        onPanEnd: (details) {
          setState(() {
            _touchPosition = null;
          });
        },
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
              ),
            );
          },
        ),
      ),
    );
  }
}

class TenPrintPainter extends CustomPainter {
  final List<Slash> slashes;
  final int gridSize;
  final double animationValue;
  final Offset? touchPosition;
  TenPrintPainter({
    required this.slashes,
    required this.gridSize,
    required this.animationValue,
    required this.touchPosition, // --- NEW ---
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;

    final stepX = size.width / gridSize;
    final stepY = size.height / gridSize;
    // Use the smaller step to make cells squarish
    final step = min(stepX, stepY);

    // One-time grid initialization
    if (slashes.isEmpty && size.width > 0) {
      final int numX = (size.width / step).floor();
      final int numY = (size.height / step).floor();
      for (int i = 0; i < numX * numY; i++) {
        slashes.add(Slash());
      }
    }
      final double influenceRadius = size.width / 4;
    const rippleColor = Colors.white;

    int index = 0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        if (index >= slashes.length) break;

        final slash = slashes[index];
        final slashCenter = Offset(x + step / 2, y + step / 2);

        // --- CORE RIPPLE LOGIC ---
        
        // 1. Inject energy if touch is active
        if (touchPosition != null) {
          final distance = (slashCenter - touchPosition!).distance;
          if (distance < influenceRadius) {
            // The closer to the touch, the more energy we add.
            // This creates a nice soft edge on the ripple.
            final energyToAdd = 1.0 - (distance / influenceRadius);
            slash.addEnergy(energyToAdd * 0.5); // Multiplier controls ripple strength
          }
        }
        
        // 2. Get the slash's normal, calculated color and angle
        final angle = slash.getAngle(animationValue);
        final baseColor = slash.getColor(animationValue);
        
        // 3. Use the slash's current energy to modify its color
        // Color.lerp smoothly blends between the base color and the bright rippleColor.
        final displayColor = Color.lerp(baseColor, rippleColor, slash.energy)!;
        paint.color = displayColor.withOpacity(0.8);
        
        // 4. Tell the slash to decay its energy for the next frame
        slash.decay();
        
        // --- Drawing logic is the same as before ---
        final lineLength = step * 0.5;
        final startX = slashCenter.dx - cos(angle) * lineLength;
        final startY = slashCenter.dy - sin(angle) * lineLength;
        final endX = slashCenter.dx + cos(angle) * lineLength;
        final endY = slashCenter.dy + sin(angle) * lineLength;

        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
        index++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant TenPrintPainter oldDelegate) {
    // --- MODIFIED: Repaint if the touch position changes too ---
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.touchPosition != touchPosition;
  }
}
