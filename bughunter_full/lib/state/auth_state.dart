import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/app_user.dart';

class AuthResult {
  const AuthResult({
    this.emailError,
    this.passError,
    this.codeError,
    this.message,
    this.needsVerification = false,
  });

  const AuthResult.ok()
      : emailError = null,
        passError = null,
        codeError = null,
        message = null,
        needsVerification = false;

  final String? emailError;
  final String? passError;
  final String? codeError;
  final String? message;

  /// Пароль верный, но почта не подтверждена: нужно ввести код из письма.
  final bool needsVerification;

  bool get ok =>
      emailError == null &&
      passError == null &&
      codeError == null &&
      message == null &&
      !needsVerification;
}

/// Для чего выдан код из письма.
enum CodePurpose { verifyEmail, resetPassword }

class _PendingCode {
  _PendingCode(this.code, this.expires, this.sentAt);

  final String code;
  final DateTime expires;
  final DateTime sentAt;
  int attempts = 0;
}

/// Авторизация. Пользователи и сессия хранятся на устройстве.
/// Пароль в открытом виде не сохраняется: хранится соль и многократный SHA-256.
///
/// Коды из писем живут в памяти и действуют [kCodeMinutes] минут. Пока нет сервера,
/// письма не отправляются, а код показывается на экране (см. [kDemoMail]).
/// Чтобы подключить настоящую почту, замените тело [_deliver] вызовом вашего API.
class AuthState extends ChangeNotifier {
  AuthState(this._prefs) {
    _restore();
  }

  static const int maxFailed = 5;
  static const int lockSeconds = 30;

  final SharedPreferences _prefs;
  List<AppUser> _users = [];
  AppUser? _user;
  int _failed = 0;
  DateTime? _lockedUntil;
  final Map<String, _PendingCode> _pending = {};
  final Map<String, DateTime> _resetAllowed = {};

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  void _restore() {
    final raw = _prefs.getString('users');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _users = list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _users = [];
      }
    }
    final sid = _prefs.getString('session');
    if (sid != null) {
      for (final u in _users) {
        if (u.id == sid && u.verified) _user = u;
      }
    }
  }

  Future<void> _saveUsers() {
    return _prefs.setString('users', jsonEncode(_users.map((u) => u.toJson()).toList()));
  }

  static String _newSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _hash(String salt, String password) {
    var h = '$salt:$password';
    for (var i = 0; i < 2000; i++) {
      h = sha256.convert(utf8.encode(h)).toString();
    }
    return h;
  }

  static String _newCode() {
    final r = Random.secure();
    return List<String>.generate(kCodeLength, (_) => '${r.nextInt(10)}').join();
  }

  static String _key(String email, CodePurpose purpose) => '${purpose.name}:$email';

  static String _normEmail(String email) => email.trim().toLowerCase();

  AppUser? _findByEmail(String mail) {
    for (final u in _users) {
      if (u.email == mail) return u;
    }
    return null;
  }

  /// Отправка письма с кодом. Сейчас письмо не уходит, код просто запоминается.
  void _deliver(String email, CodePurpose purpose, String code) {
    // Здесь будет вызов почтового сервиса или своего API.
  }

  void _issueCode(String email, CodePurpose purpose) {
    final now = DateTime.now();
    final code = _newCode();
    _pending[_key(email, purpose)] = _PendingCode(
      code,
      now.add(const Duration(minutes: kCodeMinutes)),
      now,
    );
    _deliver(email, purpose, code);
  }

  /// Код для показа на экране в демо-режиме. В боевом режиме всегда null.
  String? demoCode(String email, CodePurpose purpose) {
    if (!kDemoMail) return null;
    final p = _pending[_key(_normEmail(email), purpose)];
    if (p == null || p.expires.isBefore(DateTime.now())) return null;
    return p.code;
  }

  Future<AuthResult> register(String name, String email, String password) async {
    final mail = _normEmail(email);
    final existing = _findByEmail(mail);
    if (existing != null && existing.verified) {
      return const AuthResult(emailError: 'Такая почта уже зарегистрирована');
    }
    if (existing != null) {
      // Регистрация не была закончена: обновляем данные и шлём код заново.
      final salt = _newSalt();
      existing.name = name.trim();
      existing.salt = salt;
      existing.hash = _hash(salt, password);
    } else {
      final salt = _newSalt();
      final now = DateTime.now();
      _users.add(AppUser(
        id: now.microsecondsSinceEpoch.toString(),
        name: name.trim(),
        email: mail,
        salt: salt,
        hash: _hash(salt, password),
        createdAt: now.millisecondsSinceEpoch,
      ));
    }
    await _saveUsers();
    _issueCode(mail, CodePurpose.verifyEmail);
    return const AuthResult.ok();
  }

  Future<AuthResult> login(String email, String password) async {
    final locked = _lockedUntil;
    if (locked != null && locked.isAfter(DateTime.now())) {
      final sec = locked.difference(DateTime.now()).inSeconds + 1;
      return AuthResult(message: 'Слишком много попыток. Подождите $sec с.');
    }
    final mail = _normEmail(email);
    final u = _findByEmail(mail);
    // Одинаковое сообщение для «нет такой почты» и «неверный пароль»,
    // чтобы нельзя было подбирать, кто зарегистрирован.
    if (u == null || u.hash != _hash(u.salt, password)) {
      _failed++;
      if (_failed >= maxFailed) {
        _failed = 0;
        _lockedUntil = DateTime.now().add(const Duration(seconds: lockSeconds));
        return const AuthResult(passError: 'Неверная почта или пароль. Вход заблокирован на 30 секунд');
      }
      return AuthResult(passError: 'Неверная почта или пароль. Осталось попыток: ${maxFailed - _failed}');
    }
    _failed = 0;
    if (!u.verified) {
      _issueCode(mail, CodePurpose.verifyEmail);
      return const AuthResult(needsVerification: true);
    }
    _user = u;
    await _prefs.setString('session', u.id);
    notifyListeners();
    return const AuthResult.ok();
  }

  /// Проверка кода из письма. Для подтверждения почты ещё и входит в аккаунт.
  Future<AuthResult> verifyCode(String email, CodePurpose purpose, String code) async {
    final mail = _normEmail(email);
    final key = _key(mail, purpose);
    final p = _pending[key];
    if (p == null) {
      return const AuthResult(codeError: 'Код не найден. Запросите новый');
    }
    if (p.expires.isBefore(DateTime.now())) {
      _pending.remove(key);
      return const AuthResult(codeError: 'Срок действия кода истёк. Запросите новый');
    }
    if (p.code != code.trim()) {
      p.attempts++;
      if (p.attempts >= maxFailed) {
        _pending.remove(key);
        return const AuthResult(codeError: 'Слишком много неверных попыток. Запросите новый код');
      }
      return AuthResult(codeError: 'Неверный код. Осталось попыток: ${maxFailed - p.attempts}');
    }
    _pending.remove(key);
    final u = _findByEmail(mail);
    if (u == null) {
      return const AuthResult(codeError: 'Аккаунт не найден');
    }
    if (purpose == CodePurpose.verifyEmail) {
      u.verified = true;
      await _saveUsers();
      _user = u;
      await _prefs.setString('session', u.id);
      notifyListeners();
    } else {
      _resetAllowed[mail] = DateTime.now().add(const Duration(minutes: kCodeMinutes));
    }
    return const AuthResult.ok();
  }

  /// Повторная отправка кода. Не чаще раза в [kResendSeconds] секунд.
  Future<AuthResult> resendCode(String email, CodePurpose purpose) async {
    final mail = _normEmail(email);
    final p = _pending[_key(mail, purpose)];
    if (p != null) {
      final wait = kResendSeconds - DateTime.now().difference(p.sentAt).inSeconds;
      if (wait > 0) {
        return AuthResult(message: 'Повторная отправка через $wait с');
      }
    }
    if (_findByEmail(mail) != null) _issueCode(mail, purpose);
    return const AuthResult.ok();
  }

  /// Запрос на сброс пароля. Ответ одинаковый для любой почты.
  Future<AuthResult> requestReset(String email) async {
    final mail = _normEmail(email);
    if (_findByEmail(mail) != null) _issueCode(mail, CodePurpose.resetPassword);
    return const AuthResult.ok();
  }

  /// Новый пароль после подтверждения кода.
  Future<AuthResult> setNewPassword(String email, String newPassword) async {
    final mail = _normEmail(email);
    final until = _resetAllowed[mail];
    final u = _findByEmail(mail);
    if (u == null || until == null || until.isBefore(DateTime.now())) {
      return const AuthResult(message: 'Время на смену пароля истекло. Начните заново');
    }
    final salt = _newSalt();
    u.salt = salt;
    u.hash = _hash(salt, newPassword);
    u.verified = true;
    _resetAllowed.remove(mail);
    await _saveUsers();
    return const AuthResult.ok();
  }

  Future<void> logout() async {
    _user = null;
    await _prefs.remove('session');
    notifyListeners();
  }

  Future<AuthResult> updateName(String name) async {
    final u = _user;
    if (u == null) return const AuthResult(message: 'Нет активного пользователя');
    u.name = name.trim();
    await _saveUsers();
    notifyListeners();
    return const AuthResult.ok();
  }

  Future<AuthResult> changePassword(String oldPassword, String newPassword) async {
    final u = _user;
    if (u == null) return const AuthResult(message: 'Нет активного пользователя');
    if (u.hash != _hash(u.salt, oldPassword)) {
      return const AuthResult(passError: 'Неверный текущий пароль');
    }
    final salt = _newSalt();
    u.salt = salt;
    u.hash = _hash(salt, newPassword);
    await _saveUsers();
    notifyListeners();
    return const AuthResult.ok();
  }

  Future<AuthResult> deleteAccount(String password) async {
    final u = _user;
    if (u == null) return const AuthResult(message: 'Нет активного пользователя');
    if (u.hash != _hash(u.salt, password)) {
      return const AuthResult(passError: 'Неверный пароль');
    }
    _users.removeWhere((x) => x.id == u.id);
    await _saveUsers();
    await _prefs.remove('results_${u.id}');
    await _prefs.remove('lang_${u.id}');
    await _prefs.remove('theory_${u.id}');
    await logout();
    return const AuthResult.ok();
  }
}
