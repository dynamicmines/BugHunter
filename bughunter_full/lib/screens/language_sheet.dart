import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/progress_state.dart';

/// Выбор языка обучения: нижняя шторка со списком языков.
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    builder: (sheetContext) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressState>();
    final current = p.language.id;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Язык обучения', style: ts(20, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Прогресс по каждому языку хранится отдельно', style: ts(14, color: kMuted)),
            const SizedBox(height: 16),
            for (final lang in p.languages) ...[
              _LanguageRow(
                title: lang.title,
                subtitle: lang.description,
                done: p.solvedCountIn(lang),
                total: lang.levels.fold<int>(0, (sum, lv) => sum + lv.tasks.length),
                selected: lang.id == current,
                onTap: () async {
                  await p.setLanguage(lang.id);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int done;
  final int total;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BhCard(
      radius: 16,
      onTap: onTap,
      borderColor: selected ? kPrimary : kLine,
      borderWidth: selected ? 2 : 1,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconTile(
            icon: selected ? Icons.check : Icons.code,
            size: 40,
            radius: 12,
            iconSize: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ts(16, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ts(12, color: kMuted, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$done/$total', style: ts(13, weight: FontWeight.w600, color: kMuted)),
        ],
      ),
    );
  }
}
