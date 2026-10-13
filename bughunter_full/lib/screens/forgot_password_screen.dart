import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/validators.dart';
import '../core/widgets.dart';
import '../state/auth_state.dart';
import 'send_code_screen.dart';

/// Забыли пароль (экран 15 в Figma): вводим почту, получаем код.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(text: widget.initialEmail);
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthState>();
    final mail = _email.text.trim();
    await auth.requestReset(mail);
    if (!mounted) return;
    setState(() => _busy = false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SendCodeScreen(email: mail, purpose: CodePurpose.resetPassword),
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
                  Text('Забыли пароль?', style: ts(28, weight: FontWeight.w700, spacing: -0.4)),
                  const SizedBox(height: 6),
                  Text('Введи почту — пришлём код для восстановления', style: ts(15, color: kMuted)),
                  const SizedBox(height: 24),
                  BhField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _email,
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 56),
                  BhButton(label: 'Отправить код', onPressed: _submit, busy: _busy),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
