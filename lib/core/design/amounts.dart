import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../money.dart';
import '../ui.dart';

/// An amount that counts to its new value when it changes, in digits of equal
/// width so the figure does not wobble on the way.
class MoneyText extends StatelessWidget {
  const MoneyText(this.amountMinor, this.currency, {super.key, this.style, this.prefix = ''});

  final int amountMinor;
  final String currency;
  final TextStyle? style;

  /// Put before the amount, e.g. "+".
  final String prefix;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
        tween: IntTween(begin: amountMinor, end: amountMinor),
        duration: context.motion(AppMotion.count),
        curve: AppMotion.ease,
        builder: (context, value, _) => Text(
          '$prefix${context.money(value, currency)}',
          maxLines: 1,
          style: (style ?? DefaultTextStyle.of(context).style).copyWith(fontFeatures: tabularFigures),
        ),
      );
}

/// Keeps an amount field to what a sum is made of: digits, a point and the
/// operators. Covers what the keypad does not type itself: a hardware
/// keyboard, or a paste.
class _AmountFormatter extends TextInputFormatter {
  static final _notAllowed = RegExp(r'[^0-9০-৯.+−×÷%()]');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text
        .replaceAll('*', '×')
        .replaceAll('/', '÷')
        .replaceAll('-', '−')
        .replaceAll(_notAllowed, '');
    if (text == newValue.text) return newValue;
    final caret = newValue.selection.isValid ? newValue.selection.end.clamp(0, text.length) : text.length;
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: caret));
  }
}

/// Field for typing an amount in major units ("1250.50"), or a sum that makes
/// one ("1200+350×2"): it opens Spendroo's keypad and shows the answer as it
/// is typed. With [hero] it is the large figure a money form opens on,
/// coloured by [color]. Read the result with `Money.evaluate`.
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.currency,
    this.label,
    this.allowZero = false,
    this.hero = false,
    this.color,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String currency;
  final String? label;
  final bool allowZero;
  final bool hero;
  final Color? color;
  final bool autofocus;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  final _focus = FocusNode();
  final _heroKey = GlobalKey<FormFieldState<String>>();
  final _formatters = [_AmountFormatter()];
  AmountKeypadController? _keypad;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
    widget.controller.addListener(_textChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _keypad = AmountKeypadHost.maybeOf(context);
  }

  @override
  void didUpdateWidget(AmountField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_textChanged);
      widget.controller.addListener(_textChanged);
    }
    // The currency or colour changed under an open keypad (another account was picked)
    final changed = old.currency != widget.currency || old.color != widget.color || old.controller != widget.controller;
    if (changed && _focus.hasFocus) _attach();
  }

  @override
  void dispose() {
    _keypad?.detach(this);
    widget.controller.removeListener(_textChanged);
    _focus.dispose();
    super.dispose();
  }

  void _attach() => _keypad?.attach(
        this,
        text: widget.controller,
        currency: widget.currency,
        accent: widget.color,
        onAction: _action,
      );

  void _focusChanged() {
    if (_focus.hasFocus) {
      _attach();
    } else {
      _settle();
      _keypad?.detach(this);
    }
    if (mounted) setState(() {});
  }

  void _textChanged() {
    if (!mounted) return;
    final hero = _heroKey.currentState;
    if (hero != null && hero.hasError) hero.validate();
    setState(() {});
  }

  /// Replaces a sum with its answer. False when it cannot be worked out.
  bool _settle() {
    final text = widget.controller.text;
    if (!Money.isExpression(text)) return true;
    final amount = Money.evaluate(text, widget.currency);
    if (amount == null) return false;
    final answer = Money.toInput(amount, widget.currency);
    widget.controller.value = TextEditingValue(text: answer, selection: TextSelection.collapsed(offset: answer.length));
    return true;
  }

  /// The keypad's last key: "=" on a sum, "done" on an amount.
  void _action() {
    if (!Money.isExpression(widget.controller.text)) return _focus.unfocus();
    if (!_settle()) HapticFeedback.mediumImpact();
  }

  String? _validate(BuildContext context, String? value) {
    final amount = Money.evaluate(value ?? '', widget.currency);
    return amount == null || (amount == 0 && !widget.allowZero) ? context.l10n.amountInvalid : null;
  }

  /// "= ৳1,900.00" while a sum is being typed, else nothing.
  Widget _answer(TextStyle? style, {AlignmentGeometry alignment = AlignmentDirectional.centerStart}) {
    final text = widget.controller.text;
    final amount = Money.isExpression(text) ? Money.evaluate(text, widget.currency) : null;
    return AnimatedSize(
      duration: context.motion(AppMotion.standard),
      alignment: Alignment.topCenter,
      child: amount == null
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              alignment: alignment,
              padding: const EdgeInsets.only(top: 6),
              child: MoneyText(amount, widget.currency, prefix: '= ', style: style),
            ),
    );
  }

  /// Back closes the keypad first, as it would the system keyboard.
  Widget _closesOnBack(Widget child) => _focus.hasFocus && _keypad != null && Router.maybeOf(context) != null
      ? BackButtonListener(
          onBackButtonPressed: () async {
            _focus.unfocus();
            return true;
          },
          child: child,
        )
      : child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = widget.currency;
    final controller = widget.controller;
    // Without the keypad host (a widget on its own) the system keyboard still works
    final keyboard = _keypad == null ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.none;
    if (!widget.hero) {
      return _closesOnBack(Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: controller,
            focusNode: _focus,
            keyboardType: keyboard,
            inputFormatters: _formatters,
            autofocus: widget.autofocus,
            onFieldSubmitted: (_) => _settle(),
            style: theme.textTheme.bodyLarge?.copyWith(fontFeatures: tabularFigures),
            decoration: InputDecoration(
              labelText: widget.label ?? context.l10n.amount,
              prefixText: Money.symbol(currency),
            ),
            validator: (value) => _validate(context, value),
          ),
          _answer(theme.textTheme.bodyMedium?.copyWith(color: context.colors.muted)),
        ],
      ));
    }

    final ink = widget.color ?? theme.colorScheme.onSurface;
    final figure = theme.textTheme.displaySmall!.copyWith(color: ink, fontFeatures: tabularFigures);
    // A sum is written smaller, and its answer takes the large figure below
    final sum = Money.isExpression(controller.text);
    final typed = sum ? theme.textTheme.headlineSmall!.copyWith(color: ink, fontFeatures: tabularFigures) : figure;
    // The outer field owns the error, so it can sit centred under the whole figure
    return _closesOnBack(FormField<String>(
      key: _heroKey,
      validator: (_) => _validate(context, controller.text),
      builder: (state) => Shake(
        trigger: state.hasError ? 1 : 0,
        child: Column(
          children: [
            Text(widget.label ?? context.l10n.amount, style: theme.textTheme.labelMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedDefaultTextStyle(
                  duration: context.motion(AppMotion.standard),
                  style: typed.copyWith(color: ink.withValues(alpha: 0.55), fontWeight: FontWeight.w500),
                  child: Text(Money.symbol(currency)),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: IntrinsicWidth(
                    child: TextFormField(
                      controller: controller,
                      focusNode: _focus,
                      keyboardType: keyboard,
                      inputFormatters: _formatters,
                      autofocus: widget.autofocus,
                      onFieldSubmitted: (_) => _settle(),
                      style: typed,
                      cursorColor: ink,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        hintText: '0',
                        hintStyle: figure.copyWith(color: ink.withValues(alpha: 0.3)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        constraints: const BoxConstraints(minWidth: 32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _answer(figure, alignment: Alignment.center),
            AnimatedSize(
              duration: context.motion(AppMotion.standard),
              child: state.hasError
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        state.errorText!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    ));
  }
}
