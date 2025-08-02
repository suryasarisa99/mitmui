import 'dart:convert';
import 'package:mitmui/utils/logger.dart';

const _log = Logger("flow");

/// Represents a complete mitmproxy flow with all its components
class MitmFlow {
  final String id;
  final bool intercepted;
  // the intercepted state is add my me, not comes with mitm flow
  final String interceptedState;
  final dynamic isReplay; // Can be null
  final String type; // typically "http"
  final bool modified;
  final String marked;
  final String comment;
  final double timestampCreated;
  final ClientConnection clientConn;
  final ServerConnection? serverConn;
  final HttpRequest? request;
  final HttpResponse? response; // Can be null for incomplete requests
  final WebSocketInfo? websocket; // Only present for WebSocket connections

  MitmFlow({
    required this.id,
    required this.intercepted,
    this.interceptedState = 'none',
    this.isReplay,
    required this.type,
    required this.modified,
    required this.marked,
    required this.comment,
    required this.timestampCreated,
    required this.clientConn,
    required this.serverConn,
    required this.request,
    this.response,
    this.websocket,
  });

  factory MitmFlow.fromJson(
    Map<String, dynamic> json, {
    String interceptedState = 'none',
    List<bool>? enabledHeaders,
    List<List<String>>? headers,
  }) {
    try {
      return MitmFlow(
        id: json['id'],
        intercepted: json['intercepted'],
        isReplay: json['is_replay'],
        type: json['type'],
        interceptedState: interceptedState,
        modified: json['modified'],
        marked: json['marked'] ?? '',
        comment: json['comment'] ?? '',
        timestampCreated: json['timestamp_created'],
        clientConn: ClientConnection.fromJson(json['client_conn']),
        serverConn: json['server_conn'] != null
            ? ServerConnection.fromJson(json['server_conn'])
            : null,
        request: json['request'] != null
            ? HttpRequest.fromJson(
                json['request'],
                enabledHeaders: enabledHeaders,
                headers: headers,
              )
            : null,
        response: json['response'] != null
            ? HttpResponse.fromJson(json['response'])
            : null,
        websocket: json['websocket'] != null
            ? WebSocketInfo.fromJson(json['websocket'])
            : null,
      );
    } catch (err) {
      _log.error("error parsing MitmFlow: $err");
      _log.error("json: $json");
      throw FormatException('Invalid MitmFlow data: $err');
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'intercepted': intercepted,
      'is_replay': isReplay,
      'type': type,
      'modified': modified,
      'marked': marked,
      'comment': comment,
      'timestamp_created': timestampCreated,
      'client_conn': clientConn.toJson(),
      'server_conn': serverConn?.toJson(),
      'request': request?.toJson(),
    };

    if (response != null) {
      data['response'] = response!.toJson();
    }

    if (websocket != null) {
      data['websocket'] = websocket!.toJson();
    }

    return data;
  }

  // copyWith serverState
  MitmFlow copyWith({
    String? interceptedState,
    List<List<String>>? headers,
    List<bool>? enabledHeaders,
  }) {
    return MitmFlow(
      id: id,
      intercepted: intercepted,
      interceptedState: interceptedState ?? this.interceptedState,
      isReplay: isReplay,
      type: type,
      modified: modified,
      marked: marked,
      comment: comment,
      timestampCreated: timestampCreated,
      clientConn: clientConn,
      serverConn: serverConn,
      request: request?.copyWith(
        headers: headers ?? request?.headers ?? [],
        enabledHeaders: enabledHeaders ?? request?.enabledHeaders ?? [],
      ),
      response: response,
      websocket: websocket,
    );
  }

  /// Parse a flow update message from the WebSocket connection
  static MitmFlow? parseFlowMessage(String message) {
    try {
      final Map<String, dynamic> json = jsonDecode(message);

      if (json['type'] == 'flows/add' || json['type'] == 'flows/update') {
        return MitmFlow.fromJson(json['payload']['flow']);
      }
      return null;
    } catch (e) {
      _log.error('Error parsing flow message: $e');
      return null;
    }
  }

  /// Get the full URL of the request
  String get url {
    if (request != null) return request!.url;
    final clientPeer = clientConn.peername;
    final clientAddr = '${clientPeer[0]}:${clientPeer[1]}';
    if (serverConn != null && serverConn!.peername != null) {
      final serverPeer = serverConn!.peername;
      return '$clientAddr -> ${serverPeer![0]}:${serverPeer[1]}';
    }
    return clientAddr;
  }

  /// Returns true if this flow represents a WebSocket connection
  bool get isWebSocket => websocket != null;

  /// Returns a readable timestamp
  DateTime get createdDateTime =>
      DateTime.fromMillisecondsSinceEpoch((timestampCreated * 1000).round());
}

/// Represents the client connection details
class ClientConnection {
  final String id;
  final List<dynamic> peername; // [ip, port]
  final List<dynamic> sockname; // [ip, port]
  final bool tlsEstablished;
  final dynamic cert; // Can be null
  final String? sni;
  final String? cipher;
  final String? alpn;
  final String? tlsVersion;
  final double timestampStart;
  final double? timestampTlsSetup;
  final dynamic timestampEnd; // Can be null

  ClientConnection({
    required this.id,
    required this.peername,
    required this.sockname,
    required this.tlsEstablished,
    this.cert,
    this.sni,
    this.cipher,
    this.alpn,
    this.tlsVersion,
    required this.timestampStart,
    this.timestampTlsSetup,
    this.timestampEnd,
  });

  factory ClientConnection.fromJson(Map<String, dynamic> json) {
    try {
      return ClientConnection(
        id: json['id'],
        peername: json['peername'],
        sockname: json['sockname'],
        tlsEstablished: json['tls_established'],
        cert: json['cert'],
        sni: json['sni'],
        cipher: json['cipher'],
        alpn: json['alpn'],
        tlsVersion: json['tls_version'],
        timestampStart: json['timestamp_start'],
        timestampTlsSetup: json['timestamp_tls_setup'],
        timestampEnd: json['timestamp_end'],
      );
    } catch (err) {
      _log.error("error parsing ClientConnection: $err");
      throw FormatException('Invalid ClientConnection data: $err');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'peername': peername,
      'sockname': sockname,
      'tls_established': tlsEstablished,
      'cert': cert,
      'sni': sni,
      'cipher': cipher,
      'alpn': alpn,
      'tls_version': tlsVersion,
      'timestamp_start': timestampStart,
      'timestamp_tls_setup': timestampTlsSetup,
      'timestamp_end': timestampEnd,
    };
  }

  String get clientIp => peername[0].toString();
  int get clientPort => peername[1] as int;
}

/// Represents the server connection details
class ServerConnection {
  final String id;
  final List<dynamic>? peername; // [ip, port, ...]
  final List<dynamic>? sockname; // [ip, port, ...]
  final List<dynamic>? address; // [ip, port]
  final bool tlsEstablished;
  final Certificate? cert;
  final String? sni;
  final String? cipher;
  final String? alpn;
  final String? tlsVersion;
  final double? timestampStart;
  final double? timestampTcpSetup;
  final double? timestampTlsSetup;
  final dynamic timestampEnd;

  ServerConnection({
    required this.id,
    required this.peername,
    required this.sockname,
    required this.address,
    required this.tlsEstablished,
    this.cert,
    this.sni,
    this.cipher,
    this.alpn,
    this.tlsVersion,
    required this.timestampStart,
    this.timestampTcpSetup,
    this.timestampTlsSetup,
    this.timestampEnd,
  });

  factory ServerConnection.fromJson(Map<String, dynamic> json) {
    try {
      return ServerConnection(
        id: json['id'],
        peername: json['peername'] != null
            ? List<dynamic>.from(json['peername'])
            : null,
        sockname: json['sockname'] != null
            ? List<dynamic>.from(json['sockname'])
            : null,
        address: json['address'] != null
            ? List<dynamic>.from(json['address'])
            : null,
        tlsEstablished: json['tls_established'],
        cert: json['cert'] != null ? Certificate.fromJson(json['cert']) : null,
        sni: json['sni'],
        cipher: json['cipher'],
        alpn: json['alpn'],
        tlsVersion: json['tls_version'],
        timestampStart: json['timestamp_start'],
        timestampTcpSetup: json['timestamp_tcp_setup'],
        timestampTlsSetup: json['timestamp_tls_setup'],
        timestampEnd: json['timestamp_end'],
      );
    } catch (err) {
      _log.error("error parsing ServerConnection: $err");
      _log.error("json: $json");
      throw FormatException('Invalid ServerConnection data: $err');
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'peername': peername,
      'sockname': sockname,
      'address': address,
      'tls_established': tlsEstablished,
      'sni': sni,
      'cipher': cipher,
      'alpn': alpn,
      'tls_version': tlsVersion,
      'timestamp_start': timestampStart,
      'timestamp_tcp_setup': timestampTcpSetup,
      'timestamp_tls_setup': timestampTlsSetup,
      'timestamp_end': timestampEnd,
    };

    if (cert != null) {
      data['cert'] = cert!.toJson();
    }

    return data;
  }

  String? get serverIp => address?[0].toString();
  int? get serverPort => address?[1] as int?;
}

/// Represents a TLS certificate
class Certificate {
  final List<dynamic> keyinfo; // [type, bits]
  final String sha256;
  final int notBefore;
  final int notAfter;
  final String serial;
  final List<List<String>> subject;
  final List<List<String>> issuer;
  final List<String>? altnames;

  Certificate({
    required this.keyinfo,
    required this.sha256,
    required this.notBefore,
    required this.notAfter,
    required this.serial,
    required this.subject,
    required this.issuer,
    this.altnames,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    List<List<String>> parseNamesList(dynamic jsonList) {
      return (jsonList as List<dynamic>)
          .map(
            (item) => (item as List<dynamic>).map((e) => e.toString()).toList(),
          )
          .toList();
    }

    return Certificate(
      keyinfo: json['keyinfo'],
      sha256: json['sha256'],
      notBefore: json['notbefore'],
      notAfter: json['notafter'],
      serial: json['serial'].toString(),
      subject: parseNamesList(json['subject']),
      issuer: parseNamesList(json['issuer']),
      altnames: json['altnames'] != null
          ? (json['altnames'] as List<dynamic>)
                .map((e) => e.toString())
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'keyinfo': keyinfo,
      'sha256': sha256,
      'notbefore': notBefore,
      'notafter': notAfter,
      'serial': serial,
      'subject': subject,
      'issuer': issuer,
    };

    if (altnames != null) {
      data['altnames'] = altnames;
    }

    return data;
  }

  String get commonName {
    for (var pair in subject) {
      if (pair[0] == 'CN') {
        return pair[1];
      }
    }
    return 'Unknown';
  }

  DateTime get validFrom =>
      DateTime.fromMillisecondsSinceEpoch(notBefore * 1000);

  DateTime get validUntil =>
      DateTime.fromMillisecondsSinceEpoch(notAfter * 1000);
}

/// Represents an HTTP request
class HttpRequest {
  final String method;
  final String scheme;
  final String host;
  final int port;
  final String path;
  final String httpVersion;
  final List<List<String>> headers; // [name, value]
  final int? contentLength; // Can be null
  final String? contentHash; // Can be null
  final double? timestampStart; // Can be null for reconstructed flows
  final double? timestampEnd; // Can be null for incomplete flows
  final String? prettyHost; // Can be null
  final List<bool>? enabledHeaders;

  HttpRequest({
    required this.method,
    required this.scheme,
    required this.host,
    required this.port,
    required this.path,
    required this.httpVersion,
    required this.headers,
    this.enabledHeaders,
    this.contentLength,
    this.contentHash,
    this.timestampStart,
    this.timestampEnd,
    this.prettyHost,
  });

  factory HttpRequest.fromJson(
    Map<String, dynamic> json, {
    List<List<String>>? headers,
    List<bool>? enabledHeaders,
  }) {
    try {
      List<List<String>> parseHeaders(dynamic jsonHeaders) {
        return (jsonHeaders as List<dynamic>)
            .map((header) => [header[0].toString(), header[1].toString()])
            .toList();
      }

      return HttpRequest(
        method: json['method'],
        scheme: json['scheme'],
        host: json['host'],
        port: json['port'],
        path: json['path'],
        enabledHeaders: enabledHeaders,
        httpVersion: json['http_version'],
        headers: headers ?? parseHeaders(json['headers']),
        contentLength: json['contentLength'],
        contentHash: json['contentHash'],
        timestampStart: json['timestamp_start'],
        timestampEnd: json['timestamp_end'],
        prettyHost: json['pretty_host'],
      );
    } catch (err) {
      _log.error("error parsing HttpRequest: $err");
      throw FormatException('Invalid HttpRequest data: $err');
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'method': method,
      'scheme': scheme,
      'host': host,
      'port': port,
      'path': path,
      'http_version': httpVersion,
      'headers': headers,
    };

    if (contentLength != null) data['contentLength'] = contentLength;
    if (contentHash != null) data['contentHash'] = contentHash;
    if (timestampStart != null) data['timestamp_start'] = timestampStart;
    if (timestampEnd != null) data['timestamp_end'] = timestampEnd;
    if (prettyHost != null) data['pretty_host'] = prettyHost;

    return data;
  }

  /// Get a header value by name (case-insensitive)
  String? getHeader(String name) {
    final normalizedName = name.toLowerCase();
    for (var header in headers) {
      if (header[0].toLowerCase() == normalizedName) {
        return header[1];
      }
    }
    return null;
  }

  String? get cookies => getHeader('cookie');
  String? get contentTypeHeader => getHeader('content-type');

  /// Get the full URL of the request
  String get url => '$scheme://${prettyHost ?? '$host:$port'}$path';

  /// Get just the hostname and path
  String get hostAndPath => '${prettyHost ?? host}$path';

  /// copy with
  HttpRequest copyWith({
    String? method,
    String? scheme,
    String? host,
    int? port,
    String? path,
    String? httpVersion,
    List<List<String>>? headers,
    List<bool>? enabledHeaders,
    int? contentLength,
    String? contentHash,
    double? timestampStart,
    double? timestampEnd,
    String? prettyHost,
  }) {
    return HttpRequest(
      method: method ?? this.method,
      scheme: scheme ?? this.scheme,
      host: host ?? this.host,
      port: port ?? this.port,
      path: path ?? this.path,
      httpVersion: httpVersion ?? this.httpVersion,
      headers: headers ?? this.headers,
      enabledHeaders: enabledHeaders ?? this.enabledHeaders,
      contentLength: contentLength ?? this.contentLength,
      contentHash: contentHash ?? this.contentHash,
      timestampStart: timestampStart ?? this.timestampStart,
      timestampEnd: timestampEnd ?? this.timestampEnd,
      prettyHost: prettyHost ?? this.prettyHost,
    );
  }
}

/// Represents an HTTP response
class HttpResponse {
  final String httpVersion;
  final int statusCode;
  final String reason;
  final List<List<String>> headers; // [name, value]
  final int? contentLength; // Can be null
  final String? contentHash; // Can be null
  final double timestampStart;
  final double? timestampEnd;

  HttpResponse({
    required this.httpVersion,
    required this.statusCode,
    required this.reason,
    required this.headers,
    this.contentLength,
    this.contentHash,
    required this.timestampStart,
    required this.timestampEnd,
  });

  // Extract content type from headers
  String? get contentType {
    for (var header in headers) {
      if (header.length == 2 && header[0].toLowerCase() == 'content-type') {
        return header[1];
      }
    }
    return null;
  }

  factory HttpResponse.fromJson(Map<String, dynamic> json) {
    try {
      List<List<String>> parseHeaders(dynamic jsonHeaders) {
        return (jsonHeaders as List<dynamic>)
            .map((header) => [header[0].toString(), header[1].toString()])
            .toList();
      }

      return HttpResponse(
        httpVersion: json['http_version'],
        statusCode: json['status_code'],
        reason: json['reason'],
        headers: parseHeaders(json['headers']),
        contentLength: json['contentLength'],
        contentHash: json['contentHash'],
        timestampStart: json['timestamp_start'],
        timestampEnd: json['timestamp_end'],
      );
    } catch (err) {
      _log.error("error parsing HttpResponse: $err");
      throw FormatException('Invalid HttpResponse data: $err');
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'http_version': httpVersion,
      'status_code': statusCode,
      'reason': reason,
      'headers': headers,
      'timestamp_start': timestampStart,
      'timestamp_end': timestampEnd,
    };

    if (contentLength != null) data['contentLength'] = contentLength;
    if (contentHash != null) data['contentHash'] = contentHash;

    return data;
  }

  /// Get a header value by name (case-insensitive)
  String? getHeader(String name) {
    final normalizedName = name.toLowerCase();
    for (var header in headers) {
      if (header[0].toLowerCase() == normalizedName) {
        return header[1];
      }
    }
    return null;
  }

  String? get cookies => getHeader('cookie');
  String? get contentTypeHeader => getHeader('content-type');

  /// Calculate response time in milliseconds
  double? get responseTimeMs =>
      timestampEnd != null ? (timestampEnd! - timestampStart) * 1000 : null;

  /// Check if the response is an error
  bool get isError => statusCode >= 400;

  /// Check if the status code is a success
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Represents WebSocket connection information
class WebSocketInfo {
  final Map<String, dynamic> messagesMeta;
  final dynamic closedByClient; // Can be null
  final dynamic closeCode; // Can be null
  final dynamic closeReason; // Can be null
  final dynamic timestampEnd; // Can be null

  WebSocketInfo({
    required this.messagesMeta,
    this.closedByClient,
    this.closeCode,
    this.closeReason,
    this.timestampEnd,
  });

  factory WebSocketInfo.fromJson(Map<String, dynamic> json) {
    try {
      return WebSocketInfo(
        messagesMeta: json['messages_meta'],
        closedByClient: json['closed_by_client'],
        closeCode: json['close_code'],
        closeReason: json['close_reason'],
        timestampEnd: json['timestamp_end'],
      );
    } catch (err) {
      _log.error("error parsing WebSocketInfo: $err");
      throw FormatException('Invalid WebSocketInfo data: $err');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'messages_meta': messagesMeta,
      'closed_by_client': closedByClient,
      'close_code': closeCode,
      'close_reason': closeReason,
      'timestamp_end': timestampEnd,
    };
  }

  int get messageCount => messagesMeta['count'] as int;
  int get contentLength => messagesMeta['contentLength'] as int;
  double? get lastMessageTimestamp => messagesMeta['timestamp_last'] as double?;
  bool get isClosed => timestampEnd != null;
}

/// Get a header value by name (case-insensitive)
/// some old frameworks use duplicate header names so we handle all that name
List<String> getHeadersByName(List<List<String>> headers, String name) {
  final List<String> values = [];
  final normalizedName = name.toLowerCase();
  for (var header in headers) {
    if (header[0].toLowerCase() == normalizedName) {
      values.add(header[1]);
    }
  }
  return values;
}
