import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 900;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 900;
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static double getScreenPadding(BuildContext context) {
    return isDesktop(context) ? 40.0 : 20.0;
  }

  static double getHorizontalPadding(BuildContext context) {
    return isDesktop(context) ? 40.0 : 16.0;
  }

  static double getVerticalPadding(BuildContext context) {
    return isDesktop(context) ? 32.0 : 16.0;
  }

  static double getMaxContentWidth(BuildContext context) {
    return isDesktop(context) ? 1200.0 : double.infinity;
  }

  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  static double getCardSpacing(BuildContext context) {
    return isDesktop(context) ? 24.0 : 16.0;
  }

  static double getFontSize(BuildContext context, {
    required double mobileSize,
    double? desktopSize,
  }) {
    return isDesktop(context) ? (desktopSize ?? mobileSize * 1.1) : mobileSize;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getHorizontalPadding(context),
      vertical: getVerticalPadding(context),
    );
  }

  static Widget buildResponsiveLayout({
    required BuildContext context,
    required Widget mobile,
    Widget? desktop,
    Widget? tablet,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }

  static double getChatMaxWidth(BuildContext context) {
    return isDesktop(context) ? 800.0 : double.infinity;
  }

  static double getAvatarSize(BuildContext context) {
    return isDesktop(context) ? 120.0 : 88.0;
  }

  static double getButtonHeight(BuildContext context) {
    return isDesktop(context) ? 56.0 : 48.0;
  }

  static double getInputBorderRadius(BuildContext context) {
    return isDesktop(context) ? 12.0 : 8.0;
  }
}
