import 'package:flutter/material.dart';

import 'loaders.dart';
import 'motion.dart';
import 'tokens.dart';

/// The main button of a form. While [busy] its label gives way to the loader
/// and further taps are ignored, without the button changing size or colour.
class BusyButton extends StatelessWidget {
  const BusyButton({super.key, required this.label, required this.onPressed, this.busy = false, this.color, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  /// Background, when the action has a meaning of its own (green for cash in).
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = color == null ? Theme.of(context).colorScheme.onPrimary : Colors.white;
    return FilledButton(
      style: color == null ? null : FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      onPressed: busy ? () {} : onPressed,
      child: AnimatedSwitcher(
        duration: context.motion(AppMotion.standard),
        child: busy
            ? AppLoader(key: const ValueKey('busy'), size: 7, color: foreground)
            : Row(
                key: const ValueKey('label'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }
}

/// The gold button: the one thing on screen that adds something new.
class AddButton extends StatelessWidget {
  const AddButton({super.key, required this.onPressed, required this.tooltip, this.size = 56});

  final VoidCallback onPressed;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        child: Pressable(
          scale: 0.9,
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colors.gold,
              borderRadius: BorderRadius.circular(size * 0.34),
              boxShadow: [
                BoxShadow(color: colors.gold.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Icon(Icons.add_rounded, size: size * 0.55, color: colors.onGold),
          ),
        ),
      ),
    );
  }
}

/// A quiet full-width "add one more" row for the end of a list.
class AddRowButton extends StatelessWidget {
  const AddRowButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded),
        label: Text(label),
      );
}
