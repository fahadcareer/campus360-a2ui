import 'dart:math';
import 'package:flutter/widgets.dart';

class UI {
  static MediaQueryData? _mediaQueryData;
  static double? width;
  static double? height;
  static double? horizontal;
  static double? vertical;
  static EdgeInsets? padding;
  static EdgeInsets? viewInsets;

  static double? _safeAreaHorizontal;
  static double? _safeAreaVertical;
  static double? safeWidth;
  static double? safeHeight;

  static double? diagonal;

  static bool? xxs;
  static bool? xs;
  static bool? sm;
  static bool? md;
  static bool? xmd;
  static bool? lg;
  static bool? xl;
  static bool? xlg;
  static bool? xxlg;

  static void init(BuildContext context) {
    // Get the MediaQuery data
    _mediaQueryData = MediaQuery.of(context);

    // Initialize the screen checks based on size
    initChecks(_mediaQueryData!);

    // Set padding, viewInsets, width, and height
    padding = _mediaQueryData!.padding;
    viewInsets = _mediaQueryData!.viewInsets;
    width = _mediaQueryData!.size.width;
    height = _mediaQueryData!.size.height;

    // Horizontal and vertical percentages based on screen size
    horizontal = width! / 100;
    vertical = height! / 100;

    // Calculate safe areas (excluding padding areas)
    _safeAreaHorizontal =
        _mediaQueryData!.padding.left + _mediaQueryData!.padding.right;
    _safeAreaVertical =
        _mediaQueryData!.padding.top + _mediaQueryData!.padding.bottom;
    safeWidth = width! - _safeAreaHorizontal!;
    safeHeight = height! - _safeAreaVertical!;
  }

  static void initChecks(MediaQueryData query) {
    var size = query.size;

    // Calculate diagonal size of the screen
    diagonal = sqrt((size.width * size.width) + (size.height * size.height));

    // Set screen size breakpoints for adaptive layouts
    xxs = size.width > 300;
    xs = size.width > 360;
    sm = size.width > 480;
    md = size.width > 600;
    xmd = size.width > 720;
    lg = size.width > 980;
    xl = size.width > 1160;
    xlg = size.width > 1400;
    xxlg = size.width > 1700;
  }

  // Getter for MediaQuery data
  static MediaQueryData mediaQuery() => _mediaQueryData!;

  // Getter for screen size
  static Size getSize() => _mediaQueryData!.size;
}
