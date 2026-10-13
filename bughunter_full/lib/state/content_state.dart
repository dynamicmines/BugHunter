import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../data/content_repository.dart';
import '../models/content.dart';

/// Хранит языки, уровни и задачи и умеет скачивать новую версию контента.
class ContentState extends ChangeNotifier {
  ContentState(this._prefs, this._data);

  final SharedPreferences _prefs;
  ContentData _data;
  bool _syncing = false;
  bool _offline = false;

  int get version => _data.version;
  List<Language> get languages => _data.languages;

  /// Идёт загрузка обновлений.
  bool get syncing => _syncing;

  /// Последняя попытка обновить контент не удалась из-за сети.
  bool get offline => _offline;

  Language languageById(String id) {
    for (final l in _data.languages) {
      if (l.id == id) return l;
    }
    return _data.languages.first;
  }

  Level? levelById(String id) {
    for (final lang in _data.languages) {
      for (final lv in lang.levels) {
        if (lv.id == id) return lv;
      }
    }
    return null;
  }

  TaskRef? taskById(String id) {
    for (final lang in _data.languages) {
      for (var i = 0; i < lang.levels.length; i++) {
        final lv = lang.levels[i];
        for (var j = 0; j < lv.tasks.length; j++) {
          if (lv.tasks[j].id == id) return TaskRef(lang, lv, i, lv.tasks[j], j);
        }
      }
    }
    return null;
  }

  /// Язык, к которому относится уровень.
  Language? languageOfLevel(String levelId) {
    for (final lang in _data.languages) {
      for (final lv in lang.levels) {
        if (lv.id == levelId) return lang;
      }
    }
    return null;
  }

  /// Скачивает content.json по адресу kContentUrl. Возвращает сообщение для пользователя.
  Future<String> refresh() async {
    if (kContentUrl.isEmpty) {
      _offline = false;
      notifyListeners();
      return 'Адрес обновлений не задан. Задачи берутся из приложения (версия $version).';
    }
    _syncing = true;
    notifyListeners();
    try {
      final response = await http
          .get(Uri.parse(kContentUrl))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        _offline = false;
        return 'Сервер ответил ошибкой ${response.statusCode}';
      }
      final raw = utf8.decode(response.bodyBytes);
      final fresh = ContentRepository.parse(raw);
      _offline = false;
      if (fresh.version <= _data.version || fresh.languages.isEmpty) {
        return 'У вас уже последняя версия контента ($version)';
      }
      await _prefs.setString(ContentRepository.cacheKey, raw);
      _data = fresh;
      return 'Загружена новая версия контента: ${fresh.version}';
    } catch (e) {
      _offline = true;
      return 'Нет соединения. Проверьте интернет и повторите.';
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }
}
