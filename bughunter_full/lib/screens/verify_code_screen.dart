import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/auth_state.dart';
import 'new_password_screen.dart';

/// Ввод 6-значного кода из письма (экран 14 в Figma).
/// Подтверждает почту при регистрации и входе или открывает смену пароля.
class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key, required this.email, required this.purpose});

  final String email;
  final CodePurpose purpose;

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _ticker;
  int _wait = kResendSeconds;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _wait = kResendSeconds;
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_wait > 0) _wait--;
        if (_wait == 0) t.cancel();
      });
    });
  }

  Future<void> _submit() async {
    final code = _controller.text;
    if (code.length != kCodeLength || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthState>();
    final result = await auth.verifyCode(widget.email, widget.purpose, code);
    if (!mounted) return;
    if (!result.ok) {
      _controller.clear();
      setState(() {
        _busy = false;
        _error = result.codeError ?? result.message;
      });
      return;
    }
    if (widget.purpose == CodePurpose.verifyEmail) {
      // Пользователь вошёл, AuthGate под этим экраном уже показывает главную.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => NewPasswordScreen(email: widget.email)),
      );
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthState>();
    final result = await auth.resendCode(widget.email, widget.purpose);
    if (!mounted) return;
    if (!result.ok) {
      showSnack(context, result.message ?? 'Не удалось отправить код');
      return;
    }
    _controller.clear();
    setState(() => _error = null);
    _startTicker();
    showSnack(context, 'Код отправлен повторно');
  }

  void _fillDemo(String code) {
    _controller.text = code;
    _controller.selection = TextSelection.collapsed(offset: code.length);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final demo = auth.demoCode(widget.email, widget.purpose);
    final text = _controller.text;
    final hasError = _error != null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                const Align(alignment: Alignment.centerLeft, child: BhBackButton(plain: true)),
                const SizedBox(height: 14),
                Text('Введи код', style: ts(28, weight: FontWeight.w700, spacing: -0.4)),
                const SizedBox(height: 6),
                Text(
                  'Мы отправили $kCodeLength-значный код на ${widget.email}',
                  style: ts(15, color: kMuted, height: 1.3),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 58,
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 0; i < kCodeLength; i++)
                            _CodeBox(
                              char: i < text.length ? text[i] : '',
                              focused: _focus.hasFocus && i == (text.length < kCodeLength ? text.length : kCodeLength - 1),
                              error: hasError,
                            ),
                        ],
                      ),
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0,
                          child: TextField(
                            controller: _controller,
                            focusNode: _focus,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            enableInteractiveSelection: false,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(kCodeLength),
                            ],
                            onChanged: (_) {
                              if (_error != null) setState(() => _error = null);
                            },
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: ts(13, color: kDanger)),
                ],
                if (demo != null) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _fillDemo(demo),
                    child: HintBox('Демо-режим: письма пока не отправляются. Твой код: $demo. Нажми, чтобы подставить.'),
                  ),
                ],
                const SizedBox(height: 32),
                BhButton(
                  label: 'Подтвердить',
                  onPressed: text.length == kCodeLength ? _submit : null,
                  busy: _busy,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Не пришёл код? ', style: ts(14, color: kMuted)),
                    if (_wait > 0)
                      Text('Повторно через $_wait с', style: ts(14, weight: FontWeight.w600, color: kPlaceholder))
                    else
                      GestureDetector(
                        onTap: _resend,
                        child: Text('Отправить повторно', style: ts(14, weight: FontWeight.w600, color: kPrimary)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.char, required this.focused, required this.error});

  final String char;
  final bool focused;
  final bool error;

  @override
  Widget build(BuildContext context) {
    Color border = kLine;
    double width = 1;
    if (error) {
      border = kDanger;
      width = 1.5;
    } else if (focused) {
      border = kPrimary;
      width = 2;
    }
    return Container(
      width: 54,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: width),
      ),
      child: Text(char, style: ts(22, weight: FontWeight.w700)),
    );
  }
}
