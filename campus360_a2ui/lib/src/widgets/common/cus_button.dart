// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import '../../res/colors/colors.dart';
import '../../res/dimentions/app_dimensions.dart';
import '../../res/style/app_typography.dart';
import '../../res/style/text_style.dart';
import 'cus_container.dart';

class CustomButton extends StatelessWidget {
  final void Function()? onPressed;
  final BuildContext context;
  final String txt;
  final double? width;
  Color? prime;
  final Color? txtColor;
  final Color? borderColor;
  CustomButton({
    super.key,
    required this.onPressed,
    required this.context,
    required this.txt,
    this.width = double.infinity,
    this.prime,
    this.txtColor = AppColors.whiteColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    if (prime == null) {
      prime = Theme.of(context).primaryColor;
    } else {
      prime = prime;
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: prime,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor ?? prime!),
        ),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: CustomContainer(
        width: width,
        color: Colors.transparent, // Ensure container background is transparent
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.space(0.9)),
            child: textStyle(
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              text: txt,
              style: TextStyles.b3!.copyWith(color: txtColor),
            ),
          ),
        ),
      ),
    );
  }
}
