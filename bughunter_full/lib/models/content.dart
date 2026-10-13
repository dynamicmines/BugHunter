/// Блок разбора темы: абзац текста или пример кода.
class TheoryBlock {
  const TheoryBlock({required this.isCode, required this.text});

  final bool isCode;
  final String text;

  factory TheoryBlock.fromJson(Map<String, dynamic> j) => TheoryBlock(
        isCode: j['type'] == 'code',
        text: j['text'] as String,
      );
}

enum TaskType { find, choice }

/// Одна задача уровня: найти строку с ошибкой или выбрать верный ответ.
class Task {
  const Task({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.explanation,
    required this.hint,
    required this.retryHint,
    required this.difficulty,
    required this.minutes,
    this.code = '',
    this.bugLine = 0,
    this.fix = '',
    this.options = const [],
    this.answer = 0,
  });

  final String id;
  final TaskType type;
  final String title;
  final String description;
  final String explanation;
  final String hint;

  /// Подсказка, которая показывается после неверного ответа.
  final String retryHint;

  /// 0 лёгкая, 1 средняя, 2 сложная.
  final int difficulty;
  final int minutes;
  final String code;

  /// find: номер строки с ошибкой (с нуля) и как она должна выглядеть.
  final int bugLine;
  final String fix;

  /// choice: варианты и номер верного.
  final List<String> options;
  final int answer;

  List<String> get lines => code.isEmpty ? const [] : code.split('\n');

  String get buggyLine => (bugLine >= 0 && bugLine < lines.length) ? lines[bugLine] : '';

  /// Очки за первое верное решение без ошибок: 10, 20 или 30.
  int get baseXp => const [10, 20, 30][difficulty.clamp(0, 2)];

  factory Task.fromJson(Map<String, dynamic> j) {
    final isFind = j['type'] == 'find';
    return Task(
      id: j['id'] as String,
      type: isFind ? TaskType.find : TaskType.choice,
      title: j['title'] as String,
      description: (j['description'] as String?) ?? '',
      explanation: (j['explanation'] as String?) ?? '',
      hint: (j['hint'] as String?) ?? '',
      retryHint: (j['retryHint'] as String?) ?? '',
      difficulty: (j['difficulty'] as int?) ?? 0,
      minutes: (j['minutes'] as int?) ?? 2,
      code: (j['code'] as String?) ?? '',
      bugLine: (j['bugLine'] as int?) ?? 0,
      fix: (j['fix'] as String?) ?? '',
      options: ((j['options'] as List<dynamic>?) ?? const []).map((e) => e as String).toList(),
      answer: (j['answer'] as int?) ?? 0,
    );
  }
}

/// Уровень (тема): разбор и список задач.
class Level {
  const Level({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.intro,
    required this.theory,
    required this.tasks,
  });

  final String id;
  final String title;
  final String subtitle;
  final String intro;
  final List<TheoryBlock> theory;
  final List<Task> tasks;

  factory Level.fromJson(Map<String, dynamic> j) => Level(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: (j['subtitle'] as String?) ?? '',
        intro: (j['intro'] as String?) ?? '',
        theory: ((j['theory'] as List<dynamic>?) ?? const [])
            .map((e) => TheoryBlock.fromJson(e as Map<String, dynamic>))
            .toList(),
        tasks: ((j['tasks'] as List<dynamic>?) ?? const [])
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Язык программирования: набор уровней.
class Language {
  const Language({
    required this.id,
    required this.title,
    required this.description,
    required this.levels,
  });

  final String id;
  final String title;
  final String description;
  final List<Level> levels;

  factory Language.fromJson(Map<String, dynamic> j) => Language(
        id: j['id'] as String,
        title: j['title'] as String,
        description: (j['description'] as String?) ?? '',
        levels: ((j['levels'] as List<dynamic>?) ?? const [])
            .map((e) => Level.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Задача вместе с её уровнем и языком.
class TaskRef {
  const TaskRef(this.language, this.level, this.levelIndex, this.task, this.taskIndex);

  final Language language;
  final Level level;
  final int levelIndex;
  final Task task;
  final int taskIndex;

  /// Подпись вида «Python · Функции · Задача 4 из 10».
  String get meta => '${language.title} · ${level.title} · Задача ${taskIndex + 1} из ${level.tasks.length}';
}
