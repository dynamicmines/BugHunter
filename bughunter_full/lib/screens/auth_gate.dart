import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Показывает вход, если пользователя нет, и главную, если он вошёл.
/// Сессия хранится на устройстве, поэтому после перезапуска вход не нужен.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    if (user == null) return const LoginScreen();
    return const HomeScreen();
  }
}
