import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/validators.dart';
import '../core/widgets.dart';
import '../state/auth_state.dart';

/// Смена пароля из настроек. В Figma такого экрана нет, сделан в той же вёрстке, что «Новый пароль».
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _new2 = TextEditingController();
  String? _oldError;
  bool _busy = false;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _new2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _oldError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthState>();
    final result = await auth.changePassword(_old.text, _new.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.ok) {
      setState(() => _oldError = result.passError ?? result.message);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Пароль изменён')));
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
                  Text('Смена пароля', style: ts(28, weight: FontWeight.w700, spacing: -0.4)),
                  const SizedBox(height: 6),
                  Text('Введи текущий пароль и придумай новый', style: ts(15, color: kMuted)),
                  const SizedBox(height: 24),
                  BhField(
                    label: 'Текущий пароль',
                    hint: '••••••••',
                    controller: _old,
                    password: true,
                    errorText: _oldError,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.isEmpty) ? 'Введите текущий пароль' : null,
                  ),
                  const SizedBox(height: 16),
                  BhField(
                    label: 'Новый пароль',
                    hint: '••••••••',
                    controller: _new,
                    password: true,
                    helper: 'Не короче 8 символов, буквы и цифры',
                    textInputAction: TextInputAction.next,
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 16),
                  BhField(
                    label: 'Повтори новый пароль',
                    hint: '••••••••',
                    controller: _new2,
                    password: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: (v) => v != _new.text ? 'Пароли не совпадают' : null,
                  ),
                  const SizedBox(height: 40),
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
