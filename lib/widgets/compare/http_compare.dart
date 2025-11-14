import 'dart:developer';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:mitmui/models/flow.dart';
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

/// Represents an HTTP message (request or response) with structured parts
class HttpMessage {
  final String? method; // GET, POST, etc. (null for response)
  final String? url; // Full URL (null for response)
  final String? statusCode; // 200, 404, etc. (null for request)
  final String? statusMessage; // OK, Not Found, etc. (null for request)
  final String httpVersion; // HTTP/1.1, HTTP/2, etc.
  final List<List<String>> headers; // Header key-value pairs
  final String body; // Raw body content
  final bool isRequest;

  const HttpMessage({
    this.method,
    this.url,
    this.statusCode,
    this.statusMessage,
    required this.httpVersion,
    required this.headers,
    required this.body,
    this.isRequest = true,
  });

  // bool get isRequest => method != null && url != null;
  // bool get isResponse => statusCode != null;
  bool get isResponse => !isRequest;

  /// Helper to create from raw HTTP text
  factory HttpMessage.fromRawRequest(String rawText) {
    final lines = rawText.split('\n');
    if (lines.isEmpty) {
      return HttpMessage(httpVersion: 'HTTP/1.1', headers: [], body: '');
    }

    // Parse request line: GET /path HTTP/1.1
    final firstLine = lines[0].trim();
    final parts = firstLine.split(' ');
    final method = parts.isNotEmpty ? parts[0] : 'GET';
    final url = parts.length > 1 ? parts[1] : '/';
    final httpVersion = parts.length > 2 ? parts[2] : 'HTTP/1.1';

    // Parse headers and body
    final headers = <String, String>{};
    int bodyStartIndex = 1;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        bodyStartIndex = i + 1;
        break;
      }
      final colonIndex = line.indexOf(':');
      if (colonIndex > 0) {
        final key = line.substring(0, colonIndex).trim();
        final value = line.substring(colonIndex + 1).trim();
        headers[key] = value;
      }
    }

    final body = lines.skip(bodyStartIndex).join('\n');

    return HttpMessage(
      method: method,
      url: url,
      httpVersion: httpVersion,
      // headers: headers,
      headers: [],
      body: body,
    );
  }

  factory HttpMessage.fromFlow(MitmFlow flow, {required bool isRequest}) {
    return HttpMessage(
      httpVersion: flow.request?.httpVersion ?? '',
      headers: flow.request?.headers ?? [],
      isRequest: isRequest,
      body: """[
    {
        "type": "flows/edit",
        "payload": {
            "flow": {
                "id": "5b864419-6e41-4574-b78c-3c8ebceb4a9c",
                "intercepted": false,
                "is_replay": null,
                "type": "http",
                "modified": false,
                "marked": "",
                "comment": "",
                "timestamp_created": 1753172361.03849,
                "client_conn": {
                    "id": "d48fd663-dde5-42a0-bacd-29d18f7bbf57",
                    "peername": [
                        "192.168.1.7",
                        43046
                    ],
                    "sockname": [
                        "192.168.1.14",
                        8080
                    ],
                    "tls_established": true,
                    "cert": null,
                    "sni": "gateway.instagram.com",
                    "cipher": "TLS_AES_256_GCM_SHA384",
                    "alpn": "http/1.1",
                    "tls_version": "TLSv1.3",
                    "timestamp_start": 1753172360.862132,
                    "timestamp_tls_setup": 1753172361.036887,
                    "timestamp_end": null
                },
                "server_conn": {
                    "id": "e9edbd9c-1606-4b92-b723-974bd4a74fb3",
                    "peername": [
                        "2a03:2880:f0a4:106:face:b00c:0:6206",
                        443,
                        0,
                        0
                    ],
                    "sockname": [
                        "2401:4900:8fce:f5d6:21f9:3daa:a5f6:fb3a",
                        49881,
                        0,
                        0
                    ],
                    "address": [
                        "2a03:2880:f0a4:106:face:b00c:0:6206",
                        443
                    ],
                    "tls_established": true,
                    "cert": {
                        "keyinfo": [
                            "EC (secp256r1)",
                            256
                        ],
                        "sha256": "982b760601ec409eebba9b6d996168018ffa63e19baeb25ecd31f0abd41c3e0d",
                        "notbefore": 1745971200,
                        "notafter": 1753833599,
                        "serial": "10267941578913480389388808227858711935",
                        "subject": [
                            [
                                "C",
                                "US"
                            ],""",
      method: flow.request?.method,
      url: flow.request?.path,
      statusCode: flow.response?.statusCode.toString() ?? '',
      statusMessage: getStatusCodeMessage(flow.response?.statusCode),
    );
  }

  factory HttpMessage.fromRawResponse(String rawText) {
    final lines = rawText.split('\n');
    if (lines.isEmpty) {
      return HttpMessage(httpVersion: 'HTTP/1.1', headers: [], body: '');
    }

    // Parse status line: HTTP/1.1 200 OK
    final firstLine = lines[0].trim();
    final parts = firstLine.split(' ');
    final httpVersion = parts.isNotEmpty ? parts[0] : 'HTTP/1.1';
    final statusCode = parts.length > 1 ? parts[1] : '200';
    final statusMessage = parts.length > 2 ? parts.sublist(2).join(' ') : 'OK';

    // Parse headers and body
    final headers = <String, String>{};
    int bodyStartIndex = 1;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        bodyStartIndex = i + 1;
        break;
      }
      final colonIndex = line.indexOf(':');
      if (colonIndex > 0) {
        final key = line.substring(0, colonIndex).trim();
        final value = line.substring(colonIndex + 1).trim();
        headers[key] = value;
      }
    }

    final body = lines.skip(bodyStartIndex).join('\n');

    return HttpMessage(
      httpVersion: httpVersion,
      statusCode: statusCode,
      statusMessage: statusMessage,
      headers: [],
      body: body,
    );
  }
}

/// Color scheme for HTTP syntax highlighting
class HttpSyntaxColors {
  final Color method; // GET, POST, etc.
  final Color url; // URL path
  final Color urlQueryKey; // Query parameter keys
  final Color urlQueryValue; // Query parameter values
  // final Color statusCode; // HTTP status code
  // final Color statusMessage; // Status message
  final Color httpVersion; // HTTP version
  final Color headerKey; // Header keys
  final Color headerValue; // Header values
  final Color cookieKey; // Cookie keys
  final Color cookieValue; // Cookie values
  final Color body; // Body content
  final Color diffHighlight; // Background for differences
  final Color diffText; // Text color for differences

  const HttpSyntaxColors({
    this.method = const Color(0xFFE06C75), // Red
    this.url = const Color(0xffA89CF7), // Purple
    this.urlQueryKey = const Color(0xFFD19A66), // Orange
    this.urlQueryValue = const Color(0xFF98C379), // Green
    // this.statusCode = const Color(0xFFE5C07B), // Yellow
    // this.statusMessage = const Color(0xFF98C379), // Green
    this.httpVersion = const Color(0xFFC678DD), // Purple
    this.headerKey = const Color(0xff86BFA3), // Teal
    this.headerValue = const Color(0xFFDC7C7C), // Light Red
    this.cookieKey = const Color(0xFFD19A66), // Orange
    this.cookieValue = const Color(0xFF98C379), // Green
    this.body = const Color(0xFFE5C07B), // Orange/Yellow
    this.diffHighlight = const Color(0xFF006DC1), // Blue background
    this.diffText = const Color(0xFFFFFFFF), // White text
  });
}

class HttpCompare extends ConsumerStatefulWidget {
  final HttpMessage message1;
  final HttpMessage message2;
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
  ConsumerState<ConsumerStatefulWidget> createState() => _HttpCompareState();
}

class _HttpCompareState extends ConsumerState<HttpCompare> {
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
      linesCount = Math.max(leftLines.length, rightLines.length);
    });
  }

  String _httpMessageToText(HttpMessage msg) {
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
    msg.headers.forEach((header) {
      buffer.writeln('${header[0]}: ${header[1]}');
    });

    // Empty line before body
    buffer.writeln();

    // Body
    buffer.write(msg.body);

    return buffer.toString();
  }

  List<HttpSection> _calculateSections(HttpMessage msg) {
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
    return Math.max(_minLineHeight, actualHeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.from(Theme.brightnessOf(context));

    return LayoutBuilder(
      builder: (context, constraints) {
        final lineNumberWidth = (linesCount.toString().length * 13.0) + 2;
        final availableWidth = (constraints.maxWidth - lineNumberWidth - 8) / 2;

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
                        sections: leftSections,
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
                  color: hasDiff ? _colors.diffText : _colors.method,
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
              style: TextStyle(backgroundColor: bgColor),
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
              style: TextStyle(backgroundColor: bgColor),
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
            style: TextStyle(backgroundColor: bgColor),
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
              // color: _colors.headerValue,
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
