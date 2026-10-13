import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/validators.dart';
import '../core/widgets.dart';
import '../state/auth_state.dart';
import 'send_code_screen.dart';

/// Регистрация (экран 12 в Figma).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _emailError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthState>();
    final mail = _email.text.trim();
    final result = await auth.register(_name.text, mail, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.ok) {
      setState(() => _emailError = result.emailError);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SendCodeScreen(email: mail, purpose: CodePurpose.verifyEmail),
      ),
    );
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  const Align(alignment: Alignment.centerLeft, child: BhBackButton(plain: true)),
                  const SizedBox(height: 14),
                  Text('Создай аккаунт', style: ts(28, weight: FontWeight.w700, spacing: -0.4)),
                  const SizedBox(height: 6),
                  Text('Начни бесплатно за минуту', style: ts(15, color: kMuted)),
                  const SizedBox(height: 24),
                  BhField(
                    label: 'Имя',
                    hint: 'Бекназар',
                    controller: _name,
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    validator: validateName,
                  ),
                  const SizedBox(height: 16),
                  BhField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _email,
                    icon: Icons.person_outline,
                    errorText: _emailError,
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
                    helper: 'Не короче 8 символов, буквы и цифры',
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 56),
                  BhButton(label: 'Создать аккаунт', onPressed: _submit, busy: _busy),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Уже есть аккаунт? ', style: ts(14, color: kMuted)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Text('Войти', style: ts(14, weight: FontWeight.w600, color: kPrimary)),
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
