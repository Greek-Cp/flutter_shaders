import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'dart:ui' as ui;

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({Key? key}) : super(key: key);

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final WaveController _waveController = WaveController();

  void _onTriggerWave() {
    // Set the wave origin (normalized coordinates between 0.0 and 1.0)
    final double x = 0.1; // Center x
    final double y = 0.5; // Center y
    _waveController.triggerWave(Offset(x, y));
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSampledContainer(
      controller: _waveController,
      child: MaterialApp(
        title: 'Shader Playground',
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Image.asset(
                "assets/img1.jpg",
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              ElevatedButton(
                onPressed: _onTriggerWave,
                child: Text('Klik Disini Untuk Water Ripple'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedBlurContainer extends StatefulWidget {
  const AnimatedBlurContainer({
    Key? key,
    this.width = 200,
    this.height = 200,
  }) : super(key: key);

  final double width;
  final double height;

  @override
  _AnimatedBlurContainerState createState() => _AnimatedBlurContainerState();
}

class _AnimatedBlurContainerState extends State<AnimatedBlurContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blurAnimation;
  late Animation<double> _hueAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Animate blur value between 0 and 10, back and forth
    _blurAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 10.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 10.0, end: 0.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Animate hue from 0 to 360 degrees
    _hueAnimation = Tween<double>(begin: 0.0, end: 360.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Function to generate colors based on hue
  Color _colorFromHue(double hue) {
    return HSVColor.fromAHSV(1.0, hue % 360, 0.8, 0.8).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final blurSigma = _blurAnimation.value;
        final hue = _hueAnimation.value;

        final color1 = _colorFromHue(hue);
        final color2 = _colorFromHue(hue + 60);
        final color3 = _colorFromHue(hue + 120);
        final color4 = _colorFromHue(hue + 180);
        final color5 = _colorFromHue(hue + 240);
        final color6 = _colorFromHue(hue + 300);
        final color7 = _colorFromHue(hue + 360);

        return Container(
          width: widget.width,
          height: widget.height,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color1,
                    color2,
                    color3,
                    color4,
                    color5,
                    color6,
                    color7,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class WaveController {
  void Function(Offset)? _triggerWaveCallback;

  void addListener(void Function(Offset) callback) {
    _triggerWaveCallback = callback;
  }

  void triggerWave(Offset origin) {
    if (_triggerWaveCallback != null) {
      _triggerWaveCallback!(origin);
    }
  }

  void dispose() {
    _triggerWaveCallback = null;
  }
}

class AnimatedSampledContainer extends StatefulWidget {
  const AnimatedSampledContainer({
    Key? key,
    required this.controller,
    required this.child,
  }) : super(key: key);

  final WaveController controller;
  final Widget child;

  @override
  _AnimatedSampledContainerState createState() =>
      _AnimatedSampledContainerState();
}

class _AnimatedSampledContainerState extends State<AnimatedSampledContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isWaveActive = false;
  Offset _waveOrigin = Offset(0.5, 0.5); // Default center
  Duration _startTime = Duration.zero;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(); // Repeats to keep the time updated

    // Register the wave trigger callback
    widget.controller.addListener(_onTriggerWave);
  }

  @override
  void dispose() {
    widget.controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTriggerWave(Offset origin) {
    setState(() {
      _isWaveActive = true;
      _startTime = _animationController.lastElapsedDuration ?? Duration.zero;
      _waveOrigin = origin; // Set the wave origin
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShaderBuilder(
      assetKey: 'shaders/wave.frag',
      (context, shader, child) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final elapsedTime =
                _animationController.lastElapsedDuration ?? Duration.zero;
            final timeSinceStart =
                (elapsedTime - _startTime).inMilliseconds / 1000.0;

            // Stop the wave effect after a certain duration
            if (timeSinceStart > 2.0 && _isWaveActive) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _isWaveActive = false;
                });
              });
            }

            return AnimatedSampler(
              (image, size, canvas) {
                shader
                  ..setFloat(0, _isWaveActive ? timeSinceStart : 0.0) // uTime
                  ..setFloat(1, size.width) // uSize.x
                  ..setFloat(2, size.height) // uSize.y
                  ..setFloat(3, _waveOrigin.dx) // uOrigin.x
                  ..setFloat(4, _waveOrigin.dy) // uOrigin.y
                  ..setImageSampler(0, image); // uTexture

                canvas.drawRect(
                  Offset.zero & size,
                  Paint()..shader = shader,
                );
              },
              child: widget.child,
            );
          },
        );
      },
    );
  }
}
