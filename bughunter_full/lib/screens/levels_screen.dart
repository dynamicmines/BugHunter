import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/util.dart';
import '../core/widgets.dart';
import '../state/progress_state.dart';
import 'language_sheet.dart';
import 'level_screen.dart';
import 'task_screen.dart';

/// Уровни (экран 04 в Figma): путь обучения по выбранному языку.
class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressState>();
    final lang = p.language;
    final levels = lang.levels;
    final cur = p.currentLevelIndex;
    final curLevel = levels[cur];
    final done = p.solvedInLevel(curLevel);
    final total = curLevel.tasks.length;
    final allDone = p.allDone;
    final next = p.nextTask;

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
                    title: 'Уровни',
                    trailing: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      shadowColor: const Color(0x1A0F172A),
                      elevation: 1.5,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => showLanguageSheet(context),
                        child: const Icon(Icons.translate, size: 20, color: kInk),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${lang.title} · твой уровень',
                              style: ts(13, color: const Color(0xCCFFFFFF)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              allDone ? 'Все уровни пройдены' : 'Уровень ${cur + 1} · ${curLevel.title}',
                              style: ts(24, weight: FontWeight.w700, color: Colors.white, spacing: -0.3),
                            ),
                            const SizedBox(height: 10),
                            BhProgress(
                              value: total == 0 ? 0 : done / total,
                              height: 8,
                              fill: Colors.white,
                              track: const Color(0x40FFFFFF),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              allDone
                                  ? 'Отличная работа. Можно повторить любой уровень или выбрать другой язык.'
                                  : '$done из $total ${plural(total, 'задачи', 'задач', 'задач')} · ещё ${total - done} до следующего уровня',
                              style: ts(13, color: const Color(0xD9FFFFFF), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Путь обучения', style: ts(18, weight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      for (var i = 0; i < levels.length; i++) ...[
                        _LevelRow(
                          title: levels[i].title,
                          subtitle: levels[i].subtitle,
                          done: p.solvedInLevel(levels[i]),
                          total: levels[i].tasks.length,
                          state: p.levelDone(levels[i])
                              ? _RowState.done
                              : (p.levelUnlocked(lang, i) ? _RowState.current : _RowState.locked),
                          number: i + 1,
                          onTap: () {
                            if (!p.levelUnlocked(lang, i)) {
                              showSnack(context, 'Сначала пройди предыдущий уровень');
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => LevelScreen(levelId: levels[i].id)),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                if (next != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: BhButton(
                      label: 'Начать задачу',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => TaskScreen(taskId: next.task.id)),
                        );
                      },
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

enum _RowState { done, current, locked }

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.total,
    required this.state,
    required this.number,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int done;
  final int total;
  final _RowState state;
  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = state == _RowState.locked;
    final current = state == _RowState.current;
    Widget tile;
    String status;
    Color statusColor;
    switch (state) {
      case _RowState.done:
        tile = const IconTile(icon: Icons.check, size: 40, radius: 12, bg: kSuccessBg, fg: kSuccess, iconSize: 22);
        status = 'Пройден';
        statusColor = kSuccess;
        break;
      case _RowState.current:
        tile = NumberTile(number);
        status = '$done из $total';
        statusColor = kPrimary;
        break;
      case _RowState.locked:
        tile = const IconTile(
          icon: Icons.lock_outline,
          size: 40,
          radius: 12,
          bg: kLockedTile,
          fg: kPlaceholder,
          iconSize: 20,
        );
        status = 'Закрыт';
        statusColor = kPlaceholder;
        break;
    }
    return BhCard(
      radius: 18,
      onTap: onTap,
      borderColor: current ? kPrimary : kLine,
      borderWidth: current ? 2 : 1,
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      child: Row(
        children: [
          tile,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(16, weight: FontWeight.w600, color: locked ? kPlaceholder : kInk),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(12, color: locked ? kPlaceholder : kMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(status, style: ts(13, weight: FontWeight.w600, color: statusColor)),
        ],
      ),
    );
  }
}
