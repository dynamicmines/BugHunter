import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';

/// Пароль изменён (экран 18 в Figma).
class PasswordDoneScreen extends StatelessWidget {
  const PasswordDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BigCircleIcon(icon: Icons.check, bg: kSuccessBg, fg: kSuccess),
                  const SizedBox(height: 24),
                  Text('Пароль изменён', style: ts(24, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Теперь можешь войти с новым паролем', style: ts(14, color: kMuted)),
                  const SizedBox(height: 32),
                  BhButton(
                    label: 'Войти',
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
