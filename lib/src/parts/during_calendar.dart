import 'package:flutter/material.dart';

class DuringCalendarWidget extends StatelessWidget {
  const DuringCalendarWidget({
    super.key,
    required this.closeKeyboard,
    required this.backgroundColor,
    required this.textColor,
  });

  final void Function() closeKeyboard;
  final Color backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: closeKeyboard,
      child: Container(
        color: backgroundColor,
        alignment: Alignment.center,
        child: Opacity(
          opacity: 0.6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_hide_rounded,
                size: 56,
                color: textColor,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Close Keyboard',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
