import 'package:mitmui/models/flow.dart';
import 'package:mitmui/utils/statusCode.dart';

/// Represents an HTTP message (request or response) with structured parts
class HttpCompareMessage {
  final String? method; // GET, POST, etc. (null for response)
  final String? url; // Full URL (null for response)
  final String? statusCode; // 200, 404, etc. (null for request)
  final String? statusMessage; // OK, Not Found, etc. (null for request)
  final String httpVersion; // HTTP/1.1, HTTP/2, etc.
  final List<List<String>> headers; // Header key-value pairs
  final String body; // Raw body content
  final bool isRequest;

  const HttpCompareMessage({
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
  factory HttpCompareMessage.fromRawRequest(String rawText) {
    final lines = rawText.split('\n');
    if (lines.isEmpty) {
      return HttpCompareMessage(httpVersion: 'HTTP/1.1', headers: [], body: '');
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

    return HttpCompareMessage(
      method: method,
      url: url,
      httpVersion: httpVersion,
      // headers: headers,
      headers: [],
      body: body,
    );
  }

  factory HttpCompareMessage.fromFlow(
    MitmFlow flow, {
    required bool isRequest,
    required String body,
  }) {
    return HttpCompareMessage(
      httpVersion: flow.request?.httpVersion ?? '',
      headers: flow.request?.headers ?? [],
      isRequest: isRequest,
      body: body,
      method: flow.request?.method,
      url: flow.request?.path,
      statusCode: flow.response?.statusCode.toString() ?? '',
      statusMessage: getStatusCodeMessage(flow.response?.statusCode),
    );
  }

  factory HttpCompareMessage.fromRawResponse(String rawText) {
    final lines = rawText.split('\n');
    if (lines.isEmpty) {
      return HttpCompareMessage(httpVersion: 'HTTP/1.1', headers: [], body: '');
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

    return HttpCompareMessage(
      httpVersion: httpVersion,
      statusCode: statusCode,
      statusMessage: statusMessage,
      headers: [],
      body: body,
    );
  }
}
