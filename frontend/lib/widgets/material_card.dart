import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class MaterialCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? color;
  final Color? shadowColor;

  const MaterialCard({
    Key? key,
    required this.child,
    this.padding,
    this.elevation,
    this.color,
    this.shadowColor,
  }) : super(key: key);

  const MaterialCard.elevated({
    Key? key,
    required this.child,
    this.padding,
    this.color,
    this.shadowColor,
  })  : elevation = 4,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 1,
      color: color ?? AppColors.surface,
      shadowColor: shadowColor ?? AppColors.onSurface.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );
  }
}
