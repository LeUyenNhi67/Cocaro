import 'package:flutter/material.dart';

class NeonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color glowColor;
  final List<Color> gradientColors;
  final IconData? icon;
  final double? width;

  const NeonButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.glowColor = const Color(0xFF00F2FE),
    this.gradientColors = const [Color(0xFF00C6FF), Color(0xFF0072FF)],
    this.icon,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isEnabled
                    ? gradientColors
                    : [Colors.grey.shade800, Colors.grey.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEnabled
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: isEnabled ? Colors.white : Colors.grey.shade500,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: isEnabled ? Colors.white : Colors.grey.shade500,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: isEnabled
                          ? const [
                              Shadow(
                                color: Colors.black38,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
