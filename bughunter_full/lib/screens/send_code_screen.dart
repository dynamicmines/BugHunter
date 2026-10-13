import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/auth_state.dart';
import 'verify_code_screen.dart';

/// Экраны «Отправляем код» (13 и 16 в Figma): короткая пауза, затем ввод кода.
class SendCodeScreen extends StatefulWidget {
  const SendCodeScreen({super.key, required this.email, required this.purpose});

  final String email;
  final CodePurpose purpose;

  @override
  State<SendCodeScreen> createState() => _SendCodeScreenState();
}

class _SendCodeScreenState extends State<SendCodeScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => VerifyCodeScreen(email: widget.email, purpose: widget.purpose),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reset = widget.purpose == CodePurpose.resetPassword;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BigCircleIcon(
                icon: reset ? Icons.lock_outline : Icons.bolt,
                bg: kPrimaryTint,
                fg: const Color(0xFFC4C0FF),
                size: 88,
              ),
              const SizedBox(height: 28),
              Text('Отправляем код', style: ts(20, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                reset ? 'Проверь почту через минуту' : 'Обычно приходит в течение минуты',
                textAlign: TextAlign.center,
                style: ts(14, color: kMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
