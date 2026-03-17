import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CardGestureHandler extends StatelessWidget {
  final Widget child;
  final VoidCallback onFlip;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;

  const CardGestureHandler({
    super.key,
    required this.child,
    required this.onFlip,
    this.onNext,
    this.onPrev,
    this.onSwipeUp,
    this.onSwipeDown,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onFlip,
      onDoubleTap: () {
        if (onNext != null) {
          HapticFeedback.lightImpact();
          onNext!();
        } else {
          HapticFeedback.lightImpact();
        }
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -300) {
          if (onNext != null) {
            HapticFeedback.lightImpact();
            onNext!();
          } else {
            HapticFeedback.lightImpact();
          }
        } else if (velocity > 300) {
          if (onPrev != null) {
            HapticFeedback.lightImpact();
            onPrev!();
          } else {
            HapticFeedback.lightImpact();
          }
        }
      },
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -300) {
          if (onSwipeUp != null) {
            onSwipeUp!();
          } else {
            debugPrint('Swipe Up: Dummy log');
          }
        } else if (velocity > 300) {
          if (onSwipeDown != null) {
            onSwipeDown!();
          } else {
            debugPrint('Swipe Down: Dummy log');
          }
        }
      },
      child: child,
    );
  }
}
