import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../core/widgets.dart';
import '../state/auth_state.dart';
import '../state/content_state.dart';
import '../state/progress_state.dart';
import 'change_password_screen.dart';
import 'language_sheet.dart';

/// Настройки. В Figma этого экрана нет, он собран из тех же карточек и кнопок.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _updating = false;

  Future<void> _rename() async {
    final auth = context.read<AuthState>();
    final name = await inputDialog(
      context,
      title: 'Изменить имя',
      label: 'Имя',
      initial: auth.user?.name ?? '',
      validate: validateName,
    );
    if (name == null || !mounted) return;
    await auth.updateName(name);
    if (mounted) showSnack(context, 'Имя сохранено');
  }

  Future<void> _refreshContent() async {
    if (_updating) return;
    setState(() => _updating = true);
    final message = await context.read<ContentState>().refresh();
    if (!mounted) return;
    setState(() => _updating = false);
    showSnack(context, message);
  }

  Future<void> _resetProgress() async {
    final ok = await confirmDialog(
      context,
      title: 'Сбросить прогресс?',
      text: 'Все решённые задачи, очки и серия дней будут удалены. Аккаунт останется.',
      confirm: 'Сбросить',
      danger: true,
    );
    if (!ok || !mounted) return;
    await context.read<ProgressState>().resetProgress();
    if (mounted) showSnack(context, 'Прогресс сброшен');
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(
      context,
      title: 'Выйти из аккаунта?',
      text: 'Прогресс сохранится на этом устройстве.',
      confirm: 'Выйти',
    );
    if (!ok || !mounted) return;
    final auth = context.read<AuthState>();
    Navigator.of(context).popUntil((r) => r.isFirst);
    await auth.logout();
  }

  Future<void> _deleteAccount() async {
    final auth = context.read<AuthState>();
    final password = await inputDialog(
      context,
      title: 'Удалить аккаунт?',
      text: 'Аккаунт и весь прогресс будут удалены без возможности восстановления. Введи пароль для подтверждения.',
      label: 'Пароль',
      password: true,
      confirm: 'Удалить',
      validate: (v) => v.isEmpty ? 'Введите пароль' : null,
    );
    if (password == null || !mounted) return;
    final navigator = Navigator.of(context);
    final result = await auth.deleteAccount(password);
    if (!mounted) return;
    if (!result.ok) {
      showSnack(context, result.passError ?? result.message ?? 'Не удалось удалить аккаунт');
      return;
    }
    navigator.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final p = context.watch<ProgressState>();
    final content = context.watch<ContentState>();
    final user = auth.user;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: BhHeader(title: 'Настройки'),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    children: [
                      const _Section('Аккаунт'),
                      _Tile(
                        icon: Icons.person_outline,
                        title: 'Имя',
                        value: user?.name ?? '',
                        onTap: _rename,
                      ),
                      const SizedBox(height: 10),
                      _Tile(
                        icon: Icons.mail_outline,
                        title: 'Email',
                        value: user?.email ?? '',
                        badge: (user?.verified ?? false) ? 'Подтверждён' : null,
                      ),
                      const SizedBox(height: 10),
                      _Tile(
                        icon: Icons.lock_outline,
                        title: 'Сменить пароль',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const _Section('Обучение'),
                      _Tile(
                        icon: Icons.translate,
                        title: 'Язык обучения',
                        value: p.language.title,
                        onTap: () => showLanguageSheet(context),
                      ),
                      const SizedBox(height: 10),
                      _Tile(
                        icon: Icons.sync,
                        title: 'Обновить задания и уроки',
                        value: _updating ? 'Проверяем…' : 'Версия ${content.version}',
                        onTap: _refreshContent,
                      ),
                      const SizedBox(height: 10),
                      _Tile(
                        icon: Icons.restart_alt,
                        title: 'Сбросить прогресс',
                        onTap: _resetProgress,
                      ),
                      const SizedBox(height: 24),
                      const _Section('О приложении'),
                      _Tile(
                        icon: Icons.info_outline,
                        title: nazvanieProekta,
                        value: podzagolovok,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: _deleteAccount,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              'Удалить аккаунт',
                              style: ts(14, weight: FontWeight.w600, color: kDanger),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: BhButton(
                    label: 'Выйти',
                    kind: BhButtonKind.secondary,
                    onPressed: _logout,
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

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(text, style: ts(20, weight: FontWeight.w700)),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.value,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BhCard(
      radius: 16,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconTile(icon: icon, size: 40, radius: 12, iconSize: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ts(15, weight: FontWeight.w600)),
                if (value != null && value!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts(13, color: kMuted),
                  ),
                ],
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: kSuccessBg, borderRadius: BorderRadius.circular(12)),
              child: Text(badge!, style: ts(12, weight: FontWeight.w600, color: kSuccess)),
            )
          else if (onTap != null)
            const Icon(Icons.chevron_right, size: 22, color: kPlaceholder),
        ],
      ),
    );
  }
}
