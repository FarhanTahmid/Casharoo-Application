import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/ui.dart';
import 'ledger_repository.dart';

String localDigits(BuildContext context, String text) =>
    context.languageCode == 'bn' ? Money.toBengaliDigits(text) : text;

/// "+12% vs last month" in red when spending rose, green when it fell.
class ChangeChip extends StatelessWidget {
  const ChangeChip({super.key, required this.percent});

  /// Null: the category had no spending last month.
  final int? percent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rose = (percent ?? 0) > 0;
    final color = percent == null ? context.colors.muted : context.amountColor(!rose);
    final signed = percent == null ? null : localDigits(context, '${rose ? '+' : ''}$percent');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (percent != null && percent != 0)
          Icon(rose ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: color),
        if (percent != null && percent != 0) const SizedBox(width: 4),
        Flexible(
          child: Text(
            signed == null ? l10n.newThisMonth : l10n.changeVsLastMonth(signed),
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Where the month's money went: what stands out, a ring to tap, and the
/// categories ranked. Tapping a slice or a row puts that category in focus and
/// opens what there is to know about it: its change on last month, how many
/// expenses it holds, and how it stands against its budget.
class SpendingBreakdown extends StatefulWidget {
  const SpendingBreakdown({super.key, required this.month, required this.currency, this.budgets = const []});

  final MonthSummary month;
  final String currency;

  /// The budgets in force for the month, to show next to the category in focus.
  final List<BudgetProgress> budgets;

  @override
  State<SpendingBreakdown> createState() => _SpendingBreakdownState();
}

class _SpendingBreakdownState extends State<SpendingBreakdown> with TickerProviderStateMixin {
  static const _collapsedRows = 5;

  late final _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final _focus = AnimationController(vsync: this, duration: AppMotion.emphasised, value: 1);
  late final _revealCurve = CurvedAnimation(parent: _reveal, curve: AppMotion.ease);
  late final _focusCurve = CurvedAnimation(parent: _focus, curve: AppMotion.ease);

  /// The slice in focus and the one it took over from, as indexes into the month's categories.
  int? _selected;
  int? _previous;
  bool _expanded = false;
  bool _started = false;

  List<CategorySpend> get _slices => widget.month.byCategory;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    context.reduceMotion ? _reveal.value = 1 : _reveal.forward();
  }

  @override
  void didUpdateWidget(SpendingBreakdown old) {
    super.didUpdateWidget(old);
    final selected = _selected;
    if (selected == null || identical(old.month, widget.month)) return;
    // Another month, or the figures moved: stay on the same category if it is still there
    final id = old.month.byCategory[selected].categoryId;
    final index = _slices.indexWhere((s) => s.categoryId == id);
    _selected = index < 0 ? null : index;
    _previous = null;
  }

  @override
  void dispose() {
    _revealCurve.dispose();
    _focusCurve.dispose();
    _reveal.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _select(int? index) {
    final next = index == _selected ? null : index;
    if (next == _selected) return;
    HapticFeedback.selectionClick();
    setState(() {
      _previous = _selected;
      _selected = next;
    });
    context.reduceMotion ? _focus.value = 1 : _focus.forward(from: 0);
  }

  int _percent(int amountMinor) =>
      widget.month.expenseMinor <= 0 ? 0 : (amountMinor * 100 / widget.month.expenseMinor).round();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final slices = _slices;
    final fills = [for (final s in slices) categoryFill(s.color, s.categoryId)];
    final selected = _selected;
    final hidden = slices.length - _collapsedRows;
    // One row would not be worth a button; a category chosen on the ring must be listed
    final showAll = _expanded || hidden < 2 || (selected != null && selected >= _collapsedRows);
    final visible = showAll ? slices.length : _collapsedRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._insights(context),
        const SizedBox(height: 4),
        SizedBox(
          key: const ValueKey('spending-ring'),
          height: 208,
          child: LayoutBuilder(
            builder: (context, box) {
              final size = Size(box.maxWidth, 208);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _select(_RingPainter.hit(size, details.localPosition, _weights(slices))),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: CustomPaint(
                          painter: _RingPainter(
                            weights: _weights(slices),
                            fills: fills,
                            track: colors.hairline,
                            selected: selected,
                            previous: _previous,
                            reveal: _revealCurve,
                            focus: _focusCurve,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 112,
                      child: AnimatedSwitcher(
                        duration: context.motion(AppMotion.standard),
                        child: selected == null
                            ? _Centre(
                                key: const ValueKey('total'),
                                label: l10n.spent,
                                figure: Money.compact(widget.month.expenseMinor, widget.currency,
                                    locale: context.languageCode),
                              )
                            : _Centre(
                                key: ValueKey(selected),
                                label: slices[selected].name ?? l10n.uncategorised,
                                figure: Money.compact(slices[selected].amountMinor, widget.currency,
                                    locale: context.languageCode),
                                caption: l10n.shareOfSpending(
                                    localDigits(context, '${_percent(slices[selected].amountMinor)}')),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        AnimatedSize(
          duration: context.motion(AppMotion.emphasised),
          curve: AppMotion.ease,
          alignment: Alignment.topCenter,
          child: selected == null
              ? Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 14, color: colors.muted),
                      const SizedBox(width: 6),
                      Text(l10n.spendTapHint, style: text.bodySmall),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: _FocusPanel(
                    slice: slices[selected],
                    fill: fills[selected],
                    currency: widget.currency,
                    budget: _budgetOf(slices[selected]),
                    onClose: () => _select(selected),
                  ),
                ),
        ),
        for (var i = 0; i < visible; i++)
          _CategoryRow(
            slice: slices[i],
            fill: fills[i],
            currency: widget.currency,
            percent: _percent(slices[i].amountMinor),
            barFraction: slices.first.amountMinor <= 0 ? 0 : slices[i].amountMinor / slices.first.amountMinor,
            selected: selected == i,
            dimmed: selected != null && selected != i,
            onTap: () => _select(i),
          ),
        if (hidden >= 2 && !(selected != null && selected >= _collapsedRows))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18),
              label: Text(_expanded ? l10n.showLess : l10n.moreCategories(localDigits(context, '$hidden'))),
            ),
          ),
      ],
    );
  }

  List<double> _weights(List<CategorySpend> slices) => [for (final s in slices) s.amountMinor.toDouble()];

  BudgetProgress? _budgetOf(CategorySpend slice) {
    for (final b in widget.budgets) {
      if (b.budget.categoryId == slice.categoryId && b.budget.currency == widget.currency) return b;
    }
    return null;
  }

  /// What is worth saying before any tapping: the category that dominates, and
  /// the one that grew most on last month.
  List<Widget> _insights(BuildContext context) {
    final l10n = context.l10n;
    final slices = _slices;
    final top = slices.first;
    CategorySpend? riser;
    for (final s in slices) {
      final grew = s.amountMinor - s.previousMinor;
      if (s.previousMinor > 0 && (s.changePercent ?? 0) >= 10 && grew > (riser?.amountMinor ?? 0) - (riser?.previousMinor ?? 0)) {
        riser = s;
      }
    }
    return [
      if (slices.length > 1)
        _Insight(
          icon: Icons.pie_chart_rounded,
          color: Theme.of(context).colorScheme.primary,
          text: l10n.spendInsightTop(
              top.name ?? l10n.uncategorised, localDigits(context, '${_percent(top.amountMinor)}')),
        ),
      if (riser != null)
        _Insight(
          icon: Icons.trending_up_rounded,
          color: context.colors.moneyOut,
          text: l10n.spendInsightRise(
              riser.name ?? l10n.uncategorised, localDigits(context, '${riser.changePercent}')),
        ),
    ];
  }
}

/// One finding, with a small sign in front.
class _Insight extends StatelessWidget {
  const _Insight({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );
}

/// The middle of the ring: the month's total, or the category in focus.
class _Centre extends StatelessWidget {
  const _Centre({super.key, required this.label, required this.figure, this.caption});

  final String label;
  final String figure;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(figure, style: text.headlineSmall?.copyWith(fontFeatures: tabularFigures)),
        ),
        if (caption != null)
          FittedBox(fit: BoxFit.scaleDown, child: Text(caption!, style: text.labelSmall)),
      ],
    );
  }
}

/// Everything about the category in focus.
class _FocusPanel extends StatelessWidget {
  const _FocusPanel({
    required this.slice,
    required this.fill,
    required this.currency,
    required this.budget,
    required this.onClose,
  });

  final CategorySpend slice;
  final Color fill;
  final String currency;
  final BudgetProgress? budget;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final budget = this.budget;

    Widget stat(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontFeatures: tabularFigures),
                ),
              ),
            ],
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: colors.field,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border(left: BorderSide(color: fill, width: 4)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slice.name ?? l10n.uncategorised,
                        style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    ChangeChip(percent: slice.changePercent),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                stat(l10n.transactions, localDigits(context, '${slice.count}')),
                const SizedBox(width: 8),
                stat(l10n.statAverage,
                    context.money(slice.count == 0 ? 0 : (slice.amountMinor / slice.count).round(), currency)),
                const SizedBox(width: 8),
                stat(l10n.statLargest, context.money(slice.largestMinor, currency)),
              ],
            ),
          ),
          if (budget != null)
            Padding(
              padding: const EdgeInsets.only(top: 10, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LimitBar(value: budget.spentMinor / budget.budget.amountMinor, height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.spentOf(
                              context.money(budget.spentMinor, currency), context.money(budget.budget.amountMinor, currency)),
                          style: text.bodySmall,
                        ),
                      ),
                      if (budget.isOver)
                        Text(l10n.overBudget, style: text.bodySmall?.copyWith(color: colors.moneyOut)),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A category in the ranking: its share and amount, over a bar measured
/// against the biggest category so the gaps between them can be seen.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.slice,
    required this.fill,
    required this.currency,
    required this.percent,
    required this.barFraction,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final CategorySpend slice;
  final Color fill;
  final String currency;
  final int percent;
  final double barFraction;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final weight = selected ? FontWeight.w700 : null;
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        scale: 0.98,
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: dimmed ? 0.45 : 1,
          duration: context.motion(AppMotion.standard),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              children: [
                Row(
                  children: [
                    ColorDot(fill),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        slice.name ?? context.l10n.uncategorised,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(fontWeight: weight),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(localDigits(context, '$percent%'), style: text.bodySmall),
                    ),
                    Text(
                      context.money(slice.amountMinor, currency),
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontFeatures: tabularFigures),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: barFraction.clamp(0.0, 1.0)),
                  duration: context.motion(const Duration(milliseconds: 450)),
                  curve: AppMotion.ease,
                  builder: (context, fraction, _) => Stack(
                    children: [
                      Container(
                        height: selected ? 6 : 4,
                        decoration: BoxDecoration(
                          color: context.colors.hairline,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction,
                        child: Container(
                          height: selected ? 6 : 4,
                          constraints: const BoxConstraints(minWidth: 4),
                          decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(3)),
                        ),
                      ),
                    ],
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

/// The ring: one arc per category, clockwise from the top. The arc in focus
/// grows outwards while the others fade back.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.weights,
    required this.fills,
    required this.track,
    required this.selected,
    required this.previous,
    required this.reveal,
    required this.focus,
  }) : super(repaint: Listenable.merge([reveal, focus]));

  final List<double> weights;
  final List<Color> fills;
  final Color track;
  final int? selected;
  final int? previous;
  final Animation<double> reveal;
  final Animation<double> focus;

  static const _thickness = 24.0;
  static const _grow = 8.0;
  static const _gap = 0.045;

  /// A sliver too thin to see or tap still gets this share of the ring.
  static const _minShare = 0.012;

  static double _radius(Size size) => math.min(size.width, size.height) / 2 - _grow - 2;

  /// Start angle and sweep of each arc, in radians from the top.
  static List<(double, double)> _arcs(List<double> weights) {
    final total = weights.fold<double>(0, (sum, w) => sum + w);
    if (total <= 0) return const [];
    final shares = [for (final w in weights) math.max(w / total, _minShare)];
    final sum = shares.fold<double>(0, (a, b) => a + b);
    final gap = weights.length > 1 ? _gap : 0.0;
    final room = 2 * math.pi - gap * weights.length;
    final arcs = <(double, double)>[];
    var at = gap / 2;
    for (final share in shares) {
      final sweep = room * share / sum;
      arcs.add((at, sweep));
      at += sweep + gap;
    }
    return arcs;
  }

  /// The arc under [position], or null for the middle and anywhere off the ring.
  static int? hit(Size size, Offset position, List<double> weights) {
    final offset = position - size.center(Offset.zero);
    final radius = _radius(size);
    if (offset.distance < radius - _thickness - 10 || offset.distance > radius + _grow + 10) return null;
    final angle = (math.atan2(offset.dy, offset.dx) + math.pi / 2) % (2 * math.pi);
    final arcs = _arcs(weights);
    for (final (index, (start, sweep)) in arcs.indexed) {
      // The gap after an arc belongs to it, so no tap on the ring is lost
      if (angle >= start - _gap / 2 && angle < start + sweep + _gap / 2) return index;
    }
    return arcs.isEmpty ? null : arcs.length - 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = _radius(size);
    final t = focus.value;
    final shown = 2 * math.pi * reveal.value;
    final dim = (previous != null ? 1 - t : 0.0) + (selected != null ? t : 0.0);

    canvas.drawCircle(
      centre,
      radius - _thickness / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _thickness
        ..color = track.withValues(alpha: 0.5),
    );

    for (final (index, (start, sweep)) in _arcs(weights).indexed) {
      if (start >= shown) break;
      final emphasis = index == selected ? t : (index == previous ? 1 - t : 0.0);
      final width = _thickness + _grow * emphasis;
      canvas.drawArc(
        // Grows outwards: the inner edge stays where it is
        Rect.fromCircle(center: centre, radius: radius - _thickness + width / 2),
        start - math.pi / 2,
        math.min(sweep, shown - start),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = fills[index].withValues(alpha: 1 - 0.7 * dim.clamp(0.0, 1.0) * (1 - emphasis)),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => true;
}
