import 'package:flutter/material.dart';

class SmIconButton extends StatelessWidget {
  const SmIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 24.0,
    this.btnSize = 24.0,
    this.color,
    this.splashRadius = 20.0,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double btnSize;
  final Color? color;
  final double splashRadius;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      splashRadius: splashRadius,
      constraints: BoxConstraints(minWidth: btnSize, minHeight: btnSize),
      color: Colors.red,
      padding: EdgeInsets.zero,
      // style: ButtonStyle(
      //   iconColor: WidgetStateProperty.resolveWith((states) {
      //     print("states: $states");
      //     return states.contains(WidgetState.pressed)
      //         ? Colors.red
      //         : (color ?? Colors.grey);
      //   }),
      // ),
      icon: Icon(icon, size: size, color: color ?? Colors.grey),
    );
  }
}
