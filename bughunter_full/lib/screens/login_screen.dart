import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/validators.dart';
import '../core/widgets.dart';
import '../state/auth_state.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'send_code_screen.dart';

/// Вход (экран 11 в Figma).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _passError;
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _passError = null;
      _message = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthState>();
    final mail = _email.text.trim();
    final result = await auth.login(mail, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.needsVerification) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SendCodeScreen(email: mail, purpose: CodePurpose.verifyEmail),
        ),
      );
      return;
    }
    // При успехе AuthGate сам заменит экран входа на главную.
    setState(() {
      _passError = result.passError;
      _message = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  const Align(alignment: Alignment.centerLeft, child: LogoMark()),
                  const SizedBox(height: 20),
                  Text('С возвращением', style: ts(28, weight: FontWeight.w700, spacing: -0.4)),
                  const SizedBox(height: 6),
                  Text('Войди, чтобы продолжить обучение', style: ts(15, color: kMuted)),
                  const SizedBox(height: 28),
                  BhField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _email,
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 16),
                  BhField(
                    label: 'Пароль',
                    hint: '••••••••',
                    controller: _password,
                    password: true,
                    errorText: _passError,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: (v) => (v == null || v.isEmpty) ? 'Введите пароль' : null,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ForgotPasswordScreen(initialEmail: _email.text.trim()),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('Забыли пароль?', style: ts(14, weight: FontWeight.w600, color: kPrimary)),
                      ),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 8),
                    Text(_message!, style: ts(13, color: kDanger)),
                  ],
                  const SizedBox(height: 56),
                  BhButton(label: 'Войти', onPressed: _submit, busy: _busy),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Нет аккаунта? ', style: ts(14, color: kMuted)),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: Text('Зарегистрироваться', style: ts(14, weight: FontWeight.w600, color: kPrimary)),
                      ),
                    ],
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
