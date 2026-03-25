import 'package:flutter/material.dart';
import '../../res/dimentions/space.dart';
import '../../res/style/app_typography.dart';
import '../../res/style/text_style.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool backButton;
  final bool searchButton;
  // final BuildContext c; // Removed as context is available in build
  final void Function()? onTap;
  final String? title;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.backButton = false,
    this.searchButton = false,
    this.onTap,
    // required this.c,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      centerTitle: true,
      leading: backButton
          ? Padding(
              padding: Space.v ?? EdgeInsets.zero,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Material(
                  type: MaterialType.circle,
                  color: Theme.of(context).primaryColor,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Theme.of(
                      context,
                    ).floatingActionButtonTheme.foregroundColor,
                  ),
                ),
              ),
            )
          : null,
      title: GestureDetector(
        onTap: onTap,
        child: textStyle(
          text: '$title',
          style: TextStyles.b2!.copyWith(
            color: Theme.of(context).floatingActionButtonTheme.foregroundColor,
          ),
        ),
      ),
      actions: actions,
      elevation: 0.5,
      automaticallyImplyLeading: false, // Handle leading manually
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
