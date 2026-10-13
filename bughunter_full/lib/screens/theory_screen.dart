import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/content_state.dart';
import '../state/progress_state.dart';

/// Разбор темы: короткое объяснение с примерами кода перед задачами уровня.
/// Этого экрана нет в Figma, он сделан в том же стиле.
class TheoryScreen extends StatefulWidget {
  const TheoryScreen({super.key, required this.levelId});

  final String levelId;

  @override
  State<TheoryScreen> createState() => _TheoryScreenState();
}

class _TheoryScreenState extends State<TheoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProgressState>().markTheoryOpened(widget.levelId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentState>();
    final level = content.levelById(widget.levelId);
    final lang = content.languageOfLevel(widget.levelId);
    if (level == null || lang == null) {
      return const Scaffold(body: SafeArea(child: Center(child: Text('Разбор не найден'))));
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: BhHeader(title: 'Разбор темы'),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    children: [
                      Text('${lang.title} · ${level.title}', style: ts(12, weight: FontWeight.w600, color: kPrimary)),
                      const SizedBox(height: 6),
                      Text(level.title, style: ts(28, weight: FontWeight.w700, spacing: -0.4)),
                      if (level.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(level.subtitle, style: ts(14, color: kMuted)),
                      ],
                      const SizedBox(height: 20),
                      for (final block in level.theory) ...[
                        if (block.isCode)
                          CodeBlock(lines: block.text.split('\n'), numbers: false)
                        else
                          Text(block.text, style: ts(15, height: 1.55)),
                        const SizedBox(height: 16),
                      ],
                      const HintBox('Дальше задачи: в каждой нужно найти один баг. Подсказка будет под кодом.'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: BhButton(
                    label: 'К задачам',
                    trailing: Icons.arrow_forward,
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
