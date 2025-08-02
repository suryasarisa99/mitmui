import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomInput extends StatefulWidget {
  final Function(String)? onFieldSubmitted;
  final Function(String)? onChanged;
  final Function()? onTap;
  final Function(String)? onTab;
  final Function(String)? onTapOutside;
  final String value;
  final bool isEnabled;
  final FocusNode? focusNode;
  const CustomInput({
    this.onFieldSubmitted,
    this.onChanged,
    this.onTap,
    this.onTab,
    required this.value,
    this.onTapOutside,
    this.focusNode,
    this.isEnabled = true,
    super.key,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: false,
      canRequestFocus: false,
      onKeyEvent: (n, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.tab) {
          widget.onTab?.call(_controller.text);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextFormField(
        controller: _controller,
        focusNode: widget.focusNode,

        // enabled: isEnabled,
        style: TextStyle(
          fontSize: 14,
          color: widget.isEnabled ? Colors.white : Colors.grey[600],
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 11,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey[600]!, width: 0.6),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: const Color.fromARGB(150, 117, 117, 117),
              width: 0.6,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(
              color: Color.fromARGB(211, 174, 184, 252),
              width: 0.6,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
          ),
        ),
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onFieldSubmitted,
        onTap: widget.onTap,
        onTapOutside: (event) {
          widget.onTapOutside?.call(_controller.text);
        },
      ),
    );
  }
}
