import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class CustomContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final Widget? child;
  final EdgeInsets? padding;
  final Alignment? alignment;
  final bool cartDes;
  final bool cartGra;
  final bool iconGra;
  final bool titleCart;
  final bool useDottedBorder;
  final Color? borderColor;
  const CustomContainer({
    Key? key,
    this.color = Colors.white,
    this.width,
    this.height,
    this.child,
    this.padding,
    this.alignment,
    this.cartDes = false,
    this.cartGra = false,
    this.iconGra = false,
    this.titleCart = false,
    this.useDottedBorder = false,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    BoxDecoration fullDesign = BoxDecoration(
      color: color,
      borderRadius: BorderRadius.all(Radius.circular(8)),
    );

    BoxDecoration cartDesign = BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade200,
          // blurRadius:,
        ),
      ],
      color: color,
      borderRadius: BorderRadius.all(Radius.circular(11)),
    );

    BoxDecoration dotdesign = BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.all(Radius.circular(11)),
    );

    BoxDecoration iconDesign = BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).primaryColor),
    );

    ShapeDecoration cartLinearGradient = ShapeDecoration(
      gradient: LinearGradient(
        begin: Alignment(0.99, -0.16),
        end: Alignment(-0.99, 0.16),
        colors: [
          Theme.of(context).colorScheme.surface,
          Theme.of(context).colorScheme.surface,
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    BoxDecoration titleCartGradient = BoxDecoration(
      color: Theme.of(context).primaryColor,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(5),
        topRight: Radius.circular(5),
      ),
    );
    return Container(
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      child: cartGra && useDottedBorder
          ? DottedBorder(
              options: RectDottedBorderOptions(
                color: Theme.of(context).primaryColor,
                dashPattern: [6, 3],
              ),
              child: Container(
                width: width,
                height: height,
                decoration: dotdesign,
                child: child,
              ),
            )
          : Container(
              decoration: cartDes
                  ? cartDesign
                  : cartGra
                  ? cartLinearGradient
                  : iconGra
                  ? iconDesign
                  : titleCart
                  ? titleCartGradient
                  : fullDesign,
              width: width,
              height: height,
              padding: padding,
              alignment: alignment,
              child: child,
            ),
    );
  }
}
