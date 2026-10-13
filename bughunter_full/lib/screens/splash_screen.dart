import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'auth_gate.dart';

/// Экран запуска: градиент, логотип и тонкая полоса загрузки (экран 01 в Figma).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 250),
            pageBuilder: (_, __, ___) => const AuthGate(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kSplashGradient),
        child: Stack(
          children: [
            Positioned(
              top: -150,
              left: -150,
              child: Container(
                width: 380,
                height: 380,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x14FFFFFF)),
              ),
            ),
            Positioned(
              bottom: -170,
              right: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x0FFFFFFF)),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LogoMark(size: 108, radius: 30, bg: Colors.white, fg: kPrimary, shadow: true),
                  const SizedBox(height: 24),
                  Text(
                    nazvanieProekta,
                    style: ts(34, weight: FontWeight.w700, color: Colors.white, spacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    podzagolovok,
                    style: ts(15, color: const Color(0xFFD9D4FF)),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 96,
              child: Center(
                child: SizedBox(
                  width: 120,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: 0.15 + 0.85 * _controller.value,
                          minHeight: 4,
                          color: Colors.white,
                          backgroundColor: const Color(0x40FFFFFF),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
