import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui.dart';

/// The shape of every main screen: a navy field holding the figure that
/// matters, and a pale sheet rising over it with the detail.
class PassbookBody extends StatelessWidget {
  const PassbookBody({super.key, required this.child, this.header});

  /// Sits on the navy field, above the sheet. Null gives just the sheet's rounded top.
  final Widget? header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return EntranceScope(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.header, colors.headerEnd],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                child: IconTheme.merge(
                  data: IconThemeData(color: colors.onHeader),
                  child: DefaultTextStyle.merge(style: TextStyle(color: colors.onHeader), child: header!),
                ),
              )
            else
              const SizedBox(height: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
                child: ColoredBox(color: colors.paper, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A scaffold whose top bar continues the navy field of a [PassbookBody].
class PassbookScaffold extends StatelessWidget {
  const PassbookScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.header,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? header;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: headerAppBar(context, title: title, actions: actions),
        body: PassbookBody(header: header, child: body),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      );
}

AppBar headerAppBar(BuildContext context, {Widget? title, List<Widget>? actions}) {
  final colors = context.colors;
  return AppBar(
    backgroundColor: colors.header,
    foregroundColor: colors.onHeader,
    titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(color: colors.onHeader),
    systemOverlayStyle: SystemUiOverlayStyle.light,
    title: title,
    actions: actions,
  );
}

/// The big number on the navy field, under a short label.
class HeaderFigure extends StatelessWidget {
  const HeaderFigure({super.key, required this.label, required this.amountMinor, required this.currency, this.color});

  final String label;
  final int amountMinor;
  final String currency;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.bodyMedium?.copyWith(color: colors.onHeaderMuted)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: MoneyText(
            amountMinor,
            currency,
            style: text.displaySmall?.copyWith(color: color ?? colors.onHeader),
          ),
        ),
      ],
    );
  }
}

/// A smaller labelled figure for the header's second row.
class HeaderStat extends StatelessWidget {
  const HeaderStat({super.key, required this.label, required this.amountMinor, required this.currency, this.color});

  final String label;
  final int amountMinor;
  final String currency;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodySmall?.copyWith(color: colors.onHeaderMuted)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MoneyText(amountMinor, currency, style: text.titleMedium?.copyWith(color: color ?? colors.onHeader)),
          ),
        ],
      ),
    );
  }
}

/// "‹ October 2026 ›" on the navy field: steps a month back or forward.
/// [month] is any day in the month.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({super.key, required this.month, required this.onChanged});

  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = MaterialLocalizations.of(context).formatMonthYear(month);
    Widget arrow(String tooltip, IconData icon, int step) => IconButton(
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          color: colors.onHeader,
          icon: Icon(icon),
          onPressed: () {
            HapticFeedback.selectionClick();
            onChanged(DateTime(month.year, month.month + step));
          },
        );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          arrow(context.l10n.previousMonth, Icons.chevron_left_rounded, -1),
          Expanded(
            child: AnimatedSwitcher(
              duration: context.motion(AppMotion.standard),
              child: Text(
                label,
                key: ValueKey(label),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.onHeader),
              ),
            ),
          ),
          arrow(context.l10n.nextMonth, Icons.chevron_right_rounded, 1),
        ],
      ),
    );
  }
}

/// A titled white card: one topic of a screen.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.children, this.title, this.trailing, this.padding});

  final String? title;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: AppSpace.md),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.md),
                  child: Row(
                    children: [
                      Expanded(child: Text(title!, style: Theme.of(context).textTheme.titleMedium)),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
              ...children,
            ],
          ),
        ),
      );
}

/// One labelled figure with a small coloured sign, for a row of two or three.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.amountMinor,
    required this.currency,
    required this.color,
    required this.icon,
  });

  final String label;
  final int amountMinor;
  final String currency;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Flexible(child: Text(label, style: text.bodySmall, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MoneyText(amountMinor, currency, style: text.titleMedium?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

/// A bar that fills to [value] (0 to 1) when it appears or changes. Green
/// while there is room, gold when close to the limit, red once over it.
class LimitBar extends StatelessWidget {
  const LimitBar({super.key, required this.value, this.marker, this.height = 10});

  /// Spent as a share of the limit; may exceed 1.
  final double value;

  /// Where "today" falls in the period (0 to 1), drawn as a tick.
  final double? marker;
  final double height;

  static Color colorFor(BuildContext context, double value) =>
      value > 1 ? AppTheme.errorColor : (value >= 0.85 ? AppTheme.warningColor : AppTheme.successColor);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: context.motion(const Duration(milliseconds: 450)),
      curve: AppMotion.ease,
      builder: (context, fill, _) => SizedBox(
        height: height + 8,
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              Container(
                height: height,
                width: box.maxWidth * fill,
                decoration: BoxDecoration(
                  color: colorFor(context, value),
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              if (marker != null)
                Positioned(
                  left: (box.maxWidth * marker!.clamp(0.0, 1.0) - 1.5).clamp(0.0, box.maxWidth - 3),
                  child: Container(
                    width: 3,
                    height: height + 8,
                    decoration: BoxDecoration(color: scheme.onSurface, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The month's spending against its budget, with a tick at today: if the bar
/// is behind the tick, the month is going fine.
class PaceBar extends StatelessWidget {
  const PaceBar({
    super.key,
    required this.spentMinor,
    required this.limitMinor,
    required this.currency,
    this.dayFraction,
  });

  final int spentMinor;
  final int limitMinor;
  final String currency;

  /// How far through the month today is; null for a month that is not the current one.
  final double? dayFraction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final left = limitMinor - spentMinor;
    final value = spentMinor / limitMinor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                left >= 0 ? l10n.paceLeft(context.money(left, currency)) : l10n.paceOver(context.money(-left, currency)),
                style: text.titleMedium?.copyWith(color: left >= 0 ? null : context.colors.moneyOut),
              ),
            ),
            if (dayFraction != null) Text(l10n.today, style: text.labelSmall),
            if (dayFraction != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Container(
                  width: 3,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LimitBar(value: value, marker: dayFraction, height: 12),
        const SizedBox(height: 6),
        Text(
          '${l10n.budgetThisMonth}: ${context.money(limitMinor, currency)}',
          style: text.bodySmall,
        ),
      ],
    );
  }
}

/// What an empty screen says, and the one thing to do about it.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.actionLabel, this.onAction});

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: context.motion(const Duration(milliseconds: 450)),
              curve: AppMotion.spring,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(icon, size: 40, color: scheme.primary.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(onPressed: onAction, icon: const Icon(Icons.add_rounded), label: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders a stream-backed provider: placeholder rows while loading, the error
/// if it fails, and a soft fade to the content when it arrives.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.builder});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: context.motion(AppMotion.standard),
        child: value.when(
          data: (data) => KeyedSubtree(key: const ValueKey('data'), child: builder(data)),
          loading: () => const Align(
            key: ValueKey('loading'),
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: 8),
              child: SkeletonList(),
            ),
          ),
          error: (error, _) => Center(
            key: const ValueKey('error'),
            child: Padding(padding: const EdgeInsets.all(24), child: Text('$error', textAlign: TextAlign.center)),
          ),
        ),
      );
}

/// Tappable field that opens a date picker. Dates are ISO strings (yyyy-MM-dd).
class DateField extends StatelessWidget {
  const DateField({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => PickerField(
        label: context.l10n.date,
        text: friendlyDate(context, value),
        icon: Icons.calendar_today_rounded,
        onOpen: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.parse(value),
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) onChanged(picked.toIso8601String().substring(0, 10));
        },
      );
}
