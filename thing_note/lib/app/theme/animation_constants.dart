import 'package:flutter/animation.dart';

/// App-wide animation duration constants
class AppAnimations {
  AppAnimations._();

  /// Very fast duration for button presses and micro-interactions
  static const Duration veryFast = Duration(milliseconds: 150);

  /// Fast duration for menu opens, toggles
  static const Duration fast = Duration(milliseconds: 200);

  /// Normal duration for FAB animations, card expansions
  static const Duration normal = Duration(milliseconds: 250);

  /// Slow duration for page transitions
  static const Duration slow = Duration(milliseconds: 300);

  /// Default animation curve
  static const Curve defaultCurve = Curves.easeOutCubic;
}
