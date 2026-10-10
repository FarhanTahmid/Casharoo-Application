import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../ui.dart';

/// A round profile picture, or the person's initials on a tint while there is none.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({super.key, required this.initials, this.image, this.size = 40, this.busy = false});

  final String initials;
  final Uint8List? image;
  final double size;

  /// Dims the picture under a loader while a new one uploads.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final face = image == null
        ? ColoredBox(
            color: scheme.primaryContainer,
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        : Image.memory(image!, fit: BoxFit.cover, gaplessPlayback: true);
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(duration: context.motion(AppMotion.standard), child: KeyedSubtree(key: ValueKey(image), child: face)),
            if (busy)
              ColoredBox(
                color: Colors.black38,
                child: Center(child: AppLoader(size: size * 0.08, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
