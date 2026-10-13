import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/content.dart';
import '../models/result.dart';

/// Что делать после экрана результата.
enum ResultAction { next, levels, back, retry }

/// Результат проверки (экраны 06 и 07 в Figma).
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.ref,
    required this.picked,
    required this.outcome,
  });

  final TaskRef ref;
  final int picked;
  final CheckOutcome outcome;

  void _close(BuildContext context, ResultAction action) {
    Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.task;
    final ok = outcome.correct;
    final isFind = task.type == TaskType.find;

    return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: BhHeader(
                      title: 'Результат',
                      onBack: () => _close(context, ResultAction.back),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      children: ok ? _correct(task, isFind) : _wrong(task, isFind),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: ok
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BhButton(
                                label: 'Продолжить',
                                trailing: Icons.arrow_forward,
                                onPressed: () => _close(context, ResultAction.next),
                              ),
                              const SizedBox(height: 12),
                              BhButton(
                                label: 'Смотреть уровни',
                                kind: BhButtonKind.secondary,
                                onPressed: () => _close(context, ResultAction.levels),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BhButton(
                                label: 'Повторить',
                                onPressed: () => _close(context, ResultAction.retry),
                              ),
                              const SizedBox(height: 12),
                              BhButton(
                                label: 'Вернуться',
                                kind: BhButtonKind.secondary,
                                onPressed: () => _close(context, ResultAction.back),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  List<Widget> _correct(Task task, bool isFind) {
    final subtitle = isFind ? 'Ошибка была в строке ${task.bugLine + 1}' : 'Верный ответ найден';
    return [
      const Center(
        child: BigCircleIcon(icon: Icons.check, bg: kSuccessBg, fg: kSuccess),
      ),
      const SizedBox(height: 20),
      Center(child: Text('Верно!', style: ts(28, weight: FontWeight.w700, spacing: -0.4))),
      const SizedBox(height: 6),
      Center(child: Text(subtitle, style: ts(15, color: kMuted))),
      const SizedBox(height: 24),
      if (isFind) _FixCard(before: task.buggyLine.trim(), after: task.fix.trim()),
      if (!isFind)
        BhCard(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Правильный ответ', style: ts(12, weight: FontWeight.w600, color: kSuccess)),
                const SizedBox(height: 6),
                Text(
                  task.answer >= 0 && task.answer < task.options.length ? task.options[task.answer] : '',
                  style: ts(15, weight: FontWeight.w500, height: 1.35),
                ),
              ],
            ),
          ),
        ),
      if (task.explanation.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('Почему так', style: ts(16, weight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(task.explanation, style: ts(14, color: kMuted, height: 1.45)),
      ],
      const SizedBox(height: 20),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (outcome.xp > 0)
            _Pill(text: '+${outcome.xp} XP', bg: kPrimaryTint, fg: kPrimary)
          else
            const _Pill(text: 'Уже решено, XP не начисляется', bg: kLockedTile, fg: kMuted),
          if (outcome.levelCompleted)
            const _Pill(text: 'Уровень пройден', bg: kSuccessBg, fg: kSuccess),
        ],
      ),
    ];
  }

  List<Widget> _wrong(Task task, bool isFind) {
    return [
      const Center(
        child: BigCircleIcon(icon: Icons.close, bg: kDangerBg, fg: kDanger),
      ),
      const SizedBox(height: 20),
      Center(child: Text('Не совсем', style: ts(28, weight: FontWeight.w700, spacing: -0.4))),
      const SizedBox(height: 6),
      Center(
        child: Text(
          isFind ? 'Это не та строка. Попробуй ещё раз.' : 'Это неверный ответ. Попробуй ещё раз.',
          style: ts(15, color: kMuted),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 24),
      if (task.retryHint.isNotEmpty) HintBox(task.retryHint),
    ];
  }
}

/// Карточка «Было / Стало» из экрана 06.
class _FixCard extends StatelessWidget {
  const _FixCard({required this.before, required this.after});

  final String before;
  final String after;

  @override
  Widget build(BuildContext context) {
    return BhCard(
      padding: const EdgeInsets.all(12),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line('Было', before, kDangerBg, kDanger),
          const SizedBox(height: 10),
          _line('Стало', after, kSuccessBg, kSuccess),
        ],
      ),
    );
  }

  Widget _line(String label, String code, Color bg, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ts(12, weight: FontWeight.w600, color: accent)),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              code.isEmpty ? '—' : code,
              softWrap: false,
              style: const TextStyle(fontFamily: kMono, fontSize: 14, color: kInk),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: ts(13, weight: FontWeight.w600, color: fg)),
    );
  }
}
