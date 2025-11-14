import 'dart:developer';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:mitmui/theme.dart';
import 'package:mitmui/utils/diff.dart';
import 'package:mitmui/widgets/compare/line_numbers.dart';

/*
* lazyLoad with ListView
  - causes issues with text selection
  - better performance with large texts

* non-lazyLoad with SelectableText.rich
  - better text selection
*/
class Compare extends ConsumerStatefulWidget {
  final String text1;
  final String text2;

  /// if true, uses ListView, but it causes issues with text selection.
  final bool lazyLoad;

  const Compare({
    super.key,
    required this.text1,
    required this.text2,
    this.lazyLoad = false,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CompareState();
}

class _CompareState extends ConsumerState<Compare> {
  List<DiffLine> leftLines = [];
  List<DiffLine> rightLines = [];
  int linesCount = 0;

  late LinkedScrollControllerGroup _scrollControllers;
  late ScrollController _lineNumberController;
  late ScrollController _leftController;
  late ScrollController _rightController;

  // Store calculated heights for each line
  List<double> lineHeights = [];
  // Store number of wrapped lines for each logical line (only for non-lazy mode)
  List<int> leftWrappedLines = [];
  List<int> rightWrappedLines = [];
  // Maximum width available for text content
  double maxTextWidth = 0;

  static const double _minLineHeight = 26.0;
  static const double _fontSize = 15.0;
  static const double _textHeight = _minLineHeight / _fontSize;

  // Reusable TextPainter for measurements
  late TextPainter _textPainter;

  @override
  void initState() {
    super.initState();
    _scrollControllers = LinkedScrollControllerGroup();
    _lineNumberController = _scrollControllers.addAndGet();
    _leftController = _scrollControllers.addAndGet();
    _rightController = _scrollControllers.addAndGet();

    // Initialize TextPainter
    _textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: const TextScaler.linear(1.0),
    );

    _compare();
  }

  void _compare() {
    final result = DiffUtils.get(widget.text1, widget.text2);
    setState(() {
      leftLines = result.left;
      rightLines = result.right;
      linesCount = Math.max(leftLines.length, rightLines.length);
    });
  }

  // Calculate height for a line based on actual text measurement
  double _calculateLineHeight(DiffLine line, double maxWidth) {
    if (line.isEmpty || line.text.isEmpty) return _minLineHeight;

    // Build the text span for this line
    final textSpan = TextSpan(
      text: line.text,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: _fontSize,
        fontWeight: FontWeight.w400,
        height: _textHeight,
      ),
    );

    // Configure TextPainter
    _textPainter.text = textSpan;
    _textPainter.maxLines = null; // Allow unlimited wrapping

    // Layout with the actual width available
    _textPainter.layout(maxWidth: maxWidth);

    // Get the actual height needed
    final actualHeight = _textPainter.height;
    return Math.max(_minLineHeight, actualHeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.from(Theme.brightnessOf(context));

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available width for each text panel
        final lineNumberWidth = (linesCount.toString().length * 13.0) + 2;
        final availableWidth = (constraints.maxWidth - lineNumberWidth - 8) / 2;

        // Recalculate line heights if width changed
        if (maxTextWidth != availableWidth && leftLines.isNotEmpty) {
          maxTextWidth = availableWidth;

          lineHeights = [];
          for (int i = 0; i < linesCount; i++) {
            final leftHeight = _calculateLineHeight(leftLines[i], maxTextWidth);
            final rightHeight = _calculateLineHeight(
              rightLines[i],
              maxTextWidth,
            );
            lineHeights.add(Math.max(leftHeight, rightHeight));
            if (!widget.lazyLoad) {
              final leftWrapped = (leftHeight / _minLineHeight).ceil();
              final rightWrapped = (rightHeight / _minLineHeight).ceil();
              leftWrappedLines.add(leftWrapped);
              rightWrappedLines.add(rightWrapped);
            }
          }
        }
        return Container(
          color: theme.surface,
          padding: const EdgeInsets.all(0),
          child: (leftLines.isEmpty && rightLines.isEmpty)
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    LineNumbers(
                      controller: _lineNumberController,
                      leftLines: leftLines,
                      rightLines: rightLines,
                      lineHeights: lineHeights,
                      lazyLoad: widget.lazyLoad,
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _buildSideView(
                        lines: leftLines,
                        isLeft: true,
                        theme: theme,
                        controller: _leftController,
                        maxWidth: maxTextWidth,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _buildSideView(
                        lines: rightLines,
                        isLeft: false,
                        theme: theme,
                        controller: _rightController,
                        maxWidth: maxTextWidth,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSideView({
    required List<DiffLine> lines,
    required bool isLeft,
    required AppColors theme,
    required ScrollController controller,
    required double maxWidth,
  }) {
    if (lineHeights.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.lazyLoad) {
      // Use ListView for lazy loading
      return ListView.builder(
        controller: controller,
        itemCount: linesCount,
        itemBuilder: (context, i) {
          final line = lines[i];
          final lineSpans = _buildDiffLine(line, i, isLeft, theme);

          return Container(
            // padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color.fromARGB(82, 255, 255, 255),
                  width: 0.4,
                ),
              ),
            ),
            height: lineHeights[i],
            child: RichText(
              text: TextSpan(
                children: lineSpans,
                style: const TextStyle(height: _textHeight),
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          );
        },
      );
    }

    // For non-lazy load: build all spans with padding
    final allSpans = <InlineSpan>[];
    final wrappedLines = isLeft ? leftWrappedLines : rightWrappedLines;
    final otherWrappedLines = isLeft ? rightWrappedLines : leftWrappedLines;

    for (int i = 0; i < linesCount; i++) {
      final line = lines[i];
      final lineSpans = _buildDiffLine(line, i, isLeft, theme);

      // Add the actual line content
      allSpans.addAll(lineSpans);

      // Calculate how many extra newlines to add
      final thisLineCount = wrappedLines[i];
      final otherLineCount = otherWrappedLines[i];
      final diff = otherLineCount - thisLineCount;

      // Add newlines: 1 for line break + extra for padding
      final newlinesToAdd = 1 + (diff > 0 ? diff : 0);
      if (newlinesToAdd > 1) {
        log(
          'Line $i: thisLineCount=$thisLineCount, otherLineCount=$otherLineCount, diff=$diff, newlinesToAdd=$newlinesToAdd',
        );
      }
      // Add newlines (except after the last line)
      if (i < linesCount - 1 || diff > 0) {
        allSpans.add(TextSpan(text: '\n' * newlinesToAdd));
      }
    }

    return SingleChildScrollView(
      controller: controller,
      child: SelectableText.rich(
        TextSpan(children: allSpans),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: _fontSize,
          fontWeight: FontWeight.w400,
          height: _textHeight,
        ),
      ),
    );
  }

  List<InlineSpan> _buildDiffLine(
    DiffLine line,
    int index,
    bool isLeft,
    AppColors theme,
  ) {
    List<InlineSpan> spans;

    if (line.isEmpty) {
      // For empty lines, just return a space
      spans = [
        TextSpan(
          text: ' ',
          style: TextStyle(
            fontFamily: 'monospace',
            color: theme.text,
            fontSize: _fontSize,
            height: _textHeight,
            fontWeight: FontWeight.w400,
          ),
        ),
      ];
    } else if (line.wordDiffs != null && line.wordDiffs!.isNotEmpty) {
      spans = _buildHighlightedText(line.wordDiffs!, isLeft, theme);
    } else {
      spans = [
        TextSpan(
          text: line.text,
          style: TextStyle(
            fontFamily: 'monospace',
            color: theme.text,
            fontSize: _fontSize,
            height: _textHeight,
            fontWeight: FontWeight.w400,
          ),
        ),
      ];
    }

    return spans;
  }

  List<InlineSpan> _buildHighlightedText(
    List<Diff> wordDiffs,
    bool isLeft,
    AppColors theme,
  ) {
    final spans = <InlineSpan>[];

    for (final diff in wordDiffs) {
      Color? bgColor;
      Color? textColor = theme.text;
      // FontWeight? fontWeight;
      const double fontSize = _fontSize;

      switch (diff.operation) {
        case DIFF_EQUAL:
          break;
        case DIFF_DELETE:
        case DIFF_INSERT:
          bgColor = const Color(0xFF006DC1);
          textColor = const Color(0xFFFFFFFF);
          break;
      }

      final shouldShow =
          (diff.operation == DIFF_EQUAL) ||
          (diff.operation == DIFF_DELETE && isLeft) ||
          (diff.operation == DIFF_INSERT && !isLeft);

      if (shouldShow) {
        spans.add(
          TextSpan(
            text: diff.text,
            style: TextStyle(
              backgroundColor: bgColor,
              color: textColor,
              fontFamily: 'monospace',
              fontSize: fontSize,
              // fontWeight: fontWeight ?? FontWeight.w400,
              height: _textHeight,
            ),
          ),
        );
      }
    }

    return spans;
  }

  @override
  void dispose() {
    _textPainter.dispose();
    _lineNumberController.dispose();
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }
}
