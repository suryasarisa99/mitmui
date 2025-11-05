import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
    // final password = generateRandomString(32);
    // for testing purposes, use a fixed password
    final password = '12345678';
    _log.debug("password: $password");
    await Process.start('mitmweb', [
      '--web-port',
      port.toString(),
      // '--no-web-open-browser',
      '--set',
      'web_password=$password',
    ]);
    // get cookie, by sending password as token
    await Future.delayed(const Duration(seconds: 2));
    getCookieFromToken(password);
    _log.success('MITM Proxy started');
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
      "arguments": [exportType.name, "@$flowId"],
    };
    return _handleRequest(
      'fetching export request',
      () => _dio.post('/commands/export', data: data),
      (r) => r.data['value'] as String,
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
}

enum RequestExport { curl, httpie, rawRequest, rawResponse, raw }

enum MarkCircle {
  red(":red_circle:"),
  orange(":orange_circle:"),
  yellow(":yellow_circle:"),
  green(":green_circle:"),
  blue(":large_blue_circle:"),
  purple(":purple_circle:"),
  brown(":brown_circle:"),
  un_mark("");

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
      "" => MarkCircle.un_mark,
      _ => MarkCircle.red,
    };
  }

  Color getColor(bool isSelected) {
    // light variants
    if (isSelected) {
      return switch (this) {
        MarkCircle.red => const Color.fromARGB(255, 255, 183, 178),
        MarkCircle.orange => const Color.fromARGB(255, 255, 191, 94),
        MarkCircle.yellow => const Color.fromARGB(255, 255, 246, 161),
        MarkCircle.green => const Color.fromARGB(255, 160, 255, 163),
        MarkCircle.blue => const Color.fromARGB(255, 175, 219, 255),
        MarkCircle.purple => const Color.fromARGB(255, 242, 172, 255),
        MarkCircle.brown => const Color.fromARGB(255, 182, 160, 151),
        MarkCircle.un_mark => Colors.transparent,
      };
    } else {
      return switch (this) {
        MarkCircle.red => Colors.red,
        MarkCircle.orange => Colors.orange,
        MarkCircle.yellow => Colors.yellow,
        MarkCircle.green => const Color.fromARGB(255, 98, 213, 102),
        MarkCircle.blue => const Color.fromARGB(255, 62, 168, 255),
        MarkCircle.purple => const Color.fromARGB(255, 223, 84, 248),
        MarkCircle.brown => const Color.fromARGB(255, 165, 121, 106),
        MarkCircle.un_mark => Colors.transparent,
      };
    }
  }
}
