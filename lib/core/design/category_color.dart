import 'package:flutter/material.dart';

import '../ui.dart';

/// The colours offered for a category, and what one gets until its owner
/// chooses. All read on both the light and the dark sheet.
const categoryPalette = <Color>[
  Color(0xFF2F6FD0),
  Color(0xFFF5B530),
  Color(0xFF2DB86F),
  Color(0xFFE8705F),
  Color(0xFF3B9EE5),
  Color(0xFF7A5AF8),
  Color(0xFF1FA6A0),
  Color(0xFFE05C9A),
  Color(0xFFF08A3C),
  Color(0xFF8BBF3F),
  Color(0xFFB65FD6),
  Color(0xFF4C63D2),
  Color(0xFFD9485F),
  Color(0xFF12A5C4),
  Color(0xFFA9793E),
  Color(0xFF6B7C93),
];

/// Money that was not filed under any category.
const _uncategorised = Color(0xFF8A97AB);

/// '#RRGGBB' as stored on a category; null for anything else.
Color? parseHexColor(String? hex) {
  if (hex == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) return null;
  return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
}

String toHexColor(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// The colour of a category wherever it is drawn as a fill: chart slices and
/// dots. [hex] is what the user chose; without it the category [id] picks one
/// from the palette, the same one on every screen and device.
Color categoryFill(String? hex, String? id) {
  final chosen = parseHexColor(hex);
  if (chosen != null) return chosen;
  if (id == null) return _uncategorised;
  final hash = id.codeUnits.fold<int>(0, (h, unit) => (h * 31 + unit) & 0x7FFFFFFF);
  return categoryPalette[hash % categoryPalette.length];
}

extension CategoryColorContext on BuildContext {
  /// [categoryFill] for icons and text: a very dark choice is lifted on the
  /// dark theme and a very pale one deepened on the light, so it stays legible.
  Color categoryTint(String? hex, String? id) {
    final hsl = HSLColor.fromColor(categoryFill(hex, id));
    final dark = Theme.of(this).brightness == Brightness.dark;
    final lightness = dark ? hsl.lightness.clamp(0.62, 1.0) : hsl.lightness.clamp(0.0, 0.48);
    return hsl.withLightness(lightness).toColor();
  }
}

/// The small square that says which colour a category has.
class ColorDot extends StatelessWidget {
  const ColorDot(this.color, {super.key, this.size = 12});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size / 3)),
      );
}

/// Swatches to pick from, "automatic", and two sliders for any other colour.
class ColorPicker extends StatelessWidget {
  const ColorPicker({super.key, required this.value, required this.onChanged});

  /// '#RRGGBB', or null for the colour the app picks.
  final String? value;
  final ValueChanged<String?> onChanged;

  static const _saturation = 0.65;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final chosen = parseHexColor(value);
    final isCustom = chosen != null && !categoryPalette.contains(chosen);
    final hsl = HSLColor.fromColor(chosen ?? categoryPalette.first);

    Widget swatch({required Widget child, required bool selected, required VoidCallback onTap, String? tooltip}) {
      final ring = AnimatedContainer(
        duration: context.motion(AppMotion.fast),
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: selected ? scheme.primary : Colors.transparent, width: 2),
        ),
        child: ClipOval(child: child),
      );
      final button = InkResponse(onTap: onTap, radius: 26, child: ring);
      return tooltip == null ? button : Tooltip(message: tooltip, child: button);
    }

    void custom({double? hue, double? lightness}) => onChanged(toHexColor(
        HSLColor.fromAHSL(1, hue ?? hsl.hue, _saturation, lightness ?? hsl.lightness.clamp(0.25, 0.75)).toColor()));

    Widget slider(String label, double value, double min, double max, ValueChanged<double> onChanged) => Row(
          children: [
            SizedBox(width: 64, child: Text(label, style: text.bodySmall)),
            Expanded(
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                activeColor: chosen,
                onChanged: onChanged,
              ),
            ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.colour, style: text.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            swatch(
              tooltip: l10n.automaticColour,
              selected: chosen == null,
              onTap: () => onChanged(null),
              child: ColoredBox(
                color: context.colors.field,
                child: Icon(Icons.auto_awesome_rounded, size: 18, color: context.colors.muted),
              ),
            ),
            for (final color in categoryPalette)
              swatch(
                selected: chosen == color,
                onTap: () => onChanged(toHexColor(color)),
                child: ColoredBox(color: color),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ColorDot(isCustom ? chosen : context.colors.field, size: 18),
            const SizedBox(width: 8),
            Text(l10n.customColour, style: text.labelLarge),
          ],
        ),
        slider(l10n.colourHue, hsl.hue, 0, 359, (hue) => custom(hue: hue)),
        slider(l10n.colourShade, hsl.lightness, 0.25, 0.75, (lightness) => custom(lightness: lightness)),
      ],
    );
  }
}

/// Name and colour of a category, new or existing. Returns null when
/// cancelled or left without a name.
Future<({String name, String? color})?> showCategorySheet(
  BuildContext context, {
  required String title,
  String initialName = '',
  String? initialColor,
}) {
  final name = TextEditingController(text: initialName);
  var color = initialColor;
  return showAppSheet<({String name, String? color})>(
    context,
    title: title,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        void save() {
          final typed = name.text.trim();
          if (typed.isEmpty) return Navigator.pop(context);
          Navigator.pop(context, (name: typed, color: color));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: name,
              autofocus: initialName.isEmpty,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: context.l10n.categoryName),
              onSubmitted: (_) => save(),
            ),
            const SizedBox(height: 16),
            ColorPicker(value: color, onChanged: (value) => setState(() => color = value)),
            const SizedBox(height: 16),
            FilledButton(onPressed: save, child: Text(context.l10n.save)),
          ],
        );
      },
    ),
  );
}
