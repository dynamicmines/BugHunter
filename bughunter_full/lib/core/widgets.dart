import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// Круглая белая кнопка «назад» (44x44) как в Figma.
class BhBackButton extends StatelessWidget {
  const BhBackButton({super.key, this.onPressed, this.plain = false, this.icon = Icons.chevron_left});

  final VoidCallback? onPressed;

  /// Без круга: просто стрелка, как на экранах входа и регистрации.
  final bool plain;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final action = onPressed ?? () => Navigator.of(context).maybePop();
    if (plain) {
      return SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 28, color: kInk),
          onPressed: action,
        ),
      );
    }
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        shadowColor: const Color(0x1A0F172A),
        elevation: 1.5,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: action,
          child: Icon(icon, size: 26, color: kInk),
        ),
      ),
    );
  }
}

/// Верхняя строка экрана: кнопка назад, заголовок по центру, место справа.
class BhHeader extends StatelessWidget {
  const BhHeader({super.key, required this.title, this.onBack, this.trailing});

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          BhBackButton(onPressed: onBack),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ts(16, weight: FontWeight.w600),
            ),
          ),
          SizedBox(width: 44, height: 44, child: trailing),
        ],
      ),
    );
  }
}

enum BhButtonKind { primary, secondary }

/// Главная кнопка: высота 57, скругление 18, как в Figma.
class BhButton extends StatelessWidget {
  const BhButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = BhButtonKind.primary,
    this.trailing,
    this.busy = false,
    this.color,
    this.textColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final BhButtonKind kind;
  final IconData? trailing;
  final bool busy;

  /// Свой цвет заливки (например, серый в офлайне).
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final primary = kind == BhButtonKind.primary;
    Color bg;
    Color fg;
    if (primary) {
      bg = enabled ? (color ?? kPrimary) : (color ?? kDisabled);
      fg = enabled ? (textColor ?? Colors.white) : (color != null ? Colors.white : kPlaceholder);
    } else {
      bg = Colors.white;
      fg = enabled ? kInk : kPlaceholder;
    }
    final shadows = <BoxShadow>[
      if (primary && enabled && color == null)
        const BoxShadow(color: Color(0x445B4BFF), blurRadius: 16, offset: Offset(0, 6)),
    ];
    return Container(
      height: 57,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: primary ? null : Border.all(color: kLine),
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onPressed : null,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: ts(16, weight: FontWeight.w600, color: fg)),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        Icon(trailing, size: 20, color: fg),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Поле ввода: подпись сверху, белое поле радиуса 14 с рамкой #E6E8F0, значок справа.
class BhField extends StatefulWidget {
  const BhField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.icon,
    this.password = false,
    this.errorText,
    this.helper,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? icon;
  final bool password;
  final String? errorText;
  final String? helper;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  @override
  State<BhField> createState() => _BhFieldState();
}

class _BhFieldState extends State<BhField> {
  bool _hidden = true;

  OutlineInputBorder _border(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  @override
  Widget build(BuildContext context) {
    Widget? suffix;
    if (widget.password) {
      suffix = IconButton(
        icon: Icon(
          _hidden ? Icons.lock_outline : Icons.lock_open_outlined,
          size: 22,
          color: kPlaceholder,
        ),
        onPressed: () => setState(() => _hidden = !_hidden),
      );
    } else if (widget.icon != null) {
      suffix = Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Icon(widget.icon, size: 22, color: kInk),
      );
    }
    final showHelper = widget.helper != null && widget.errorText == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(widget.label, style: ts(13, weight: FontWeight.w600, color: kMuted)),
        ),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.password && _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          autofocus: widget.autofocus,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          style: ts(15, weight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: widget.hint,
            hintStyle: ts(15, color: kPlaceholder),
            errorText: widget.errorText,
            errorStyle: ts(12, color: kDanger),
            errorMaxLines: 2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            suffixIcon: suffix,
            border: _border(kLine, 1),
            enabledBorder: _border(kLine, 1),
            focusedBorder: _border(kPrimary, 1.5),
            errorBorder: _border(kDanger, 1.5),
            focusedErrorBorder: _border(kDanger, 1.5),
          ),
        ),
        if (showHelper)
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 6),
            child: Text(widget.helper!, style: ts(12, color: kPlaceholder)),
          ),
      ],
    );
  }
}

/// Белая карточка: радиус 20, рамка #E6E8F0.
class BhCard extends StatelessWidget {
  const BhCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.borderColor = kLine,
    this.borderWidth = 1,
    this.color = Colors.white,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color borderColor;
  final double borderWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: r,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Квадратная плитка со значком (52x52 и 40x40 в Figma).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 52,
    this.radius = 14,
    this.bg = kPrimaryTint,
    this.fg = kPrimary,
    this.iconSize = 26,
  });

  final IconData icon;
  final double size;
  final double radius;
  final Color bg;
  final Color fg;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon, size: iconSize, color: fg),
    );
  }
}

/// Плитка с цифрой внутри (номер уровня или задачи).
class NumberTile extends StatelessWidget {
  const NumberTile(this.number, {super.key, this.size = 40});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: kPrimaryTint, borderRadius: BorderRadius.circular(12)),
      child: Text('$number', style: ts(16, weight: FontWeight.w700, color: kPrimary)),
    );
  }
}

/// Жёлтая подсказка с лампочкой.
class HintBox extends StatelessWidget {
  const HintBox(this.text, {super.key, this.icon = Icons.lightbulb_outline});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: kAmberBg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 20, color: kAmber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: ts(14, color: kAmberInk, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

/// Полоса прогресса со скруглением.
class BhProgress extends StatelessWidget {
  const BhProgress({
    super.key,
    required this.value,
    this.height = 8,
    this.fill = kPrimary,
    this.track = kLine,
  });

  final double value;
  final double height;
  final Color fill;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: v,
        minHeight: height,
        color: fill,
        backgroundColor: track,
      ),
    );
  }
}

/// Тёмный блок кода с номерами строк. Строку можно выбрать нажатием.
class CodeBlock extends StatelessWidget {
  const CodeBlock({
    super.key,
    required this.lines,
    this.selected,
    this.onTap,
    this.numbers = true,
  });

  final List<String> lines;
  final int? selected;
  final void Function(int index)? onTap;
  final bool numbers;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: kCodeBg, borderRadius: BorderRadius.circular(24)),
      child: LayoutBuilder(
        builder: (context, c) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: c.maxWidth),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (var i = 0; i < lines.length; i++) _row(i)],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(int i) {
    final isSelected = selected == i;
    final tap = onTap;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap == null ? null : () => tap(i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryDark : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              if (numbers) ...[
                SizedBox(
                  width: 18,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(fontFamily: kMono, fontSize: 12, color: kCodeNumber),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Text(
                lines[i].isEmpty ? ' ' : lines[i],
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(fontFamily: kMono, fontSize: 14, color: kCodeText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Серый «скелет» для состояния загрузки.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 8, this.dark = false});

  final double? width;
  final double height;
  final double radius;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: dark ? kSkeletonDark : kSkeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Тёмная плашка «нет соединения».
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.title = 'Отсутствует соединение', this.subtitle = 'Проверь интернет и повтори попытку'});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: kBanner,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x330F172A), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3F4753),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.wifi_off, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ts(15, weight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: ts(13, color: const Color(0xFFBCBFC3))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Логотип приложения: плитка с жуком.
class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    this.size = 56,
    this.radius = 16,
    this.bg = kPrimary,
    this.fg = Colors.white,
    this.shadow = false,
  });

  final double size;
  final double radius;
  final Color bg;
  final Color fg;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow
            ? const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))]
            : null,
      ),
      child: Icon(Icons.bug_report_outlined, size: size * 0.52, color: fg),
    );
  }
}

/// Круг с крупным значком (экраны результата и успеха).
class BigCircleIcon extends StatelessWidget {
  const BigCircleIcon({super.key, required this.icon, required this.bg, required this.fg, this.size = 96});

  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.46, color: fg),
    );
  }
}

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String text,
  required String confirm,
  String cancel = 'Отмена',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: ts(20, weight: FontWeight.w700)),
        content: Text(text, style: ts(14, color: kMuted, height: 1.45)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancel, style: ts(15, weight: FontWeight.w600, color: kMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              confirm,
              style: ts(15, weight: FontWeight.w600, color: danger ? kDanger : kPrimary),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Диалог с одним полем ввода. Возвращает введённый текст или null.
Future<String?> inputDialog(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  String confirm = 'Сохранить',
  bool password = false,
  String? text,
  String? Function(String)? validate,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return _InputDialog(
        title: title,
        label: label,
        initial: initial,
        confirm: confirm,
        password: password,
        text: text,
        validate: validate,
      );
    },
  );
}

class _InputDialog extends StatefulWidget {
  const _InputDialog({
    required this.title,
    required this.label,
    required this.initial,
    required this.confirm,
    required this.password,
    this.text,
    this.validate,
  });

  final String title;
  final String label;
  final String initial;
  final String confirm;
  final bool password;
  final String? text;
  final String? Function(String)? validate;

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text;
    final check = widget.validate;
    final error = check == null ? null : check(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.title, style: ts(20, weight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.text != null) ...[
            Text(widget.text!, style: ts(14, color: kMuted, height: 1.45)),
            const SizedBox(height: 16),
          ],
          BhField(
            label: widget.label,
            controller: _controller,
            password: widget.password,
            errorText: _error,
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Отмена', style: ts(15, weight: FontWeight.w600, color: kMuted)),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(widget.confirm, style: ts(15, weight: FontWeight.w600, color: kPrimary)),
        ),
      ],
    );
  }
}

/// Копирование текста в буфер обмена с подсказкой.
Future<void> copyText(BuildContext context, String text, String message) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showSnack(context, message);
}
