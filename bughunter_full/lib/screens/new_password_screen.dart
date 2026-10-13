import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/validators.dart';
import '../core/widgets.dart';
import '../state/auth_state.dart';
import 'password_done_screen.dart';

/// Новый пароль (экран 17 в Figma).
class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _message = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthState>();
    final result = await auth.setNewPassword(widget.email, _password.text);
    if (!mounted) return;
    if (!result.ok) {
      setState(() {
        _busy = false;
        _message = result.message;
      });
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const PasswordDoneScreen()),
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
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                children: [
                  Text('Новый пароль', style: ts(28, weight: FontWeight.w700, spacing: -0.4)),
                  const SizedBox(height: 6),
                  Text('Придумай новый пароль для входа', style: ts(15, color: kMuted)),
                  const SizedBox(height: 24),
                  BhField(
                    label: 'Новый пароль',
                    hint: '••••••••',
                    controller: _password,
                    password: true,
                    helper: 'Не короче 8 символов, буквы и цифры',
                    textInputAction: TextInputAction.next,
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 16),
                  BhField(
                    label: 'Повтори пароль',
                    hint: '••••••••',
                    controller: _password2,
                    password: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: (v) => v != _password.text ? 'Пароли не совпадают' : null,
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(_message!, style: ts(13, color: kDanger)),
                  ],
                  const SizedBox(height: 56),
                  BhButton(label: 'Сохранить пароль', onPressed: _submit, busy: _busy),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
