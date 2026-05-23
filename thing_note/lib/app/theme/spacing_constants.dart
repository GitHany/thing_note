import 'package:flutter/material.dart';

/// App-wide spacing and sizing constants for consistent design
class AppSpacing {
  AppSpacing._();

  // ============ Breakpoints ============
  /// Ultra small screen (320px and below)
  static const double ultraSmallBreakpoint = 320;

  /// Small screen (360px and below)
  static const double smallBreakpoint = 360;

  /// Medium screen (600px and below)
  static const double mediumBreakpoint = 600;

  /// Large screen (768px and above)
  static const double largeBreakpoint = 768;

  /// Extra large screen (1200px and above)
  static const double extraLargeBreakpoint = 1200;

  // ============ Horizontal Padding ============
  /// Ultra small screen horizontal padding
  static const double ultraSmallHorizontalPadding = 12.0;

  /// Small screen horizontal padding
  static const double smallHorizontalPadding = 14.0;

  /// Medium screen horizontal padding
  static const double mediumHorizontalPadding = 16.0;

  /// Large screen horizontal padding
  static const double largeHorizontalPadding = 20.0;

  /// Extra large screen horizontal padding
  static const double extraLargeHorizontalPadding = 24.0;

  // ============ Vertical Spacing ============
  /// Ultra small screen vertical spacing
  static const double ultraSmallVerticalSpacing = 8.0;

  /// Small screen vertical spacing
  static const double smallVerticalSpacing = 10.0;

  /// Medium screen vertical spacing
  static const double mediumVerticalSpacing = 14.0;

  /// Large screen vertical spacing
  static const double largeVerticalSpacing = 16.0;

  // ============ Item Spacing ============
  /// Ultra small screen item spacing
  static const double ultraSmallItemSpacing = 10.0;

  /// Small screen item spacing
  static const double smallItemSpacing = 12.0;

  /// Medium screen item spacing
  static const double mediumItemSpacing = 14.0;

  /// Large screen item spacing
  static const double largeItemSpacing = 16.0;

  // ============ Section Spacing ============
  /// Small screen section spacing
  static const double smallSectionSpacing = 12.0;

  /// Medium screen section spacing
  static const double mediumSectionSpacing = 16.0;

  /// Large screen section spacing
  static const double largeSectionSpacing = 20.0;

  // ============ Border Radius ============
  /// Small border radius (chips, small buttons)
  static const double smallBorderRadius = 6.0;

  /// Medium border radius (cards, inputs)
  static const double mediumBorderRadius = 12.0;

  /// Large border radius (modals, sheets)
  static const double largeBorderRadius = 14.0;

  /// Extra large border radius (dialogs)
  static const double extraLargeBorderRadius = 16.0;

  // ============ Icon Sizes ============
  /// Small icon size
  static const double smallIconSize = 16.0;

  /// Default icon size
  static const double defaultIconSize = 20.0;

  /// Medium icon size
  static const double mediumIconSize = 24.0;

  /// Large icon size
  static const double largeIconSize = 28.0;

  // ============ Touch Targets ============
  /// Minimum touch target size (Material Design)
  static const double minTouchTarget = 44.0;

  /// Small touch target
  static const double smallTouchTarget = 36.0;

  /// Large touch target
  static const double largeTouchTarget = 48.0;

  // ============ Helper Methods ============

  /// Get horizontal padding based on screen width
  static double getHorizontalPadding(double screenWidth) {
    if (screenWidth <= ultraSmallBreakpoint) {
      return ultraSmallHorizontalPadding;
    } else if (screenWidth <= smallBreakpoint) {
      return smallHorizontalPadding;
    } else if (screenWidth <= mediumBreakpoint) {
      return mediumHorizontalPadding;
    } else if (screenWidth <= largeBreakpoint) {
      return largeHorizontalPadding;
    } else {
      return extraLargeHorizontalPadding;
    }
  }

  /// Get vertical spacing based on screen width
  static double getVerticalSpacing(double screenWidth) {
    if (screenWidth <= ultraSmallBreakpoint) {
      return ultraSmallVerticalSpacing;
    } else if (screenWidth <= smallBreakpoint) {
      return smallVerticalSpacing;
    } else if (screenWidth <= mediumBreakpoint) {
      return mediumVerticalSpacing;
    } else {
      return largeVerticalSpacing;
    }
  }

  /// Get item spacing based on screen width
  static double getItemSpacing(double screenWidth) {
    if (screenWidth <= ultraSmallBreakpoint) {
      return ultraSmallItemSpacing;
    } else if (screenWidth <= smallBreakpoint) {
      return smallItemSpacing;
    } else if (screenWidth <= mediumBreakpoint) {
      return mediumItemSpacing;
    } else {
      return largeItemSpacing;
    }
  }

  /// Check if screen is ultra small
  static bool isUltraSmall(double screenWidth) => screenWidth <= ultraSmallBreakpoint;

  /// Check if screen is small
  static bool isSmall(double screenWidth) => screenWidth <= smallBreakpoint;

  /// Check if screen is medium
  static bool isMedium(double screenWidth) => screenWidth <= mediumBreakpoint;

  /// Check if screen is large (tablet)
  static bool isLarge(double screenWidth) => screenWidth >= largeBreakpoint;

  /// Check if screen is extra large (desktop)
  static bool isExtraLarge(double screenWidth) => screenWidth >= extraLargeBreakpoint;
}

/// Common padding utilities
class AppPaddings {
  AppPaddings._();

  /// Card padding for compact screens
  static const EdgeInsets compactCardPadding = EdgeInsets.all(10.0);

  /// Card padding for normal screens
  static const EdgeInsets normalCardPadding = EdgeInsets.all(14.0);

  /// Card padding for large screens
  static const EdgeInsets largeCardPadding = EdgeInsets.all(16.0);

  /// List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  /// Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.all(16);
}

/// Common size utilities
class AppSizes {
  AppSizes._();

  /// Icon sizes for different screen sizes
  static IconSizeData iconSizes(double screenWidth) {
    final isUltraSmall = AppSpacing.isUltraSmall(screenWidth);
    return IconSizeData(
      small: isUltraSmall ? 14.0 : 16.0,
      medium: isUltraSmall ? 20.0 : 24.0,
      large: isUltraSmall ? 24.0 : 28.0,
    );
  }

  /// Font sizes for different screen sizes
  static FontSizeData fontSizes(double screenWidth) {
    final isUltraSmall = AppSpacing.isUltraSmall(screenWidth);
    return FontSizeData(
      small: isUltraSmall ? 11.0 : 12.0,
      medium: isUltraSmall ? 12.0 : 14.0,
      large: isUltraSmall ? 14.0 : 16.0,
      title: isUltraSmall ? 16.0 : 18.0,
    );
  }
}

class IconSizeData {
  final double small;
  final double medium;
  final double large;

  const IconSizeData({
    required this.small,
    required this.medium,
    required this.large,
  });
}

class FontSizeData {
  final double small;
  final double medium;
  final double large;
  final double title;

  const FontSizeData({
    required this.small,
    required this.medium,
    required this.large,
    required this.title,
  });
}