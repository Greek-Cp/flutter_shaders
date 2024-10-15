import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'dart:ui' as ui;

class RippleShaderWidget extends StatefulWidget {
  @override
  _RippleShaderWidgetState createState() => _RippleShaderWidgetState();
}

class _RippleShaderWidgetState extends State<RippleShaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _mousePosition = Offset.zero;
  Duration _startTime = Duration.zero;
  bool _isRippleActive = false;
  ui.Image? _capturedImage;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _triggerRipple() async {
    final size = MediaQuery.of(context).size;
    _mousePosition = size.center(Offset.zero);

    // Capture the Scaffold content as an image
    RenderRepaintBoundary boundary =
        _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image capturedImage = await boundary.toImage(pixelRatio: 1.0);

    setState(() {
      _capturedImage = capturedImage;
      _startTime = Duration.zero;
      _isRippleActive = true;
      _controller.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return RepaintBoundary(
      key: _repaintKey,
      child: Scaffold(
        appBar: AppBar(title: Text('Ripple Shader over Scaffold')),
        body: Stack(
          children: [
            // Wrap the content in a RepaintBoundary
            Image.asset("assets/img.jpg"),
            Center(
              child: ElevatedButton(
                onPressed: _triggerRipple,
                child: Text('Wave On'),
              ),
            ),
            // Overlay the shader when ripple is active
            if (_isRippleActive && _capturedImage != null)
              ShaderBuilder(
                (context, shader, child) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final elapsedTime =
                          _controller.lastElapsedDuration ?? Duration.zero;
                      final timeSinceStart =
                          (elapsedTime - _startTime).inMilliseconds / 1000.0;

                      // Stop the ripple effect after duration ends
                      if (timeSinceStart > 5.0) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _isRippleActive = false;
                            _controller.stop();
                            _capturedImage = null;
                          });
                        });
                      }

                      shader
                        ..setFloat(0, size.width) // iResolution.x
                        ..setFloat(1, size.height) // iResolution.y
                        ..setFloat(2, _mousePosition.dx) // iMouse.x
                        ..setFloat(3, _mousePosition.dy) // iMouse.y
                        ..setFloat(4, timeSinceStart) // iTime
                        ..setImageSampler(0, _capturedImage!); // iChannel0

                      return CustomPaint(
                        size: size,
                        painter: _ShaderPainter(shader),
                      );
                    },
                  );
                },
                assetKey: 'shaders/ripple.frag',
              ),
          ],
        ),
      ),
    );
  }
}

class _ShaderPainter extends CustomPainter {
  final FragmentShader shader;

  _ShaderPainter(this.shader);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter oldDelegate) => true;
}
