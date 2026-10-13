import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/content.dart';
import '../state/content_state.dart';
import '../state/progress_state.dart';
import 'task_screen.dart';
import 'theory_screen.dart';

/// Обзор уровня (экран 19 в Figma): разбор темы и список задач.
class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key, required this.levelId});

  final String levelId;

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentState>();
    final p = context.watch<ProgressState>();
    final level = content.levelById(levelId);
    final lang = content.languageOfLevel(levelId);
    if (level == null || lang == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                BhBackButton(),
                Expanded(child: Center(child: Text('Уровень не найден'))),
              ],
            ),
          ),
        ),
      );
    }
    final levelIndex = lang.levels.indexWhere((l) => l.id == levelId);
    var nextIndex = -1;
    for (var i = 0; i < level.tasks.length; i++) {
      if (!p.isSolved(level.tasks[i].id)) {
        nextIndex = i;
        break;
      }
    }
    final intro = level.intro.isNotEmpty
        ? level.intro
        : 'Найди и исправь ошибки. Каждая задача — один баг.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Align(alignment: Alignment.centerLeft, child: BhBackButton()),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    children: [
                      Text('${lang.title} · ${level.title}', style: ts(12, weight: FontWeight.w600, color: kPrimary)),
                      const SizedBox(height: 6),
                      Text('Уровень ${levelIndex + 1}', style: ts(28, weight: FontWeight.w700, spacing: -0.4)),
                      const SizedBox(height: 6),
                      Text(intro, style: ts(14, color: kMuted, height: 1.4)),
                      const SizedBox(height: 20),
                      BhCard(
                        radius: 16,
                        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => TheoryScreen(levelId: levelId)),
                          );
                        },
                        child: Row(
                          children: [
                            IconTile(
                              icon: p.theoryOpened(levelId) ? Icons.check : Icons.menu_book_outlined,
                              size: 40,
                              radius: 12,
                              iconSize: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Разбор темы', style: ts(16, weight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('Коротко о теме перед задачами', style: ts(12, color: kMuted)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 22, color: kPlaceholder),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < level.tasks.length; i++) ...[
                        _TaskRow(
                          title: level.tasks[i].title,
                          number: i + 1,
                          solved: p.isSolved(level.tasks[i].id),
                          current: i == nextIndex,
                          locked: !p.taskUnlocked(level, i),
                          onTap: () {
                            if (!p.taskUnlocked(level, i)) {
                              showSnack(context, 'Сначала реши предыдущую задачу');
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TaskScreen(taskId: level.tasks[i].id),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: nextIndex >= 0
                      ? BhButton(
                          label: 'Начать задачу ${nextIndex + 1}',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TaskScreen(taskId: level.tasks[nextIndex].id),
                              ),
                            );
                          },
                        )
                      : BhButton(
                          label: 'Уровень пройден',
                          kind: BhButtonKind.secondary,
                          onPressed: () => Navigator.of(context).maybePop(),
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

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.title,
    required this.number,
    required this.solved,
    required this.current,
    required this.locked,
    required this.onTap,
  });

  final String title;
  final int number;
  final bool solved;
  final bool current;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget tile;
    if (solved) {
      tile = const IconTile(icon: Icons.check, size: 40, radius: 12, bg: kSuccessBg, fg: kSuccess, iconSize: 22);
    } else if (locked) {
      tile = const IconTile(
        icon: Icons.lock_outline,
        size: 40,
        radius: 12,
        bg: kLockedTile,
        fg: kPlaceholder,
        iconSize: 20,
      );
    } else {
      tile = NumberTile(number);
    }
    return BhCard(
      radius: 16,
      onTap: onTap,
      borderColor: current ? kPrimary : kLine,
      borderWidth: current ? 2 : 1,
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      child: Row(
        children: [
          tile,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ts(16, weight: FontWeight.w600, color: locked ? kPlaceholder : kInk),
            ),
          ),
          if (current) ...[
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20, color: kPlaceholder),
          ],
        ],
      ),
    );
  }
}
