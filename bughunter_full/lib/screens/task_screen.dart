import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/content.dart';
import '../state/content_state.dart';
import '../state/progress_state.dart';
import 'levels_screen.dart';
import 'result_screen.dart';

/// Задача (экраны 05 и 05.1 в Figma): найти строку с ошибкой или выбрать ответ.
class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  int? _picked;
  bool _busy = false;

  Future<void> _check(TaskRef ref) async {
    final picked = _picked;
    if (picked == null || _busy) return;
    setState(() => _busy = true);
    final p = context.read<ProgressState>();
    final outcome = await p.check(ref.task, picked);
    if (!mounted) return;
    setState(() => _busy = false);
    final action = await Navigator.of(context).push<ResultAction>(
      MaterialPageRoute<ResultAction>(
        builder: (_) => ResultScreen(ref: ref, picked: picked, outcome: outcome),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case ResultAction.next:
        _goNext(ref);
        break;
      case ResultAction.levels:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const LevelsScreen()),
        );
        break;
      case ResultAction.back:
        Navigator.of(context).pop();
        break;
      case ResultAction.retry:
        setState(() => _picked = null);
        break;
      case null:
        // Системная кнопка «назад» на экране результата.
        if (outcome.correct) {
          Navigator.of(context).pop();
        } else {
          setState(() => _picked = null);
        }
        break;
    }
  }

  /// Следующая нерешённая задача этого уровня. Если уровень закончен, показываем путь.
  void _goNext(TaskRef ref) {
    final p = context.read<ProgressState>();
    final tasks = ref.level.tasks;
    Task? next;
    for (var i = ref.taskIndex + 1; i < tasks.length; i++) {
      if (!p.isSolved(tasks[i].id)) {
        next = tasks[i];
        break;
      }
    }
    if (next == null) {
      for (final t in tasks) {
        if (!p.isSolved(t.id)) {
          next = t;
          break;
        }
      }
    }
    final target = next;
    if (target == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LevelsScreen()),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => TaskScreen(taskId: target.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = context.watch<ContentState>().taskById(widget.taskId);
    if (ref == null) {
      return const Scaffold(body: SafeArea(child: Center(child: Text('Задача не найдена'))));
    }
    final task = ref.task;
    final isFind = task.type == TaskType.find;
    final picked = _picked;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: BhHeader(title: isFind ? 'Найди ошибку' : 'Вопрос'),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    children: [
                      Text(ref.meta, style: ts(12, weight: FontWeight.w600, color: kPrimary)),
                      const SizedBox(height: 8),
                      Text(task.title, style: ts(26, weight: FontWeight.w700, spacing: -0.4, height: 1.15)),
                      const SizedBox(height: 8),
                      Text(task.description, style: ts(14, color: kMuted, height: 1.4)),
                      const SizedBox(height: 16),
                      if (isFind)
                        CodeBlock(
                          lines: task.lines,
                          selected: picked,
                          onTap: (i) => setState(() => _picked = i),
                        )
                      else ...[
                        if (task.code.isNotEmpty) ...[
                          CodeBlock(lines: task.lines),
                          const SizedBox(height: 16),
                        ],
                        for (var i = 0; i < task.options.length; i++) ...[
                          _OptionTile(
                            text: task.options[i],
                            selected: picked == i,
                            onTap: () => setState(() => _picked = i),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                      if (task.hint.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        HintBox(task.hint),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: BhButton(
                    label: picked == null ? (isFind ? 'Выбери строку' : 'Выбери ответ') : 'Проверить',
                    onPressed: picked == null ? null : () => _check(ref),
                    busy: _busy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.text, required this.selected, required this.onTap});

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BhCard(
      radius: 14,
      onTap: onTap,
      color: selected ? kPrimaryTint : Colors.white,
      borderColor: selected ? kPrimary : kLine,
      borderWidth: selected ? 2 : 1,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: Text(text, style: ts(15, weight: FontWeight.w500, height: 1.3)),
      ),
    );
  }
}
