import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:mitmui/models/http_compare_message.dart';
import 'package:mitmui/models/http_syntax_colors.dart';
import 'package:mitmui/theme.dart';
import 'package:mitmui/utils/diff.dart';
import 'package:mitmui/utils/statusCode.dart';
import 'package:mitmui/widgets/compare/line_numbers.dart';

// Add this enum and class to your project

enum HttpSectionType {
  firstLine, // Request line or Status line
  headers, // Header section
  body, // Body content
  emptyLine, // Empty line separator
}

class HttpSection {
  final HttpSectionType type;
  final int startLine;
  final int endLine;
  final bool isRequest;
  final List<List<String>>? headers;

  HttpSection({
    required this.type,
    required this.startLine,
    required this.endLine,
    this.isRequest = false,
    this.headers,
  });
}

class HttpCompare extends StatefulWidget {
  final HttpCompareMessage message1;
  final HttpCompareMessage message2;
  final bool lazyLoad;
  final HttpSyntaxColors? syntaxColors;

  const HttpCompare({
    super.key,
    required this.message1,
    required this.message2,
    this.lazyLoad = false,
    this.syntaxColors,
  });

  @override
  State<StatefulWidget> createState() => _HttpCompareState();
}

class _HttpCompareState extends State<HttpCompare> {
  List<DiffLine> leftLines = [];
  List<DiffLine> rightLines = [];
  int linesCount = 0;

  late LinkedScrollControllerGroup _scrollControllers;
  late ScrollController _lineNumberController;
  late ScrollController _leftController;
  late ScrollController _rightController;

  List<double> lineHeights = [];
  List<int> leftWrappedLines = [];
  List<int> rightWrappedLines = [];
  double maxTextWidth = 0;

  static const double _minLineHeight = 26.0;
  static const double _fontSize = 17.0;
  static const double _textHeight = _minLineHeight / _fontSize;

  late TextPainter _textPainter;
  late HttpSyntaxColors _colors;

  // Track which section each line belongs to
  List<HttpSection> leftSections = [];
  List<HttpSection> rightSections = [];

  @override
  void initState() {
    super.initState();
    _scrollControllers = LinkedScrollControllerGroup();
    _lineNumberController = _scrollControllers.addAndGet();
    _leftController = _scrollControllers.addAndGet();
    _rightController = _scrollControllers.addAndGet();

    _textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: const TextScaler.linear(1.0),
    );

    _colors = widget.syntaxColors ?? const HttpSyntaxColors();

    _compare();
  }

  void _compare() {
    // Convert HttpMessage to text format for diffing
    final text1 = _httpMessageToText(widget.message1);
    final text2 = _httpMessageToText(widget.message2);

    // Calculate sections for syntax highlighting
    leftSections = _calculateSections(widget.message1);
    rightSections = _calculateSections(widget.message2);

    final result = DiffUtils.get(text1, text2);
    setState(() {
      leftLines = result.left;
      rightLines = result.right;
      linesCount = math.max(leftLines.length, rightLines.length);
    });
  }

  String _httpMessageToText(HttpCompareMessage msg) {
    final buffer = StringBuffer();

    // First line
    if (msg.isRequest) {
      buffer.writeln('${msg.method} ${msg.url} ${msg.httpVersion}');
    } else {
      buffer.writeln(
        '${msg.httpVersion} ${msg.statusCode} ${msg.statusMessage}',
      );
    }

    // Headers
    for (var header in msg.headers) {
      buffer.writeln('${header[0]}: ${header[1]}');
    }

    // Empty line before body
    buffer.writeln();

    // Body
    buffer.write(msg.body);

    return buffer.toString();
  }

  List<HttpSection> _calculateSections(HttpCompareMessage msg) {
    final sections = <HttpSection>[];
    int lineIndex = 0;

    // First line (request/status line)
    sections.add(
      HttpSection(
        type: HttpSectionType.firstLine,
        startLine: lineIndex,
        endLine: lineIndex,
        isRequest: msg.isRequest,
      ),
    );
    lineIndex++;

    // Headers
    final headerCount = msg.headers.length;
    if (headerCount > 0) {
      sections.add(
        HttpSection(
          type: HttpSectionType.headers,
          startLine: lineIndex,
          endLine: lineIndex + headerCount - 1,
          headers: msg.headers,
        ),
      );
      lineIndex += headerCount;
    }

    // Empty line
    sections.add(
      HttpSection(
        type: HttpSectionType.emptyLine,
        startLine: lineIndex,
        endLine: lineIndex,
      ),
    );
    lineIndex++;

    // Body
    final bodyLines = msg.body.split('\n').length;
    sections.add(
      HttpSection(
        type: HttpSectionType.body,
        startLine: lineIndex,
        endLine: lineIndex + bodyLines - 1,
      ),
    );

    return sections;
  }

  HttpSection _getSectionForLine(int lineIndex, List<HttpSection> sections) {
    for (final section in sections) {
      if (lineIndex >= section.startLine && lineIndex <= section.endLine) {
        return section;
      }
    }
    return HttpSection(
      type: HttpSectionType.body,
      startLine: lineIndex,
      endLine: lineIndex,
    );
  }

  double _calculateLineHeight(DiffLine line, double maxWidth) {
    if (line.isEmpty || line.text.isEmpty) return _minLineHeight;

    final textSpan = TextSpan(
      text: line.text,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: _fontSize,
        fontWeight: FontWeight.w400,
        height: _textHeight,
      ),
    );

    _textPainter.text = textSpan;
    _textPainter.maxLines = null;
    _textPainter.layout(maxWidth: maxWidth);

    final actualHeight = _textPainter.height;
    return math.max(_minLineHeight, actualHeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.from(Theme.brightnessOf(context));

    return LayoutBuilder(
      builder: (context, constraints) {
        final lineNumberWidth = (linesCount.toString().length * 13.0) + 2;
        /*
        -8 for adjustment, can't know some differences may occur to fix that.
        -16 for padding
        */
        final availableWidth =
            (constraints.maxWidth - lineNumberWidth - 8 - 16) / 2;

        if (maxTextWidth != availableWidth && leftLines.isNotEmpty) {
          maxTextWidth = availableWidth;

          lineHeights = [];
          leftWrappedLines = [];
          rightWrappedLines = [];

          for (int i = 0; i < linesCount; i++) {
            final leftHeight = _calculateLineHeight(leftLines[i], maxTextWidth);
            final rightHeight = _calculateLineHeight(
              rightLines[i],
              maxTextWidth,
            );
            lineHeights.add(math.max(leftHeight, rightHeight));

            if (!widget.lazyLoad) {
              final leftWrapped = (leftHeight / _minLineHeight).ceil();
              final rightWrapped = (rightHeight / _minLineHeight).ceil();
              leftWrappedLines.add(leftWrapped);
              rightWrappedLines.add(rightWrapped);
            }
          }
        }
        final containerHeight = math.min(
          lineHeights.reduce((a, b) => a + b) + 8,
          constraints.maxHeight,
        );
        debugPrint('Container height: $containerHeight');

        return Container(
          color: theme.surface,
          height: containerHeight,
          padding: const .all(0),
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
                    // const VerticalDivider(width: 1),
                    Expanded(
                      child: _buildSideView(
                        lines: leftLines,
                        sections: leftSections,
                        isLeft: true,
                        theme: theme,
                        controller: _leftController,
                        maxWidth: maxTextWidth,
                      ),
                    ),
                    SizedBox(child: const VerticalDivider(width: 1)),
                    Expanded(
                      child: _buildSideView(
                        lines: rightLines,
                        sections: rightSections,
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
    required List<HttpSection> sections,
    required bool isLeft,
    required AppColors theme,
    required ScrollController controller,
    required double maxWidth,
  }) {
    if (lineHeights.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.lazyLoad) {
      return ListView.builder(
        controller: controller,
        itemCount: linesCount,
        itemBuilder: (context, i) {
          final line = lines[i];
          final section = _getSectionForLine(i, sections);
          final lineSpans = _buildHttpLine(line, section, i, isLeft, theme);

          return Container(
            padding: const .only(left: 8.0),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: .fromARGB(82, 255, 255, 255),
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

    // Non-lazy load
    final allSpans = <InlineSpan>[];
    final wrappedLines = isLeft ? leftWrappedLines : rightWrappedLines;
    final otherWrappedLines = isLeft ? rightWrappedLines : leftWrappedLines;

    for (int i = 0; i < linesCount; i++) {
      final line = lines[i];
      final section = _getSectionForLine(i, sections);
      final lineSpans = _buildHttpLine(line, section, i, isLeft, theme);

      allSpans.addAll(lineSpans);

      final thisLineCount = wrappedLines[i];
      final otherLineCount = otherWrappedLines[i];
      final diff = otherLineCount - thisLineCount;
      final newlinesToAdd = 1 + (diff > 0 ? diff : 0);

      if (i < linesCount - 1 || diff > 0) {
        allSpans.add(TextSpan(text: '\n' * newlinesToAdd));
      }
    }

    return SingleChildScrollView(
      controller: controller,

      child: Padding(
        padding: const .only(left: 8.0),
        child: SelectableText.rich(
          TextSpan(children: allSpans),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: _fontSize,
            fontWeight: FontWeight.w400,
            height: _textHeight,
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildHttpLine(
    DiffLine line,
    HttpSection section,
    int index,
    bool isLeft,
    AppColors theme,
  ) {
    if (line.isEmpty) {
      return [
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
    }

    // Build syntax-highlighted spans based on section type
    final spans = <InlineSpan>[];

    if (line.wordDiffs != null && line.wordDiffs!.isNotEmpty) {
      // Apply both syntax highlighting and diff highlighting
      spans.addAll(
        _buildHighlightedHttpText(line.wordDiffs!, section, isLeft, theme),
      );
    } else {
      // Just syntax highlighting
      spans.addAll(
        _applySyntaxHighlighting(line.text, section, theme, hasDiff: false),
      );
    }

    return spans;
  }

  List<InlineSpan> _buildHighlightedHttpText(
    List<Diff> wordDiffs,
    HttpSection section,
    bool isLeft,
    AppColors theme,
  ) {
    final spans = <InlineSpan>[];

    for (final diff in wordDiffs) {
      final shouldShow =
          (diff.operation == DIFF_EQUAL) ||
          (diff.operation == DIFF_DELETE && isLeft) ||
          (diff.operation == DIFF_INSERT && !isLeft);

      if (shouldShow) {
        final hasDiff =
            diff.operation == DIFF_DELETE || diff.operation == DIFF_INSERT;

        // Apply syntax highlighting with diff background
        final syntaxSpans = _applySyntaxHighlighting(
          diff.text,
          section,
          theme,
          hasDiff: hasDiff,
        );

        spans.addAll(syntaxSpans);
      }
    }

    return spans;
  }

  List<InlineSpan> _applySyntaxHighlighting(
    String text,
    HttpSection section,
    AppColors theme, {
    required bool hasDiff,
  }) {
    final spans = <InlineSpan>[];
    Color? bgColor = hasDiff ? _colors.diffHighlight : null;
    Color textColor = hasDiff ? _colors.diffText : theme.text;

    switch (section.type) {
      case HttpSectionType.firstLine:
        // Parse first line (request or status line)
        if (section.isRequest) {
          // Request line: GET /path?key=value HTTP/1.1
          final parts = text.split(' ');
          if (parts.isNotEmpty) {
            // Method (GET, POST, etc.)
            spans.add(
              TextSpan(
                text: parts[0],
                style: TextStyle(
                  color: hasDiff ? _colors.diffText : getMethodColor(parts[0]),
                  backgroundColor: bgColor,
                  fontFamily: 'monospace',
                  fontSize: _fontSize,
                  height: _textHeight,
                ),
              ),
            );

            if (parts.length > 1) {
              spans.add(
                TextSpan(
                  text: ' ',
                  style: TextStyle(backgroundColor: bgColor),
                ),
              );

              // URL with query parameters
              final url = parts[1];
              spans.addAll(_highlightUrl(url, hasDiff, bgColor));

              if (parts.length > 2) {
                spans.add(
                  TextSpan(
                    text: ' ',
                    style: TextStyle(backgroundColor: bgColor),
                  ),
                );

                // HTTP version
                spans.add(
                  TextSpan(
                    text: parts[2],
                    style: TextStyle(
                      color: hasDiff ? _colors.diffText : _colors.httpVersion,
                      backgroundColor: bgColor,
                      fontFamily: 'monospace',
                      fontSize: _fontSize,
                      height: _textHeight,
                    ),
                  ),
                );
              }
            }
          }
        } else {
          // Status line: HTTP/1.1 200 OK
          final parts = text.split(' ');
          if (parts.isNotEmpty) {
            // HTTP version
            spans.add(
              TextSpan(
                text: parts[0],
                style: TextStyle(
                  color: hasDiff ? _colors.diffText : _colors.httpVersion,
                  backgroundColor: bgColor,
                  fontFamily: 'monospace',
                  fontSize: _fontSize,
                  height: _textHeight,
                ),
              ),
            );

            if (parts.length > 1) {
              spans.add(
                TextSpan(
                  text: ' ',
                  style: TextStyle(backgroundColor: bgColor),
                ),
              );

              // Status code
              final statusCodeClr = getStatusCodeColor(
                int.tryParse(parts[1]) ?? 0,
              );
              spans.add(
                TextSpan(
                  text: parts[1],
                  style: TextStyle(
                    color: hasDiff ? _colors.diffText : statusCodeClr,
                    backgroundColor: bgColor,
                    fontFamily: 'monospace',
                    fontSize: _fontSize,
                    height: _textHeight,
                  ),
                ),
              );

              if (parts.length > 2) {
                spans.add(
                  TextSpan(
                    text: ' ',
                    style: TextStyle(backgroundColor: bgColor),
                  ),
                );

                // Status message
                spans.add(
                  TextSpan(
                    text: parts.sublist(2).join(' '),
                    style: TextStyle(
                      color: hasDiff ? _colors.diffText : statusCodeClr,
                      backgroundColor: bgColor,
                      fontFamily: 'monospace',
                      fontSize: _fontSize,
                      height: _textHeight,
                    ),
                  ),
                );
              }
            }
          }
        }
        break;

      case HttpSectionType.headers:
        // Header: key: value
        final colonIndex = text.indexOf(':');
        if (colonIndex > 0) {
          final key = text.substring(0, colonIndex);
          final value = text.substring(colonIndex + 1).trim();

          // Check if this is a Cookie header
          final isCookie =
              key.toLowerCase() == 'cookie' ||
              key.toLowerCase() == 'set-cookie';

          // Header key
          spans.add(
            TextSpan(
              text: key,
              style: TextStyle(
                color: hasDiff ? _colors.diffText : _colors.headerKey,
                backgroundColor: bgColor,
                fontFamily: 'monospace',
                fontSize: _fontSize,
                height: _textHeight,
              ),
            ),
          );

          spans.add(
            TextSpan(
              text: ': ',
              style: TextStyle(
                color: textColor,
                backgroundColor: bgColor,
                fontFamily: 'monospace',
                fontSize: _fontSize,
                height: _textHeight,
              ),
            ),
          );

          // Header value (with special handling for cookies)
          if (isCookie) {
            spans.addAll(_highlightCookies(value, hasDiff, bgColor));
          } else {
            spans.add(
              TextSpan(
                text: value,
                style: TextStyle(
                  color: hasDiff ? _colors.diffText : _colors.headerValue,
                  backgroundColor: bgColor,
                  fontFamily: 'monospace',
                  fontSize: _fontSize,
                  height: _textHeight,
                ),
              ),
            );
          }
        } else {
          // Fallback if no colon found
          spans.add(
            TextSpan(
              text: text,
              style: TextStyle(
                color: textColor,
                backgroundColor: bgColor,
                fontFamily: 'monospace',
                fontSize: _fontSize,
                height: _textHeight,
              ),
            ),
          );
        }
        break;

      case HttpSectionType.body:
        // Body - single color
        spans.add(
          TextSpan(
            text: text,
            style: TextStyle(
              color: hasDiff ? _colors.diffText : _colors.body,
              backgroundColor: bgColor,
              fontFamily: 'monospace',
              fontSize: _fontSize,
              height: _textHeight,
            ),
          ),
        );
        break;

      case HttpSectionType.emptyLine:
        // Empty line
        spans.add(
          TextSpan(
            text: text.isEmpty ? ' ' : text,
            style: TextStyle(
              color: textColor,
              backgroundColor: bgColor,
              fontFamily: 'monospace',
              fontSize: _fontSize,
              height: _textHeight,
            ),
          ),
        );
        break;
    }

    return spans;
  }

  List<InlineSpan> _highlightUrl(String url, bool hasDiff, Color? bgColor) {
    final spans = <InlineSpan>[];

    // Split URL into path and query
    final queryIndex = url.indexOf('?');
    if (queryIndex < 0) {
      // No query params
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: hasDiff ? _colors.diffText : _colors.url,
            backgroundColor: bgColor,
            fontFamily: 'monospace',
            fontSize: _fontSize,
            height: _textHeight,
          ),
        ),
      );
    } else {
      // Path
      spans.add(
        TextSpan(
          text: url.substring(0, queryIndex),
          style: TextStyle(
            color: hasDiff ? _colors.diffText : _colors.url,
            backgroundColor: bgColor,
            fontFamily: 'monospace',
            fontSize: _fontSize,
            height: _textHeight,
          ),
        ),
      );

      spans.add(
        TextSpan(
          text: '?',
          style: TextStyle(
            color: hasDiff ? _colors.diffText : _colors.url,
            backgroundColor: bgColor,
          ),
        ),
      );

      // Query parameters
      final query = url.substring(queryIndex + 1);
      final params = query.split('&');

      for (int i = 0; i < params.length; i++) {
        final param = params[i];
        final eqIndex = param.indexOf('=');

        if (eqIndex > 0) {
          // Key
          spans.add(
            TextSpan(
              text: param.substring(0, eqIndex),
              style: TextStyle(
                color: hasDiff ? _colors.diffText : _colors.urlQueryKey,
                backgroundColor: bgColor,
                fontFamily: 'monospace',
                fontSize: _fontSize,
                height: _textHeight,
              ),
            ),
          );

          spans.add(
            TextSpan(
              text: '=',
              style: TextStyle(color: Colors.grey, backgroundColor: bgColor),
            ),
          );

          // Value
          spans.add(
            TextSpan(
              text: param.substring(eqIndex + 1),
              style: TextStyle(
                color: hasDiff ? _colors.diffText : _colors.urlQueryValue,
                backgroundColor: bgColor,
                fontFamily: 'monospace',
                fontSize: _fontSize,
                height: _textHeight,
              ),
            ),
          );
        } else {
          spans.add(
            TextSpan(
              text: param,
              style: TextStyle(
                color: hasDiff ? _colors.diffText : _colors.urlQueryKey,
                backgroundColor: bgColor,
                fontFamily: 'monospace',
                fontSize: _fontSize,
                height: _textHeight,
              ),
            ),
          );
        }

        if (i < params.length - 1) {
          spans.add(
            TextSpan(
              text: '&',
              style: TextStyle(color: Colors.grey, backgroundColor: bgColor),
            ),
          );
        }
      }
    }

    return spans;
  }

  List<InlineSpan> _highlightCookies(
    String cookieValue,
    bool hasDiff,
    Color? bgColor,
  ) {
    final spans = <InlineSpan>[];
    final cookies = cookieValue.split(';');

    for (int i = 0; i < cookies.length; i++) {
      final cookie = cookies[i].trim();
      final eqIndex = cookie.indexOf('=');

      if (eqIndex > 0) {
        // Cookie key
        spans.add(
          TextSpan(
            text: cookie.substring(0, eqIndex),
            style: TextStyle(
              color: hasDiff ? _colors.diffText : _colors.cookieKey,
              backgroundColor: bgColor,
              fontFamily: 'monospace',
              fontSize: _fontSize,
              height: _textHeight,
            ),
          ),
        );

        spans.add(
          TextSpan(
            text: '=',
            style: TextStyle(color: Colors.grey, backgroundColor: bgColor),
          ),
        );

        // Cookie value
        spans.add(
          TextSpan(
            text: cookie.substring(eqIndex + 1),
            style: TextStyle(
              color: hasDiff ? _colors.diffText : _colors.cookieValue,
              backgroundColor: bgColor,
              fontFamily: 'monospace',
              fontSize: _fontSize,
              height: _textHeight,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: cookie,
            style: TextStyle(
              color: hasDiff ? _colors.diffText : _colors.cookieKey,
              backgroundColor: bgColor,
              fontFamily: 'monospace',
              fontSize: _fontSize,
              height: _textHeight,
            ),
          ),
        );
      }

      if (i < cookies.length - 1) {
        spans.add(
          TextSpan(
            text: '; ',
            style: TextStyle(
              color: hasDiff ? _colors.diffText : _colors.headerValue,
              backgroundColor: bgColor,
              fontFamily: 'monospace',
              fontSize: _fontSize,
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
