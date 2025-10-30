import 'package:flutter/material.dart';

PageRouteBuilder slideRoute(Widget page, {AxisDirection direction = AxisDirection.left}) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, secondary, child) {
      final beginOffset = () {
        switch (direction) {
          case AxisDirection.right: return const Offset(-1, 0);
          case AxisDirection.up:    return const Offset(0, 1);
          case AxisDirection.down:  return const Offset(0, -1);
          case AxisDirection.left:
          default:                  return const Offset(1, 0);
        }
      }();
      final tween = Tween(begin: beginOffset, end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeInOut));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
