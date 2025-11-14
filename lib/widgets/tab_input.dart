import 'package:flutter/material.dart';
import 'package:mitmui/utils/debouncer.dart';

class CustomInput extends StatefulWidget {
  final Function()? onTap;
  final Function(String)? onFieldSubmitted;
  final Function(String)? onUpdate;
  final Function(String)? onChanged;
  final Function(String)? onTapOutside;
  final Function()? onExtraInputChange;
  final String value;
  final bool isEnabled;
  final bool isExtra;
  final FocusNode? focusNode;
  final String flowId;

  const CustomInput({
    required this.flowId,
    this.onFieldSubmitted,
    this.onChanged,
    this.onTap,
    required this.value,
    this.onTapOutside,
    required this.onUpdate,
    this.focusNode,
    this.isEnabled = true,
    this.isExtra = false,
    this.onExtraInputChange,
    super.key,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  late final debouncer = Debouncer(const Duration(milliseconds: 350));

  @override
  void didUpdateWidget(covariant CustomInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flowId != widget.flowId) {
      _controller.text = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: false,
      canRequestFocus: false,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          if (widget.isExtra) {
            // widget.onExtraInputChange?.call();
          } else {
            // widget.onUpdate?.call(_controller.text);
          }
        }
      },
      child: TextFormField(
        controller: _controller,
        // focusNode: widget.focusNode,

        // enabled: isEnabled,
        style: TextStyle(
          fontSize: 14,
          color: widget.isEnabled ? Colors.white : Colors.grey[600],
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const .symmetric(horizontal: 8, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: .new(color: Colors.grey[600]!, width: 0.6),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: const .fromARGB(150, 117, 117, 117),
              width: 0.6,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(
              color: .fromARGB(210, 255, 167, 95),
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: .new(color: Colors.grey[800]!, width: 1),
          ),
        ),
        // onChanged: widget.onChanged,
        // onFieldSubmitted: widget.onFieldSubmitted,
        // onTap: widget.onTap,
        // onTapOutside: (event) {
        //   widget.onTapOutside?.call(_controller.text);
        // },
        onChanged: (v) {
          if (widget.isExtra) {
            widget.onExtraInputChange?.call();
          }
          debouncer.run(() {
            widget.onUpdate?.call(_controller.text);
          });
        },
        onTapOutside: (e) {
          // widget.onUpdate?.call(_controller.text);
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }
}
