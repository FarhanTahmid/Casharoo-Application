import 'dart:math';
import 'package:flutter/material.dart';

class BalanceCarousel extends StatelessWidget {
  final PageController controller;
  final double net, totalIn, totalOut;
  final VoidCallback onViewReports;

  const BalanceCarousel({
    super.key,
    required this.controller,
    required this.net,
    required this.totalIn,
    required this.totalOut,
    required this.onViewReports,
  });

  @override
  Widget build(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final t  = Theme.of(context).textTheme;

  final double cardHeight = _computeCardHeight(context); // ← adaptive height

  return SizedBox(
    height: cardHeight,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: PageView(
        controller: controller,
        physics: const ClampingScrollPhysics(),
        children: [
          _card(
            context,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // no Spacer
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // top block (compact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('Net Balance', _money(net), t.titleLarge, cs.onSurface),
                      const SizedBox(height: 4),
                      _row('Total In (+)', _money(totalIn), t.titleMedium, cs.secondary),
                      const SizedBox(height: 2),
                      _row('Total Out (-)', _money(totalOut), t.titleMedium, cs.error),
                    ],
                  ),
                  // bottom button (compact)
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 15,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: onViewReports,
                        icon: const Icon(Icons.chevron_right_rounded, size: 14),
                        label: const Text('VIEW REPORTS'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _card(context, child: _miniBars(context)),
          _card(context, child: _miniPie(context)),
        ],
      ),
    ),
  );
}

/// Increase the height slightly when users bump up their system text scale.
/// Keeps cards readable and prevents vertical overflow without scaling hacks.
double _computeCardHeight(BuildContext context) {
  const base = 142.0;
  // ignore: deprecated_member_use
  final scale = MediaQuery.textScaleFactorOf(context);
  if (scale <= 1.0) return base;
  // Gentle growth: add up to ~36 px at 1.8x. Tweak if you need more headroom.
  final extra = (scale - 1.0) * 45.0;
  return min(base + extra, 168.0);
}


  Widget _card(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.2)),
      ),
      child: child,
    );
  }

  Widget _row(String label, String value, TextStyle? style, Color color) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: style?.copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // lightweight placeholders (replace with fl_chart later if you want)
  Widget _miniBars(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vals = [totalIn, totalOut, max(net, 0)];
    final maxVal = (vals..sort()).last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick glance'),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(cs.secondary, totalIn / (maxVal == 0 ? 1 : maxVal)),
            _bar(cs.error, totalOut / (maxVal == 0 ? 1 : maxVal)),
            _bar(cs.primary, net.abs() / (maxVal == 0 ? 1 : maxVal)),
          ],
        ),
      ],
    );
  }

  Widget _bar(Color c, double p) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        height: 60 * p.clamp(0, 1),
        decoration: BoxDecoration(
          color: c.withOpacity(.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c),
        ),
      ),
    );
  }

  Widget _miniPie(BuildContext context) {
    final total = totalIn + totalOut;
    final inPct  = total == 0 ? 0.5 : totalIn / total;
    final outPct = 1 - inPct;
    return Row(
      children: [
        SizedBox(
          width: 72, height: 72,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: inPct,
                strokeWidth: 10,
                color: Theme.of(context).colorScheme.secondary,
                // ignore: deprecated_member_use
                backgroundColor: Theme.of(context).colorScheme.error.withOpacity(.3),
              ),
              Center(child: Text('${(inPct*100).round()}%')),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text('Income vs Expense (quick pie)')),
      ],
    );
  }

  String _money(double v) {
    final sign = v < 0 ? '-' : '';
    final n = v.abs().toStringAsFixed(0);
    return '$sign${_comma(n)}';
  }

  String _comma(String s) {
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}
