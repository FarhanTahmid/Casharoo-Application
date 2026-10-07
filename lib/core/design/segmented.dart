import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// A choice between a few options, with a pill that slides to the chosen one.
class SlidingSegmented<T> extends StatelessWidget {
  const SlidingSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.colorOf,
    this.onHeader = false,
  });

  /// Option to its label, in display order.
  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;

  /// Pill colour per option; the primary colour when null.
  final Color Function(T value)? colorOf;

  /// Styled to sit on the navy header.
  final bool onHeader;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final keys = segments.keys.toList();
    final index = keys.indexOf(value).clamp(0, keys.length - 1);
    final pill = onHeader ? colors.onHeader : (colorOf?.call(value) ?? scheme.primary);
    final onPill = onHeader ? colors.header : (colorOf == null ? scheme.onPrimary : Colors.white);
    final idle = onHeader ? colors.onHeaderMuted : colors.muted;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: onHeader ? Colors.white.withValues(alpha: 0.1) : colors.field,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(keys.length == 1 ? 0 : -1 + 2 * index / (keys.length - 1), 0),
            duration: context.motion(AppMotion.emphasised),
            curve: AppMotion.ease,
            child: FractionallySizedBox(
              widthFactor: 1 / keys.length,
              heightFactor: 1,
              child: AnimatedContainer(
                duration: context.motion(AppMotion.emphasised),
                decoration: BoxDecoration(color: pill, borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Row(
            children: [
              for (final key in keys)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: key == value,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: key == value
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              onChanged(key);
                            },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: context.motion(AppMotion.standard),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(color: key == value ? onPill : idle, fontSize: 14),
                          child: Text(segments[key]!, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
