import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../money.dart';
import '../ui.dart';

/// Which amount field the keypad is typing into. An [AmountField] attaches
/// itself while it has focus; the [AmountKeypadHost] shows the keys.
class AmountKeypadController extends ChangeNotifier {
  Object? _owner;
  TextEditingController? _text;
  String _currency = 'BDT';
  Color? _accent;
  VoidCallback? _onAction;

  bool get isOpen => _owner != null;

  void attach(
    Object owner, {
    required TextEditingController text,
    required String currency,
    required VoidCallback onAction,
    Color? accent,
  }) {
    _owner = owner;
    _text = text;
    _currency = currency;
    _accent = accent;
    _onAction = onAction;
    notifyListeners();
  }

  /// The last field stays on the keys while they slide away.
  void detach(Object owner) {
    if (_owner != owner) return;
    _owner = null;
    notifyListeners();
  }
}

/// Puts Spendroo's own keypad under the whole app, in place of the system
/// keyboard for amounts. While it is up, everything beneath sees its height as
/// the keyboard inset, so forms and sheets rise above it as they already do.
class AmountKeypadHost extends StatefulWidget {
  const AmountKeypadHost({super.key, required this.child});

  final Widget child;

  /// Null where no host is above (a widget shown on its own): the field then
  /// falls back to the system keyboard.
  static AmountKeypadController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_KeypadScope>()?.controller;

  @override
  State<AmountKeypadHost> createState() => _AmountKeypadHostState();
}

class _AmountKeypadHostState extends State<AmountKeypadHost> with SingleTickerProviderStateMixin {
  final _controller = AmountKeypadController();
  late final _slide = AnimationController(vsync: this, duration: AppMotion.standard);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _slide.duration = context.motion(AppMotion.standard);
  }

  @override
  void dispose() {
    _controller.dispose();
    _slide.dispose();
    super.dispose();
  }

  void _changed() {
    void apply() {
      if (!mounted) return;
      _controller.isOpen ? _slide.forward() : _slide.reverse();
      setState(() {});
    }

    // A field attaches or leaves while the tree is building: wait for the frame to end
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = _Keypad.height + media.padding.bottom;
    return AnimatedBuilder(
      animation: _slide,
      builder: (context, _) {
        final shown = AppMotion.ease.transform(_slide.value);
        return Stack(
          children: [
            MediaQuery(
              data: media.copyWith(
                viewInsets: media.viewInsets.copyWith(bottom: math.max(media.viewInsets.bottom, height * shown)),
              ),
              child: _KeypadScope(controller: _controller, child: widget.child),
            ),
            if (shown > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: -height * (1 - shown),
                height: height,
                child: IgnorePointer(
                  ignoring: !_controller.isOpen,
                  child: _Keypad(controller: _controller),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _KeypadScope extends InheritedWidget {
  const _KeypadScope({required this.controller, required super.child});

  final AmountKeypadController controller;

  @override
  bool updateShouldNotify(_KeypadScope old) => false;
}

const _operators = '+−×÷';

/// Types [key] at the caret of [field], keeping the text a sum that can be
/// worked out: one operator between numbers, one point per number, and no
/// more decimals than [decimals].
void _type(TextEditingController field, String key, int decimals) {
  final text = field.text;
  final selection = field.selection;
  var start = selection.isValid ? selection.start : text.length;
  final end = selection.isValid ? selection.end : text.length;
  final before = text.substring(0, start);
  final last = before.isEmpty ? '' : before[before.length - 1];
  // The number the caret is in, as far as it has been typed
  final number = before.substring(before.lastIndexOf(RegExp('[$_operators%()]')) + 1);
  final point = number.indexOf('.');
  final endsInDigit = last.isNotEmpty && '0123456789'.contains(last);

  var insert = key;
  if (_operators.contains(key)) {
    if (before.isEmpty) return;
    if (_operators.contains(last)) start--; // a second operator replaces the first
  } else if (key == '%') {
    if (!endsInDigit && last != ')') return;
  } else if (key == '.') {
    if (point >= 0 || decimals == 0) return;
    if (number.isEmpty) insert = '0.';
  } else {
    if (last == '%' || last == ')') return;
    if (key == '000' && !endsInDigit) insert = '0';
    if (point >= 0 && number.length - point - 1 + insert.length > decimals) return;
  }
  if (text.length - (end - start) + insert.length > 40) return;

  field.value = TextEditingValue(
    text: text.replaceRange(start, end, insert),
    selection: TextSelection.collapsed(offset: start + insert.length),
  );
}

void _backspace(TextEditingController field) {
  final text = field.text;
  final selection = field.selection;
  var start = selection.isValid ? selection.start : text.length;
  final end = selection.isValid ? selection.end : text.length;
  if (start == end) {
    if (start == 0) return;
    start--;
  }
  field.value = TextEditingValue(
    text: text.replaceRange(start, end, ''),
    selection: TextSelection.collapsed(offset: start),
  );
}

/// The keys: a calculator laid out for money. The bottom-right key works the
/// sum out while there is one, and closes the keypad once there is an amount.
class _Keypad extends StatelessWidget {
  const _Keypad({required this.controller});

  final AmountKeypadController controller;

  static const double _keyHeight = 48;
  static const double _gap = 8;
  static const double _barHeight = 28;

  /// Without the home-bar inset.
  static const double height = 10 + _barHeight + _gap + 5 * _keyHeight + 4 * _gap + 10;

  @override
  Widget build(BuildContext context) {
    final field = controller._text;
    if (field == null) return const SizedBox.shrink();
    final colors = context.colors;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final currency = controller._currency;
    final decimals = Money.exponent(currency);
    final accent = controller._accent ?? scheme.primary;
    final onAccent = ThemeData.estimateBrightnessForColor(accent) == Brightness.dark ? Colors.white : colors.onGold;
    final bangla = context.languageCode == 'bn';

    void tap(VoidCallback action) {
      HapticFeedback.selectionClick();
      action();
    }

    Widget digit(String key, {bool enabled = true}) => _Key(
          label: bangla ? Money.toBengaliDigits(key) : key,
          fill: colors.field,
          ink: scheme.onSurface,
          onTap: enabled ? () => tap(() => _type(field, key, decimals)) : null,
        );

    Widget operator(String key) => _Key(
          label: key,
          fill: accent.withValues(alpha: 0.12),
          ink: accent,
          onTap: () => tap(() => _type(field, key, decimals)),
        );

    Widget row(List<Widget> keys) => SizedBox(
          height: _keyHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, key) in keys.indexed) ...[
                if (index > 0) const SizedBox(width: _gap),
                Expanded(child: key),
              ],
            ],
          ),
        );

    final symbol = Money.symbol(currency).trim();
    return TextFieldTapRegion(
      child: Material(
        color: colors.sheet,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
          side: BorderSide(color: colors.hairline),
        ),
        elevation: 12,
        shadowColor: colors.shadow,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpace.md, 10, AppSpace.md, 10 + MediaQuery.paddingOf(context).bottom),
          child: Column(
            children: [
              // The passbook line: which currency these keys are writing in
              SizedBox(
                height: _barHeight,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        symbol == currency ? currency : '$symbol  $currency',
                        style: theme.textTheme.labelMedium?.copyWith(color: accent, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: l10n.keypadDone,
                      child: Pressable(
                        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.keyboard_hide_outlined, size: 22, color: colors.muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _gap),
              row([
                _Key(
                  label: 'C',
                  semanticLabel: l10n.keypadClear,
                  fill: scheme.error.withValues(alpha: 0.10),
                  ink: scheme.error,
                  onTap: () => tap(field.clear),
                ),
                _Key(
                  icon: Icons.backspace_outlined,
                  semanticLabel: l10n.keypadBackspace,
                  fill: colors.field,
                  ink: scheme.onSurface,
                  onTap: () => tap(() => _backspace(field)),
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    field.clear();
                  },
                ),
                operator('%'),
                operator('÷'),
              ]),
              const SizedBox(height: _gap),
              row([digit('7'), digit('8'), digit('9'), operator('×')]),
              const SizedBox(height: _gap),
              row([digit('4'), digit('5'), digit('6'), operator('−')]),
              const SizedBox(height: _gap),
              row([digit('1'), digit('2'), digit('3'), operator('+')]),
              const SizedBox(height: _gap),
              row([
                digit('000'),
                digit('0'),
                digit('.', enabled: decimals > 0),
                ListenableBuilder(
                  listenable: field,
                  builder: (context, _) {
                    final sum = Money.isExpression(field.text);
                    return _Key(
                      label: sum ? '=' : null,
                      icon: sum ? null : Icons.check_rounded,
                      semanticLabel: sum ? null : l10n.keypadDone,
                      fill: accent,
                      ink: onAccent,
                      onTap: controller._onAction == null ? null : () => tap(controller._onAction!),
                    );
                  },
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.fill,
    required this.ink,
    required this.onTap,
    this.label,
    this.icon,
    this.semanticLabel,
    this.onLongPress,
  });

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final Color fill;
  final Color ink;

  /// Null greys the key out.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final face = PopSwitcher(
      child: icon != null
          ? Icon(icon, key: ValueKey(icon), size: 22, color: ink)
          : Text(
              label!,
              key: ValueKey(label),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w500,
                    fontFeatures: tabularFigures,
                  ),
            ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: GestureDetector(
          onLongPress: enabled ? onLongPress : null,
          child: Pressable(
            onTap: onTap,
            scale: 0.92,
            child: DecoratedBox(
              decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(AppRadius.control)),
              child: Center(child: face),
            ),
          ),
        ),
      ),
    );
  }
}
