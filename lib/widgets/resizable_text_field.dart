// lib/resizable_text_field.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter/services.dart';

class ResizableTextField extends StatefulWidget {
  const ResizableTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.minWidth = 50,
    this.maxWidth = 200,
    this.style,
    this.hintText = '',
    this.borderRadius,
    this.focusedBorderColor = Colors.blue,
    this.unfocusedBorderColor = Colors.grey,
    this.onChanged,
    this.onlyNumbers = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final double minWidth;
  final double maxWidth;
  final TextStyle? style;
  final String hintText;
  final BorderRadius? borderRadius;
  final Color focusedBorderColor;
  final Color unfocusedBorderColor;
  final ValueChanged<String>? onChanged;
  final bool onlyNumbers;

  @override
  State<ResizableTextField> createState() => _ResizableTextFieldState();
}

class _ResizableTextFieldState extends State<ResizableTextField> {
  // Use provided instances or create our own.
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  bool _isFocused = false;
  double _currentWidth = 0;

  // Padding inside the text field, plus a little extra for the cursor.
  static const double _textPadding = 8.0;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    // Set initial width
    _currentWidth = _calculateWidth(_controller.text);

    // Listen for text changes to resize the field.
    _controller.addListener(_handleTextChanged);
    // Listen for focus changes to update the border color.
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _focusNode.removeListener(_handleFocusChanged);

    // Dispose of our own instances, but not the ones provided.
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    super.dispose();
  }

  void _handleTextChanged() {
    final newWidth = _calculateWidth(_controller.text);
    if (newWidth != _currentWidth) {
      setState(() {
        _currentWidth = newWidth;
      });
    }
    // Forward the onChanged event if a callback was provided.
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  double _calculateWidth(String text) {
    // Use a TextPainter to measure the text's width.
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    late final double textWidth;
    if (text.isEmpty) {
      // If the text is empty, use the hint text width as a minimum.
      final x = TextPainter(
        text: TextSpan(
          text: widget.hintText,
          style: widget.style?.copyWith(color: Colors.transparent),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      textWidth = x.size.width;
    } else {
      textWidth = textPainter.size.width;
    }

    // Clamp the calculated width between the min and max width constraints.
    return math.max(widget.minWidth, math.min(widget.maxWidth, textWidth + 24));
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        widget.style ??
        Theme.of(context).textTheme.titleMedium ??
        const TextStyle();

    // this padding for border width increases when focused cause little shift,so fix it by this
    final double horizontalPaddingCompensation = (_isFocused
        ? 0.0
        : 0.5); // Add 0.5 when unfocused
    final double verticalPaddingCompensation = (_isFocused
        ? 0.0
        : 0.5); // Add 0.5 when unfocused

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: _currentWidth,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPaddingCompensation,
        vertical: verticalPaddingCompensation,
      ),
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: _isFocused
              ? widget.focusedBorderColor
              : widget.unfocusedBorderColor,
          width: _isFocused ? 1.5 : 1.0,
        ),
      ),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        style: effectiveStyle,
        maxLines: 1,
        inputFormatters: [
          if (widget.onlyNumbers) FilteringTextInputFormatter.digitsOnly,
          // FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9 ]*$')),
        ],
        keyboardType: widget.onlyNumbers
            ? TextInputType.number
            : TextInputType.text,
        decoration: InputDecoration(
          // This is the key to disabling the default border.
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isDense: true,
          hintText: widget.hintText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 6,
          ),
        ),
      ),
    );
  }
}
