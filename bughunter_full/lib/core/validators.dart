String? validateName(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Введите имя';
  if (s.length < 2) return 'Имя слишком короткое';
  if (s.length > 30) return 'Имя не длиннее 30 символов';
  return null;
}

String? validateEmail(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Введите почту';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
    return 'Почта введена неверно';
  }
  return null;
}

String? validatePassword(String? v) {
  final s = v ?? '';
  if (s.isEmpty) return 'Введите пароль';
  if (s.length < 8) return 'Пароль не короче восьми символов';
  if (!RegExp(r'[A-Za-zА-Яа-яЁё]').hasMatch(s) || !RegExp(r'[0-9]').hasMatch(s)) {
    return 'Нужны и буквы, и цифры';
  }
  return null;
}
