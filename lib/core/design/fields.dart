import 'package:flutter/material.dart';

import 'tokens.dart';

/// The outline every field wears: a rounded hairline that keeps the label
/// inside the field, and a soft ring around it when [glow] is set (focus, error).
/// Borders of this type blend into each other, so focus fades in instead of snapping.
class FieldBorder extends OutlineInputBorder {
  const FieldBorder({
    super.borderSide,
    super.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.control)),
    this.glow = const Color(0x00000000),
  });

  final Color glow;

  /// Tells the decorator to float the label inside the field, not onto the line.
  @override
  bool get isOutline => false;

  @override
  FieldBorder copyWith({BorderSide? borderSide, BorderRadius? borderRadius, double? gapPadding, Color? glow}) =>
      FieldBorder(
        borderSide: borderSide ?? this.borderSide,
        borderRadius: borderRadius ?? this.borderRadius,
        glow: glow ?? this.glow,
      );

  @override
  FieldBorder scale(double t) => FieldBorder(borderSide: borderSide.scale(t), borderRadius: borderRadius * t, glow: glow);

  static FieldBorder _blend(FieldBorder a, FieldBorder b, double t) => FieldBorder(
        borderSide: BorderSide.lerp(a.borderSide, b.borderSide, t),
        borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t)!,
        glow: Color.lerp(a.glow, b.glow, t)!,
      );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is FieldBorder ? _blend(a, this, t) : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is FieldBorder ? _blend(this, b, t) : super.lerpTo(b, t);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (glow.a > 0) {
      canvas.drawRRect(
        borderRadius.toRRect(rect).inflate(2.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = glow,
      );
    }
    // Never leave a gap for the label: it sits inside
    super.paint(canvas, rect, textDirection: textDirection);
  }

  @override
  bool operator ==(Object other) =>
      other is FieldBorder &&
      other.borderSide == borderSide &&
      other.borderRadius == borderRadius &&
      other.glow == glow;

  @override
  int get hashCode => Object.hash(borderSide, borderRadius, glow);
}

/// A field that shows a value and opens something to change it (a list, a
/// calendar). It looks focused for as long as that is open, and its arrow turns.
class PickerField extends StatefulWidget {
  const PickerField({super.key, required this.label, required this.onOpen, this.text, this.icon});

  final String label;

  /// Shown as the value; null leaves the field empty with its label resting inside.
  final String? text;
  final IconData? icon;

  /// Opens the picker and completes when it closes. Null locks the field.
  final Future<void> Function()? onOpen;

  @override
  State<PickerField> createState() => _PickerFieldState();
}

class _PickerFieldState extends State<PickerField> {
  bool _open = false;

  Future<void> _tap() async {
    setState(() => _open = true);
    try {
      await widget.onOpen!();
    } finally {
      if (mounted) setState(() => _open = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.onOpen == null;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: !locked,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: locked || _open ? null : _tap,
        child: InputDecorator(
          isEmpty: widget.text == null,
          isFocused: _open,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 22),
            suffixIcon: locked
                ? const Icon(Icons.lock_outline_rounded, size: 18)
                : AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: context.motion(AppMotion.standard),
                    curve: AppMotion.ease,
                    child: Icon(Icons.expand_more_rounded, color: _open ? scheme.primary : null),
                  ),
          ),
          child: widget.text == null
              ? null
              : Text(
                  widget.text!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: locked ? context.colors.muted : null),
                ),
        ),
      ),
    );
  }
}

/// An on/off choice shaped like the fields around it; the whole cell is the target.
class SwitchField extends StatelessWidget {
  const SwitchField({super.key, required this.title, required this.value, required this.onChanged, this.subtitle});

  final String title;
  final String? subtitle;
  final bool value;

  /// Null shows the choice but does not let it change.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadius.control);
    return Material(
      color: colors.field,
      shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: colors.hairline)),
      child: InkWell(
        borderRadius: radius,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.bodyLarge?.copyWith(color: onChanged == null ? colors.muted : null)),
                    if (subtitle != null) Text(subtitle!, style: text.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// For `TextField.buildCounter`: hides the "12/200" counter until the text
/// is close to its limit, when it starts to matter.
Widget? quietCounter(BuildContext context, {required int currentLength, required int? maxLength, required bool isFocused}) {
  if (maxLength == null || currentLength < maxLength * 0.8) return null;
  return Text('$currentLength/$maxLength', style: Theme.of(context).textTheme.bodySmall);
}
