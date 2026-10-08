import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Three dots rising one after another. The app's only "working on it" sign.
class AppLoader extends StatefulWidget {
  const AppLoader({super.key, this.size = 10, this.color});

  /// Diameter of one dot.
  final double size;
  final Color? color;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final size = widget.size;
    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      child: SizedBox(
        width: size * 4.6,
        height: size * 2.4,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 3; i++)
                () {
                  // Each dot is the same wave, a sixth of a turn behind the last
                  final wave = math.max(0.0, math.sin((_controller.value - i * 0.16) * 2 * math.pi));
                  final still = context.reduceMotion;
                  return Transform.translate(
                    offset: Offset(0, still ? 0 : -wave * size * 0.7),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.35 + 0.65 * wave),
                      ),
                    ),
                  );
                }(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A grey block standing in for content that is still loading.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height = 14, this.radius = 7});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// Placeholder rows with a band of light sweeping across them, in the shape
/// of the list that is about to appear, so the screen does not jump when it does.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.rows = 6});

  final int rows;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.rows; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: 10),
            child: Row(
              children: [
                const Skeleton(width: 44, height: 44, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: 110.0 + (i % 3) * 36),
                      const SizedBox(height: 8),
                      Skeleton(width: 70.0 + (i % 2) * 40, height: 10),
                    ],
                  ),
                ),
                const Skeleton(width: 64),
              ],
            ),
          ),
      ],
    );
    if (context.reduceMotion) return rows;
    return AnimatedBuilder(
      animation: _controller,
      child: rows,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          final x = -1.5 + _controller.value * 3;
          return LinearGradient(
            begin: Alignment(x - 0.6, 0),
            end: Alignment(x + 0.6, 0),
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.55),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(bounds);
        },
        child: child,
      ),
    );
  }
}
