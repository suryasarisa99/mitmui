import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mitmui/theme.dart';
import 'package:mitmui/utils/diff.dart';

class LineNumbers extends StatelessWidget {
  final ScrollController controller;
  final List<DiffLine> leftLines;
  final List<DiffLine> rightLines;
  final List<double> lineHeights; // Dynamic heights for each line
  final Color? diffBgColor;
  final Color? diffTextColor;
  final bool lazyLoad;

  const LineNumbers({
    super.key,
    required this.controller,
    required this.leftLines,
    required this.rightLines,
    required this.lineHeights,
    required this.lazyLoad,
    this.diffBgColor = const Color(0x1BFFC36A),
    this.diffTextColor = const Color(0xFFF57C00),
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.from(Theme.brightnessOf(context));
    final linesCount = max(leftLines.length, rightLines.length);
    final charWidth = 13.0;
    final double lineNumberWidth =
        (linesCount.toString().length * charWidth) + 2;

    if (lineHeights.isEmpty) {
      return SizedBox(width: lineNumberWidth);
    }

    return Container(
      width: lineNumberWidth,
      color: theme.surface,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.builder(
          /*
            - because of setting text height, creates gap at the top, so added padding 4 for top to sync
          */
          padding: EdgeInsets.only(top: !lazyLoad ? 4 : 0),
          controller: controller,
          itemCount: linesCount,
          physics: const ClampingScrollPhysics(),
          itemBuilder: (context, i) {
            final leftLine = leftLines[i];
            final rightLine = rightLines[i];

            final hasChange =
                leftLine.isDeleted ||
                leftLine.isInserted ||
                leftLine.isEmpty ||
                rightLine.isDeleted ||
                rightLine.isInserted ||
                rightLine.isEmpty ||
                (leftLine.wordDiffs != null && leftLine.wordDiffs!.isNotEmpty);

            Color? bgColor;
            Color? textColor = theme.text.withValues(alpha: 0.5);

            if (hasChange) {
              bgColor = diffBgColor;
              textColor = diffTextColor;
            }
            if (i > 9 && i < 15) {
              debugPrint(
                'line height for index $i line ${i + 1}: ${lineHeights[i]}',
              );
            }
            return Container(
              height: lineHeights[i],
              alignment: Alignment.topRight,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0x4DEFEFEF),
                    width: 0.5,
                  ),
                ),
              ),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: textColor,
                  fontSize: 12,
                  fontWeight: hasChange ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
