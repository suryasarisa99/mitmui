import 'dart:ui';

/// Color scheme for HTTP syntax highlighting
class HttpSyntaxColors {
  final Color method; // GET, POST, etc.
  final Color url; // URL path
  final Color urlQueryKey; // Query parameter keys
  final Color urlQueryValue; // Query parameter values
  final Color httpVersion; // HTTP version
  final Color headerKey; // Header keys
  final Color headerValue; // Header values
  final Color cookieKey; // Cookie keys
  final Color cookieValue; // Cookie values
  final Color body; // Body content
  final Color diffHighlight; // Background for differences
  final Color diffText; // Text color for differences

  const HttpSyntaxColors({
    this.method = const .new(0xFFE06C75), // Red

    this.url = const .new(0xffA89CF7), // Purple
    this.urlQueryKey = const Color(0xffA89CF7),
    this.urlQueryValue = const Color(0xFFCCA5FE),
    this.httpVersion = const .new(0xFFC678DD), // Purple
    this.headerKey = const Color(0xff86BFA3), // Teal
    this.headerValue = const Color(0xFFDC7C7C), // Light Red
    this.cookieKey = const .new(0xFFD19A66), // Orange
    this.cookieValue = const .new(0xFF98C379), // Green
    this.body = const .new(0xFFE5C07B), // Orange/Yellow
    this.diffHighlight = const .new(0xFF006DC1), // Blue background
    this.diffText = const .new(0xFFFFFFFF), // White text
  });
}
