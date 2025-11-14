import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mitmui/global.dart';
import 'package:mitmui/models/flow.dart';
import 'package:mitmui/models/response_body.dart';
import 'package:mitmui/utils/logger.dart';

const _log = Logger("mitmproxy_client");

const int port = 9090;

class MitmproxyClient {
  // Use Dio's cookie manager to automatically handle cookies
  static final Dio _dio = _createDioInstance();
  static const String baseUrl = 'http://127.0.0.1:$port';
  static const String websocketUrl = 'ws://127.0.0.1:$port';
  static String cookies = '';
  // Private constructor for singleton
  MitmproxyClient._internal();

  // Create Dio instance with cookie jar
  static Dio _createDioInstance() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'User-Agent': 'Flutter/MITMUI',
        },
      ),
    );

    // Set up interceptors to log requests and responses
    // dio.interceptors.add(
    //   LogInterceptor(
    //     request: true,
    //     requestHeader: true,
    //     requestBody: false,
    //     responseHeader: true,
    //     responseBody: false,
    //   ),
    // );
    // dio.interceptors.add(
    //   InterceptorsWrapper(
    //     onResponse: (response, handler) {
    //       final cookies = response.headers['set-cookie'];
    //       return handler.next(response);
    //     },
    //   ),
    // );
    return dio;
  }

  static Future<void> startMitm() async {
    // start mitmproxy with a random password
    final password = generateRandomString(32);
    // for testing purposes, use a fixed password
    // final password = '12345678';
    _log.debug("password: $password");
    await Process.start('mitmweb', [
      '--web-port',
      port.toString(),
      '--no-web-open-browser',
      '--set',
      'web_password=$password',
    ]);
    // get cookie, by sending password as token
    await Future.delayed(const Duration(milliseconds: 1000));
    await getCookieFromToken(password);
    prefs.setString('password', password);
    _log.success('MITM Proxy started');
  }

  /*
  1 - mitm is running (no password)
  2 - mitm is running (with password)
  -1 - mitm is not running
  -2 - port is used by other process
  3 - error
  */

  /* notes
  to get details about port: lsof -iTCP:9090 -sTCP:LISTEN
  to get only pid from port: lsof -tiTCP:9090 -sTCP:LISTEN
  to kill: kill <pid>
  to get complete command: ps -p <pid> -o command
  */

  static Future<int> isRunning() async {
    try {
      final lsof = await Process.run('lsof', ['-iTCP:9090', '-sTCP:LISTEN']);
      final out = (lsof.stdout as String).trim();

      // no LISTEN entries on the port
      if (out.isEmpty) return -1;

      final lines = out
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.length <= 1) {
        debugPrint('No LISTEN entries on TCP:9090.');
        return -1;
      }

      // parse entries (skip header)
      final entries = lines.sublist(1);
      final mitmPids = <int>{};
      final otherEntries = <String>[];

      for (var line in entries) {
        // lsof columns: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
        final cols = line.split(RegExp(r'\s+'));
        if (cols.isEmpty) continue;
        final command = cols[0];
        int? pid;
        if (cols.length >= 2) {
          pid = int.tryParse(cols[1]);
        }
        if (command == 'mitmweb' && pid != null) {
          mitmPids.add(pid);
        } else {
          otherEntries.add(line);
        }
      }

      // port used by other process(es)
      if (mitmPids.isEmpty) return -2;

      // For each mitmweb PID, check full command (args) for "web_password"
      var foundWithPassword = false;
      for (var pid in mitmPids) {
        final ps = await Process.run('ps', [
          '-p',
          pid.toString(),
          '-o',
          'args=',
        ]);
        final args = (ps.stdout as String).trim();
        if (args.isNotEmpty) {
          debugPrint('PID $pid args: $args');
          if (args.contains('web_password')) {
            foundWithPassword = true;
            break;
          }
        }
      }

      if (foundWithPassword) {
        debugPrint('mitmweb running and web_password found in command.');
        return 2;
      } else {
        debugPrint('mitmweb running but web_password not found in command.');
        return 1;
      }
    } catch (e) {
      stderr.writeln('Error: $e');
      return 3;
    }
  }

  static Future<bool> getCookieFromToken(String token) async {
    return _dio
        .get('/?token=$token')
        .then((response) {
          final newCookies = response.headers['set-cookie']?.join('; ') ?? '';
          updateCookies(newCookies);
          _log.info('Cookies set: $cookies');
          return true;
        })
        .catchError((error) {
          _log.error('Error setting cookies: $error');
          return false;
        });
  }

  static String generateRandomString(int length) {
    const characters =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      length,
      (_) => characters[random.nextInt(characters.length)],
    ).join();
  }

  static Future<T> _handleRequest<T>(
    String operationName,
    Future<Response> Function() requestFunction,
    T Function(Response r) onSuccess, [
    T Function()? handle,
  ]) async {
    try {
      _log.debug('Starting $operationName...');
      final r = await requestFunction();

      if (r.statusCode == 200) {
        _log.success('$operationName completed successfully.');
        return onSuccess(r);
      } else {
        final errorMessage =
            'Failed to $operationName: ${r.statusCode}, ${r.data}';
        _log.error(errorMessage);
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      final errorMessage = 'Dio error during $operationName: ${e.message}';
      // _log.error(errorMessage, e.error, e.stackTrace);
      _log.error(errorMessage);
      if (handle != null) return handle();
      throw Exception(errorMessage);
    } catch (e) {
      final errorMessage = 'Error during $operationName: $e';
      _log.error(errorMessage);
      if (handle != null) return handle();
      // _log.error(errorMessage, e, stackTrace);
      throw Exception(errorMessage);
    }
  }

  /// Update cookies manually if needed
  static void updateCookies(String newCookies) {
    cookies = newCookies;
    _dio.options.headers['Cookie'] = newCookies;
    // get _xsrf from cookies
    final xsrfCookie = newCookies
        .split('; ')
        .firstWhere((cookie) => cookie.startsWith('_xsrf='), orElse: () => '');
    if (xsrfCookie.isNotEmpty) {
      final xsrfValue = xsrfCookie.split('=')[1];
      _dio.options.headers['X-XSRFToken'] = xsrfValue;
    }
    _log.info('Updated cookies, newCookies: $newCookies ');
  }

  /// Fetches all existing flows from mitmproxy
  static Future<List<MitmFlow>> getFlows() async {
    return _handleRequest('fetching flows', () => _dio.get('/flows'), (r) {
      final List<dynamic> flows = r.data;
      return flows.map((f) => MitmFlow.fromJson(f)).toList();
    }, () => []);
  }

  /// get body for request or response
  static Future<MitmBody> getMitmBody(String flowId, String type) async {
    return _handleRequest(
      'fetching mitm body',
      () => _dio.get('/flows/$flowId/$type/content/Auto.json'),
      (r) => MitmBody.fromJson(r.data),
    );
  }

  /// export request string
  static Future<String> getExportReq(String flowId, RequestExport exportType) {
    final data = {
      "arguments": [exportType.toString(), "@$flowId"],
    };
    return _handleRequest(
      'fetching export request',
      () => _dio.post('/commands/export', data: data),
      (r) => r.data['value'] as String,
      // () => data.toString(),
    );
  }

  /// delete flow
  static Future<void> deleteFlow(String flowId) async {
    _handleRequest(
      'deleting flow',
      () => _dio.delete('/flows/$flowId'),
      (r) {},
    );
  }

  // repeat the request
  static Future<void> replay(String flowId) async {
    return _handleRequest(
      'replaying request',
      () => _dio.post('/flows/$flowId/replay'),
      (r) {},
    );
  }

  // mark a flow with some color or tag
  static Future<void> markFlow(String flowId, MarkCircle mark) {
    return _handleRequest(
      'marking flow',
      () => _dio.put('/flows/$flowId', data: {'marked': mark.value}),
      (r) {},
    );
  }

  static Future<void> revertChanges(String flowId) {
    return _handleRequest(
      'revert flow',
      () => _dio.post('/flows/$flowId/revert'),
      (r) {},
    );
  }

  static Future<void> duplicateFlow(String flowId) {
    return _handleRequest(
      'duplicate flow',
      () => _dio.post('/flows/$flowId/duplicate'),
      (r) {},
    );
  }

  static Future<void> interceptFlow(String filter) {
    return _handleRequest(
      'intercept flow',
      () => _dio.put('/options', data: {'intercept': filter}),
      (r) {},
    );
  }

  static Future<void> resumeIntercept(String flowId) {
    return _handleRequest(
      'resume intercept',
      () => _dio.post('/flows/$flowId/resume'),
      (r) {},
    );
  }

  static Future<void> updateHeaders(String flowId, List<List<String>> headers) {
    return _handleRequest(
      'updating headers',
      () => _dio.put(
        '/flows/$flowId',
        data: {
          'request': {'headers': headers},
        },
      ),
      (r) {},
    );
  }

  static Future<void> updatePath(String flowId, String path) {
    return _handleRequest(
      'updating path',
      () => _dio.put(
        '/flows/$flowId',
        data: {
          'request': {'path': path},
        },
      ),
      (r) {},
    );
  }

  static Future<void> updateBody(
    String flowId, {
    required String type,
    required String body,
  }) {
    return _handleRequest(
      'updating body',
      () => _dio.put(
        '/flows/$flowId',
        data: {
          type: {'content': body},
        },
      ),
      (r) {},
    );
  }
}

enum RequestExport {
  curl,
  httpie,
  rawRequest('raw_request'),
  rawResponse('raw_response'),
  raw;

  final String value;
  const RequestExport([this.value = '']);

  @override
  String toString() => value.isNotEmpty ? value : name;
}

enum MarkCircle {
  red(":red_circle:"),
  orange(":orange_circle:"),
  yellow(":yellow_circle:"),
  green(":green_circle:"),
  blue(":large_blue_circle:"),
  purple(":purple_circle:"),
  brown(":brown_circle:"),
  unMark("");

  final String value;
  const MarkCircle(this.value);

  factory MarkCircle.decode(String value) {
    return switch (value) {
      "🔴" => MarkCircle.red,
      "🟠" => MarkCircle.orange,
      "🟡" => MarkCircle.yellow,
      "🟢" => MarkCircle.green,
      "🔵" => MarkCircle.blue,
      "🟣" => MarkCircle.purple,
      "🟤" => MarkCircle.brown,
      "" => MarkCircle.unMark,
      _ => MarkCircle.red,
    };
  }

  Color getColor(bool isSelected) {
    // light variants
    if (isSelected) {
      return switch (this) {
        MarkCircle.red => const .fromARGB(255, 255, 183, 178),
        MarkCircle.orange => const .fromARGB(255, 255, 191, 94),
        MarkCircle.yellow => const .fromARGB(255, 255, 246, 161),
        MarkCircle.green => const .fromARGB(255, 160, 255, 163),
        MarkCircle.blue => const .fromARGB(255, 175, 219, 255),
        MarkCircle.purple => const .fromARGB(255, 242, 172, 255),
        MarkCircle.brown => const .fromARGB(255, 182, 160, 151),
        MarkCircle.unMark => Colors.transparent,
      };
    } else {
      return switch (this) {
        MarkCircle.red => Colors.red,
        MarkCircle.orange => Colors.orange,
        MarkCircle.yellow => Colors.yellow,
        MarkCircle.green => const .fromARGB(255, 98, 213, 102),
        MarkCircle.blue => const .fromARGB(255, 62, 168, 255),
        MarkCircle.purple => const .fromARGB(255, 223, 84, 248),
        MarkCircle.brown => const .fromARGB(255, 165, 121, 106),
        MarkCircle.unMark => Colors.transparent,
      };
    }
  }
}
