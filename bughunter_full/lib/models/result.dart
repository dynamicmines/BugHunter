/// Результат пользователя по одной задаче.
class TaskResult {
  const TaskResult({this.solved = false, this.wrong = 0, this.xp = 0, this.solvedAt});

  final bool solved;

  /// Сколько раз ответили неверно до первого верного решения.
  final int wrong;

  /// Полученные очки (0, пока не решено).
  final int xp;
  final int? solvedAt;

  TaskResult copyWith({bool? solved, int? wrong, int? xp, int? solvedAt}) {
    return TaskResult(
      solved: solved ?? this.solved,
      wrong: wrong ?? this.wrong,
      xp: xp ?? this.xp,
      solvedAt: solvedAt ?? this.solvedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'solved': solved,
        'wrong': wrong,
        'xp': xp,
        'solvedAt': solvedAt,
      };

  factory TaskResult.fromJson(Map<String, dynamic> j) => TaskResult(
        solved: (j['solved'] as bool?) ?? false,
        wrong: (j['wrong'] as int?) ?? 0,
        xp: (j['xp'] as int?) ?? 0,
        solvedAt: j['solvedAt'] as int?,
      );
}

/// Итог проверки ответа.
class CheckOutcome {
  const CheckOutcome({
    required this.correct,
    required this.xp,
    required this.firstSolve,
    required this.levelCompleted,
  });

  final bool correct;

  /// Очки, начисленные за эту проверку (0 при неверном ответе и при повторном решении).
  final int xp;
  final bool firstSolve;

  /// Эта задача была последней нерешённой в уровне.
  final bool levelCompleted;
}
