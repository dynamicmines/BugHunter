import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/auth_state.dart';
import '../state/progress_state.dart';
import 'settings_screen.dart';

/// Профиль (экран 08 в Figma). Настроек в Figma нет, их открывает значок шестерёнки.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final p = context.watch<ProgressState>();
    final name = auth.user?.name ?? '';
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final level = p.currentLevelIndex + 1;
    final achievements = p.achievements;

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
                    title: 'Профиль',
                    trailing: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 1.5,
                      shadowColor: const Color(0x1A0F172A),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                          );
                        },
                        child: const Icon(Icons.settings_outlined, size: 22, color: kInk),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    children: [
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                          child: Text(initial, style: ts(36, weight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ts(24, weight: FontWeight.w700, spacing: -0.3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Уровень $level · ${p.language.title}',
                          style: ts(14, color: kMuted),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _Stat(value: '${p.solvedCount}', label: 'Решено задач')),
                          const SizedBox(width: 10),
                          Expanded(child: _Stat(value: '${p.streak}', label: 'Дней подряд')),
                          const SizedBox(width: 10),
                          Expanded(child: _Stat(value: '${p.accuracy}%', label: 'Точность')),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text('Достижения', style: ts(20, weight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      for (final a in achievements) ...[
                        _AchievementRow(
                          icon: a.icon,
                          title: a.title,
                          description: a.description,
                          unlocked: a.unlocked,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: BhButton(
                    label: 'Вернуться на главную',
                    kind: BhButtonKind.secondary,
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return BhCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        children: [
          Text(value, style: ts(24, weight: FontWeight.w700, color: kPrimary)),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: ts(12, color: kMuted),
          ),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return BhCard(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconTile(
            icon: icon,
            size: 44,
            radius: 12,
            iconSize: 22,
            bg: unlocked ? kPrimaryTint : kLockedTile,
            fg: unlocked ? kPrimary : kPlaceholder,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ts(15, weight: FontWeight.w600, color: unlocked ? kInk : kMuted),
                ),
                const SizedBox(height: 2),
                Text(description, style: ts(13, color: kMuted)),
              ],
            ),
          ),
          if (unlocked) const Icon(Icons.check_circle, size: 22, color: kSuccess),
        ],
      ),
    );
  }
}
