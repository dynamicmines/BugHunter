import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/util.dart';
import '../core/widgets.dart';
import '../models/content.dart';
import '../state/auth_state.dart';
import '../state/content_state.dart';
import '../state/progress_state.dart';
import 'level_screen.dart';
import 'levels_screen.dart';
import 'profile_screen.dart';
import 'task_screen.dart';

/// Главная (экраны 03, 20, 09 и скелетон 02 в Figma).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return 'Доброй ночи';
    if (h < 12) return 'Доброе утро';
    if (h < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  Future<void> _refresh(BuildContext context) async {
    final content = context.read<ContentState>();
    final message = await content.refresh();
    if (context.mounted) showSnack(context, message);
  }

  void _openTask(BuildContext context, Task task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TaskScreen(taskId: task.id)),
    );
  }

  void _openLevels(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LevelsScreen()));
  }

  void _openLevel(BuildContext context, ProgressState p, int index) {
    final lang = p.language;
    if (!p.levelUnlocked(lang, index)) {
      showSnack(context, 'Сначала пройди предыдущий уровень');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LevelScreen(levelId: lang.levels[index].id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final content = context.watch<ContentState>();
    final p = context.watch<ProgressState>();
    final name = auth.user?.name ?? '';

    if (content.syncing && p.solvedCount == 0 && !content.offline) {
      return const Scaffold(body: SafeArea(child: _HomeSkeleton()));
    }

    final offline = content.offline;
    final lang = p.language;
    final levels = lang.levels;
    final next = p.nextTask;
    final newcomer = p.solvedInLanguage == 0;
    final allDone = p.allDone;
    final cur = p.currentLevelIndex;
    final curLevel = levels[cur];
    final done = p.solvedInLevel(curLevel);
    final left = curLevel.tasks.length - done;
    final streak = p.streak;

    String heroTitle;
    String heroSub;
    double heroValue;
    if (allDone) {
      heroTitle = 'Все уровни пройдены';
      heroSub = 'Выбери другой язык в настройках или повтори задачи';
      heroValue = 1;
    } else if (newcomer) {
      heroTitle = 'Пока нет уровня';
      heroSub = 'Пройди первую задачу, чтобы начать';
      heroValue = 0;
    } else {
      heroTitle = 'Уровень ${cur + 1}';
      heroSub = 'Ещё ${countText(left, 'задача', 'задачи', 'задач')} до следующего уровня';
      heroValue = done / curLevel.tasks.length;
    }
    final pill = streak > 0
        ? '$streak ${plural(streak, 'день', 'дня', 'дней')} подряд'
        : 'Начни сегодня';

    // Темы: предыдущий, текущий и следующий уровни.
    final from = cur - 1 < 0 ? 0 : cur - 1;
    final to = cur + 1 > levels.length - 1 ? levels.length - 1 : cur + 1;
    final topicIndexes = [for (var i = from; i <= to; i++) i];

    String bottomLabel;
    IconData? bottomIcon;
    VoidCallback bottomAction;
    if (offline) {
      bottomLabel = 'Повторить';
      bottomIcon = null;
      bottomAction = () => _refresh(context);
    } else if (next == null) {
      bottomLabel = 'Смотреть уровни';
      bottomIcon = null;
      bottomAction = () => _openLevels(context);
    } else {
      bottomLabel = newcomer ? 'Начать первый урок' : 'Продолжить';
      bottomIcon = Icons.arrow_forward;
      bottomAction = () => _openTask(context, next.task);
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: kPrimary,
                    onRefresh: () => _refresh(context),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      children: [
                        if (offline) ...[
                          const OfflineBanner(),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_greeting(), style: ts(13, color: kMuted)),
                                  const SizedBox(height: 2),
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: ts(26, weight: FontWeight.w700, spacing: -0.4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: Material(
                                color: Colors.white,
                                shape: const CircleBorder(),
                                shadowColor: const Color(0x1A0F172A),
                                elevation: 1.5,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
                                  ),
                                  child: const Icon(Icons.person_outline, size: 22, color: kInk),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _HeroCard(
                          pill: pill,
                          title: heroTitle,
                          subtitle: heroSub,
                          value: heroValue,
                          offline: offline,
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                newcomer ? 'Начни обучение' : 'Продолжить обучение',
                                style: ts(20, weight: FontWeight.w700, spacing: -0.2),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _openLevels(context),
                              child: Row(
                                children: [
                                  Text('Смотреть все', style: ts(14, weight: FontWeight.w600, color: kPrimary)),
                                  const Icon(Icons.chevron_right, size: 20, color: kPrimary),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        BhCard(
                          onTap: next == null ? () => _openLevels(context) : () => _openTask(context, next.task),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const IconTile(icon: Icons.bug_report_outlined),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      next == null ? 'Все задачи решены' : next.task.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: ts(16, weight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      next == null
                                          ? 'Можно повторить любую задачу'
                                          : '${lang.title} · Уровень ${next.levelIndex + 1} · ${next.task.minutes} мин',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: ts(13, color: kMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20, color: kPlaceholder),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text('Темы', style: ts(20, weight: FontWeight.w700, spacing: -0.2)),
                        const SizedBox(height: 12),
                        for (final i in topicIndexes) ...[
                          _TopicCard(
                            title: levels[i].title,
                            done: p.solvedInLevel(levels[i]),
                            total: levels[i].tasks.length,
                            locked: !p.levelUnlocked(lang, i),
                            onTap: () => _openLevel(context, p, i),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: BhButton(
                    label: bottomLabel,
                    trailing: bottomIcon,
                    onPressed: bottomAction,
                    color: offline ? const Color(0xFF666666) : null,
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.pill,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.offline,
  });

  final String pill;
  final String title;
  final String subtitle;
  final double value;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: offline
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8C8C8C), Color(0xFF5A5A5A)],
              )
            : kHeroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: offline ? const Color(0x22000000) : const Color(0x405B4BFF),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Твой прогресс', style: ts(14, color: const Color(0xCCFFFFFF))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x2EFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(pill, style: ts(12, weight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: ts(32, weight: FontWeight.w700, color: Colors.white, spacing: -0.5)),
          const SizedBox(height: 8),
          Text(subtitle, style: ts(14, color: const Color(0xD9FFFFFF))),
          const SizedBox(height: 14),
          BhProgress(value: value, height: 10, fill: Colors.white, track: const Color(0x40FFFFFF)),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.title,
    required this.done,
    required this.total,
    required this.locked,
    required this.onTap,
  });

  final String title;
  final int done;
  final int total;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BhCard(
      radius: 16,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(15, weight: FontWeight.w500, color: locked ? kPlaceholder : kInk),
                ),
              ),
              Text('$done из $total', style: ts(13, color: kMuted)),
            ],
          ),
          const SizedBox(height: 10),
          BhProgress(value: total == 0 ? 0 : done / total, height: 8),
        ],
      ),
    );
  }
}

/// Экран загрузки: серые заготовки на месте карточек (экран 02 в Figma).
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 100, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 120, height: 22),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 172,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: kSkeleton, borderRadius: BorderRadius.circular(28)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 100, height: 12, dark: true),
                SizedBox(height: 18),
                SkeletonBox(width: 150, height: 26, dark: true),
                SizedBox(height: 24),
                SkeletonBox(height: 10, dark: true),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SkeletonBox(width: 190, height: 18),
          const SizedBox(height: 14),
          Container(
            height: 84,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Row(
              children: [
                SkeletonBox(width: 52, height: 52, radius: 14),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 12),
                      SizedBox(height: 10),
                      SkeletonBox(width: 110, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SkeletonBox(width: 60, height: 18),
          const SizedBox(height: 14),
          for (var i = 0; i < 2; i++) ...[
            Container(
              height: 66,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 110, height: 12),
                  SizedBox(height: 14),
                  SkeletonBox(height: 8, radius: 4),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const Spacer(),
          const SkeletonBox(height: 57, radius: 18),
        ],
      ),
    );
  }
}
