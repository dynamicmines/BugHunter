import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content.dart';
import '../models/result.dart';
import 'auth_state.dart';
import 'content_state.dart';

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
}

/// Уровни, которые считаются «про циклы» для достижения «Мастер циклов».
const Set<String> kLoopLevelIds = {'py_l2', 'js_l2', 'dart_l1'};

/// Прогресс текущего пользователя: решённые задачи, очки, серия дней, выбранный язык.
///
/// Правила:
///  - очки за первое верное решение: лёгкая 10, средняя 20, сложная 30;
///  - каждый неверный ответ до верного снимает 5 очков, но не меньше 5;
///  - повторное решение уже решённой задачи очков не даёт;
///  - задача открывается после решения предыдущей, уровень после прохождения предыдущего;
///  - серия дней: сколько дней подряд решалась хотя бы одна задача
///    (серия не сгорает, пока не закончился сегодняшний день).
class ProgressState extends ChangeNotifier {
  ProgressState(this._prefs, this._auth, this._content) {
    _auth.addListener(_onAuth);
    _content.addListener(notifyListeners);
    _load();
  }

  final SharedPreferences _prefs;
  final AuthState _auth;
  final ContentState _content;
  String? _uid;
  Map<String, TaskResult> _results = {};
  Set<String> _theory = {};
  String _langId = '';

  @override
  void dispose() {
    _auth.removeListener(_onAuth);
    _content.removeListener(notifyListeners);
    super.dispose();
  }

  void _onAuth() {
    if (_auth.user?.id != _uid) {
      _load();
      notifyListeners();
    }
  }

  void _load() {
    _uid = _auth.user?.id;
    _results = {};
    _theory = {};
    _langId = '';
    final uid = _uid;
    if (uid == null) return;
    try {
      final raw = _prefs.getString('results_$uid');
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach((k, v) {
          _results[k] = TaskResult.fromJson(v as Map<String, dynamic>);
        });
      }
      final rawTheory = _prefs.getString('theory_$uid');
      if (rawTheory != null) {
        _theory = (jsonDecode(rawTheory) as List<dynamic>).map((e) => e as String).toSet();
      }
    } catch (_) {
      _results = {};
      _theory = {};
    }
    _langId = _prefs.getString('lang_$uid') ?? '';
  }

  Future<void> _saveResults() {
    final uid = _uid;
    if (uid == null) return Future.value();
    final map = _results.map((k, v) => MapEntry(k, v.toJson()));
    return _prefs.setString('results_$uid', jsonEncode(map));
  }

  Future<void> _saveTheory() {
    final uid = _uid;
    if (uid == null) return Future.value();
    return _prefs.setString('theory_$uid', jsonEncode(_theory.toList()));
  }

  // ---------- язык ----------

  List<Language> get languages => _content.languages;

  Language get language {
    for (final l in languages) {
      if (l.id == _langId) return l;
    }
    for (final l in languages) {
      if (l.id == 'python') return l;
    }
    return languages.first;
  }

  Future<void> setLanguage(String id) async {
    _langId = id;
    final uid = _uid;
    if (uid != null) await _prefs.setString('lang_$uid', id);
    notifyListeners();
  }

  // ---------- задачи и уровни ----------

  bool isSolved(String taskId) => _results[taskId]?.solved ?? false;

  TaskResult? resultOf(String taskId) => _results[taskId];

  int solvedInLevel(Level level) {
    var n = 0;
    for (final t in level.tasks) {
      if (isSolved(t.id)) n++;
    }
    return n;
  }

  bool levelDone(Level level) => level.tasks.isNotEmpty && solvedInLevel(level) == level.tasks.length;

  bool levelUnlocked(Language lang, int index) {
    if (index <= 0) return true;
    return levelDone(lang.levels[index - 1]);
  }

  bool taskUnlocked(Level level, int index) {
    if (index <= 0) return true;
    return isSolved(level.tasks[index - 1].id) || isSolved(level.tasks[index].id);
  }

  /// Номер первого непройденного уровня выбранного языка (с нуля).
  /// Если всё пройдено, последний уровень.
  int get currentLevelIndex {
    final levels = language.levels;
    for (var i = 0; i < levels.length; i++) {
      if (!levelDone(levels[i])) return i;
    }
    return levels.isEmpty ? 0 : levels.length - 1;
  }

  Level get currentLevel => language.levels[currentLevelIndex];

  /// Все уровни выбранного языка пройдены.
  bool get allDone {
    final levels = language.levels;
    if (levels.isEmpty) return false;
    for (final lv in levels) {
      if (!levelDone(lv)) return false;
    }
    return true;
  }

  int solvedCountIn(Language lang) {
    var n = 0;
    for (final lv in lang.levels) {
      n += solvedInLevel(lv);
    }
    return n;
  }

  int get solvedInLanguage => solvedCountIn(language);

  /// Следующая нерешённая задача в выбранном языке или null, если всё решено.
  TaskRef? get nextTask {
    final lang = language;
    for (var i = 0; i < lang.levels.length; i++) {
      final lv = lang.levels[i];
      for (var j = 0; j < lv.tasks.length; j++) {
        if (!isSolved(lv.tasks[j].id)) return TaskRef(lang, lv, i, lv.tasks[j], j);
      }
    }
    return null;
  }

  // ---------- статистика ----------

  int get solvedCount {
    var n = 0;
    for (final r in _results.values) {
      if (r.solved) n++;
    }
    return n;
  }

  int get xp {
    var n = 0;
    for (final r in _results.values) {
      n += r.xp;
    }
    return n;
  }

  /// Процент верных ответов среди всех проверок.
  int get accuracy {
    var wrong = 0;
    for (final r in _results.values) {
      wrong += r.wrong;
    }
    final solved = solvedCount;
    final attempts = solved + wrong;
    if (attempts == 0) return 0;
    return (solved * 100 / attempts).round();
  }

  static int _dayNumber(DateTime d) => DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

  int get streak {
    final days = <int>{};
    for (final r in _results.values) {
      final t = r.solvedAt;
      if (t == null) continue;
      days.add(_dayNumber(DateTime.fromMillisecondsSinceEpoch(t)));
    }
    var day = _dayNumber(DateTime.now());
    if (!days.contains(day)) day -= 1;
    var n = 0;
    while (days.contains(day - n)) {
      n++;
    }
    return n;
  }

  bool theoryOpened(String levelId) => _theory.contains(levelId);

  Future<void> markTheoryOpened(String levelId) async {
    if (_theory.add(levelId)) {
      await _saveTheory();
      notifyListeners();
    }
  }

  // ---------- проверка ответа ----------

  /// Очки за решение: база по сложности минус 5 за каждую ошибку, но не меньше 5.
  static int calcXp(int difficulty, int wrong) {
    final base = const [10, 20, 30][difficulty.clamp(0, 2)];
    final value = base - 5 * wrong;
    return value < 5 ? 5 : value;
  }

  /// Проверяет ответ и сохраняет результат.
  /// [picked] это номер строки (find) или номер варианта (choice).
  Future<CheckOutcome> check(Task task, int picked) async {
    final correct = task.type == TaskType.find ? picked == task.bugLine : picked == task.answer;
    final old = _results[task.id] ?? const TaskResult();
    if (old.solved) {
      return CheckOutcome(correct: correct, xp: 0, firstSolve: false, levelCompleted: false);
    }
    if (!correct) {
      _results[task.id] = old.copyWith(wrong: old.wrong + 1);
      await _saveResults();
      notifyListeners();
      return const CheckOutcome(correct: false, xp: 0, firstSolve: false, levelCompleted: false);
    }
    final gained = calcXp(task.difficulty, old.wrong);
    _results[task.id] = TaskResult(
      solved: true,
      wrong: old.wrong,
      xp: gained,
      solvedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _saveResults();
    final ref = _content.taskById(task.id);
    final completed = ref != null && levelDone(ref.level);
    notifyListeners();
    return CheckOutcome(correct: true, xp: gained, firstSolve: true, levelCompleted: completed);
  }

  Future<void> resetProgress() async {
    _results = {};
    _theory = {};
    await _saveResults();
    await _saveTheory();
    notifyListeners();
  }

  // ---------- достижения ----------

  List<Achievement> get achievements {
    final solved = solvedCount;
    var flawless = 0;
    for (final r in _results.values) {
      if (r.solved && r.wrong == 0) flawless++;
    }
    var loops = 0;
    var anyLevelDone = false;
    var languagesWithSolved = 0;
    for (final lang in languages) {
      var inLang = 0;
      for (final lv in lang.levels) {
        final n = solvedInLevel(lv);
        inLang += n;
        if (kLoopLevelIds.contains(lv.id)) loops += n;
        if (levelDone(lv)) anyLevelDone = true;
      }
      if (inLang > 0) languagesWithSolved++;
    }
    return [
      Achievement(
        id: 'first',
        title: 'Первая ошибка найдена',
        description: 'Решена первая задача',
        icon: Icons.workspace_premium_outlined,
        unlocked: solved >= 1,
      ),
      Achievement(
        id: 'streak5',
        title: 'Серия 5 дней',
        description: 'Занимайся каждый день',
        icon: Icons.bolt,
        unlocked: streak >= 5,
      ),
      Achievement(
        id: 'loops',
        title: 'Мастер циклов',
        description: 'Реши 10 задач на циклы',
        icon: Icons.track_changes,
        unlocked: loops >= 10,
      ),
      Achievement(
        id: 'flawless',
        title: 'Без единой ошибки',
        description: 'Реши 5 задач с первой попытки',
        icon: Icons.check_circle_outline,
        unlocked: flawless >= 5,
      ),
      Achievement(
        id: 'level',
        title: 'Уровень пройден',
        description: 'Пройди любой уровень до конца',
        icon: Icons.flag_outlined,
        unlocked: anyLevelDone,
      ),
      Achievement(
        id: 'theory',
        title: 'Любознательный',
        description: 'Открой разбор темы',
        icon: Icons.menu_book_outlined,
        unlocked: _theory.isNotEmpty,
      ),
      Achievement(
        id: 'poly',
        title: 'Полиглот',
        description: 'Реши задачи на двух языках',
        icon: Icons.translate,
        unlocked: languagesWithSolved >= 2,
      ),
      Achievement(
        id: 'xp100',
        title: 'Сто очков',
        description: 'Набери 100 XP',
        icon: Icons.emoji_events_outlined,
        unlocked: xp >= 100,
      ),
    ];
  }
}
