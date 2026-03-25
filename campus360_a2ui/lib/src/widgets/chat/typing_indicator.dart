import 'package:flutter/material.dart';
import '../../res/colors/colors.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dotColor = isDark
        ? AppColors.chatGptSecondaryText
        : AppColors.chatGptLightSecondaryText;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return _AnimatedDot(
          index: index,
          controller: _controller,
          color: dotColor,
        );
      }),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final int index;
  final AnimationController controller;
  final Color color;

  const _AnimatedDot({
    required this.index,
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double delay = index * 0.2;
        double value = (controller.value - delay) % 1.0;
        if (value < 0) value += 1.0;

        double opacity = 1.0;
        if (value < 0.2) {
          opacity = 0.3 + (value / 0.2) * 0.7;
        } else if (value < 0.4) {
          opacity = 1.0 - ((value - 0.2) / 0.2) * 0.7;
        } else {
          opacity = 0.3;
        }

        return Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
