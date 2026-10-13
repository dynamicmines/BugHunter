import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content.dart';

/// Контент приложения: языки, уровни, задачи. Лежит в JSON, а не в коде.
class ContentData {
  const ContentData({required this.version, required this.languages});

  final int version;
  final List<Language> languages;
}

class ContentRepository {
  static const String assetPath = 'assets/content/content.json';
  static const String cacheKey = 'content_cache';

  static ContentData parse(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final languages = ((map['languages'] as List<dynamic>?) ?? const [])
        .map((e) => Language.fromJson(e as Map<String, dynamic>))
        .toList();
    return ContentData(version: (map['version'] as int?) ?? 1, languages: languages);
  }

  /// Берёт файл из приложения. Если раньше скачали более новую версию, берёт её.
  static Future<ContentData> load(SharedPreferences prefs) async {
    final bundled = parse(await rootBundle.loadString(assetPath));
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        final fresh = parse(cached);
        if (fresh.version > bundled.version && fresh.languages.isNotEmpty) return fresh;
      } catch (_) {
        // повреждённый кэш игнорируем
      }
    }
    return bundled;
  }
}
