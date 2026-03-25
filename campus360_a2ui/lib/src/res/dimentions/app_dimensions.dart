import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class AppDimensions {
  static double? maxContainerWidth;
  static double? miniContainerWidth;

  static bool? isLandscape;
  static double? padding;
  static double ratio = 0;

  static Size? size;

  static init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    final pixelDensity = mediaQuery.devicePixelRatio;

    // Aspect ratio calculation based on screen size
    ratio = width / height;
    ratio = (ratio) + ((pixelDensity + ratio) / 2);

    // Adjust ratio for small screens with high pixel density
    if (width <= 380 && pixelDensity >= 3) {
      ratio *= 0.85;
    }

    _initLargeScreens();
    _initSmallScreensHighDensity(mediaQuery);

    padding = ratio * 3;
  }

  static _initLargeScreens() {
    const safe = 2.4;

    // Further adjust ratio for large screens
    ratio *= 1.5;

    if (ratio > safe) {
      ratio = safe;
    }
  }

  static _initSmallScreensHighDensity(MediaQueryData mediaQuery) {
    final width = mediaQuery.size.width;

    // Check against different screen sizes
    if (width > 600 && ratio > 2.0) {
      ratio = 2.0;
    }
    if (width > 480 && ratio > 1.6) {
      ratio = 1.6;
    }
    if (width > 320 && ratio > 1.4) {
      ratio = 1.4;
    }
  }

  static String inString(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    final ps = ui.window.physicalSize;
    return """
      Width: $width | ${ps.width}
      Height: $height | ${ps.height}
      app_ratio: $ratio
      ratio: ${width / height}
      pixels: ${mediaQuery.devicePixelRatio}
    """;
  }

  static double space([double multiplier = 1.0]) {
    return (AppDimensions.padding ?? 0) * 3 * multiplier;
  }

  static double normalize(double unit) {
    return (AppDimensions.ratio * unit * 0.77) + unit;
  }

  static double font(double unit) {
    return (AppDimensions.ratio * unit * 0.125) + unit * 1.90;
  }
}
