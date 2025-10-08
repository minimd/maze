import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
const List<Color> colorPalette = [
  Color(0xfff72585), // Pink
  Color(0xff7209b7), // Purple
  Color(0xff3a0ca3), // Indigo
  Color(0xff4361ee), // Blue
  Color(0xff4cc9f0), 
  Color(0xfff3722c), // Orange
  Color.fromARGB(255, 187, 243, 44), // Orange

];
const Color backgroundColor = Color.fromARGB(255, 26, 28, 29); // Dark background
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

   void orientTowards(Offset myPosition, Offset targetPosition, double animationValue) {
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
    _targetAngle = (_targetAngle == FORWARD_SLASH_ANGLE)
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
      backgroundColor: backgroundColor,
      // --- NEW: Wrap the AnimatedBuilder with a GestureDetector ---
      body: GestureDetector(
        // When the user starts or moves their finger
        onPanUpdate: (details) {
          setState(() {
            _touchPosition = details.localPosition;
          });
        },
        // When the user lifts their finger
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
                // --- NEW: Pass the touch position to the painter ---
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
    final paint = Paint()
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

    int index = 0;
    // --- Define the radius of influence for the touch ---
    final double influenceRadius = size.width / 4;

    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        if (index >= slashes.length) break;

        final slash = slashes[index];
        final slashCenter = Offset(x + step / 2, y + step / 2);

        // --- NEW: The core interaction logic ---
        if (touchPosition != null) {
          final distance = (slashCenter - touchPosition!).distance;
          if (distance < influenceRadius) {
            // If inside the radius, tell the slash to orient itself
            slash.orientTowards(slashCenter, touchPosition!, animationValue);
          } else {
            // If outside, make sure it's released
            slash.releaseControl();
          }
        } else {
          // If there's no touch, make sure all slashes are released
          slash.releaseControl();
        }
        
        // The rest of the drawing logic works perfectly as is!
        final angle = slash.getAngle(animationValue);
        paint.color = slash.getColor(animationValue).withOpacity(0.8);

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