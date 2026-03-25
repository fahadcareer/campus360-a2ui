import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dimentions/app_dimensions.dart';

class TextStyles {
  // Headings
  static TextStyle? h1;
  static TextStyle? h2;
  static TextStyle? h3;

  // Body
  static TextStyle? b1;
  static TextStyle? b1b;
  static TextStyle? b2;
  static TextStyle? b2b;
  static TextStyle? b3;
  static TextStyle? b3b;

  // Label
  static TextStyle? l1;
  static TextStyle? l1b;
  static TextStyle? l2;
  static TextStyle? l2b;

  static init() {
    const b = FontWeight.bold;

    // Define the base text style using GoogleFonts.inter
    final baseStyle = GoogleFonts.inter();

    h1 = baseStyle.copyWith(fontSize: AppDimensions.font(13), fontWeight: b);

    h2 = baseStyle.copyWith(fontSize: AppDimensions.font(12), fontWeight: b);

    h3 = baseStyle.copyWith(fontSize: AppDimensions.font(11), fontWeight: b);

    b1 = baseStyle.copyWith(fontSize: AppDimensions.font(10));
    b1b = b1!.copyWith(fontWeight: b);

    b2 = baseStyle.copyWith(fontSize: AppDimensions.font(8));
    b2b = b2!.copyWith(fontWeight: b);

    b3 = baseStyle.copyWith(fontSize: AppDimensions.font(7));
    b3b = b3!.copyWith(fontWeight: b);

    l1 = baseStyle.copyWith(fontSize: AppDimensions.font(6));
    l1b = l1!.copyWith(fontWeight: b);

    l2 = baseStyle.copyWith(fontSize: AppDimensions.font(4));
    l2b = l2!.copyWith(fontWeight: b);
  }
}
