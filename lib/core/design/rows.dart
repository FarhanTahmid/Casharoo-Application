import 'package:flutter/material.dart';

import '../ui.dart';

/// A round tinted badge with an icon: what kind of thing a row is.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.color, this.size = 44});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.5, color: tint),
    );
  }
}

/// One movement of money: what, the details, and how much. Transactions and
/// cashbook entries share it, so a row reads the same everywhere.
class MoneyRow extends StatelessWidget {
  const MoneyRow({
    super.key,
    required this.icon,
    required this.title,
    required this.amount,
    this.detail,
    this.tint,
    this.amountColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? detail;

  /// Already formatted, with its sign.
  final String amount;
  final Color? tint;
  final Color? amountColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: 10),
        child: Row(
          children: [
            IconBadge(icon, color: tint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (detail != null && detail!.isNotEmpty)
                    Text(detail!, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amount,
              style: text.titleMedium?.copyWith(color: amountColor, fontFeatures: tabularFigures),
            ),
          ],
        ),
      ),
    );
  }
}
