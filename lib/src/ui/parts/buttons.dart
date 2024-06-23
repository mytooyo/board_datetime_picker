import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    super.key,
    required this.icon,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
    this.buttonSize = 36,
    this.child,
  });

  final IconData icon;
  final Color? bgColor;
  final Color? fgColor;
  final void Function() onTap;
  final double buttonSize;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: buttonSize,
          width: buttonSize,
          alignment: Alignment.center,
          child: child ??
              Icon(
                icon,
                size: 20,
                color: fgColor,
              ),
        ),
      ),
    );
  }
}
