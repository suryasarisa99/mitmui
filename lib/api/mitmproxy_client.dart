import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:mitmui/models/flow.dart';
import 'package:mitmui/models/response_body.dart';
import 'package:mitmui/utils/logger.dart';
import '../store/flows_provider.dart';

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
    final res = await Process.start('mitmweb', [
      '--web-port',
      port.toString(),
      // '--no-web-open-browser',
      '--set',
      'web_password=$password',
    ]);
    // get cookie, by sending password as token
    await Future.delayed(const Duration(seconds: 2));
    _dio
        .get('/?token=$password')
        .then((response) {
          final newCookies = response.headers['set-cookie']?.join('; ') ?? '';
          updateCookies(newCookies);
          _log.info('Cookies set: $cookies');
        })
        .catchError((error) {
          _log.error('Error setting cookies: $error');
        });
    _log.success('MITM Proxy started');
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

  /// Fetches all existing flows from mitmproxy
  static Future<List<MitmFlow>> getFlows() async {
    try {
      _log.info('Fetching flows from $baseUrl/flows');
      final response = await _dio.get('/flows');

      if (response.statusCode == 200) {
        final List<dynamic> flows = response.data;
        // _log.info('Received ${flows.length} flows from API, ${response.data}');
        return flows.map((f) => MitmFlow.fromJson(f)).toList();
      } else {
        _log.error(
          'Failed to fetch flows: ${response.statusCode}, ${response.data}',
        );
        return [];
      }
      // return [];
    } catch (e) {
      _log.error('Error fetching flows: $e');
      return [];
    }
  }

  static Future<MitmBody> getMitmBody(String flowId, String type) async {
    try {
      final response = await _dio.get(
        '/flows/$flowId/$type/content/Auto.json',
        // queryParameters: {'lines': 513},
      );

      if (response.statusCode == 200) {
        // _log.debug(
        //   'res for ${'/flows/$flowId/$type/content/Auto.json'}: ${response.data}',
        // );
        return MitmBody.fromJson(response.data);
      } else {
        _log.error('Failed to fetch response body: ${response.statusCode}');
        throw Exception(
          'Failed to fetch response body: ${response.statusCode}',
        );
      }
    } catch (e) {
      _log.error('Error fetching response body: $e');
      throw Exception('Error fetching response body: $e');
    }
  }

  static Future<String> getMitmContent(String flowId, String type) async {
    try {
      final response = await _dio.get('/flows/$flowId/$type/content.data');

      if (response.statusCode == 200) {
        _log.debug('Response body fetched successfully for flow $flowId');
        return response.data;
      } else {
        _log.error(
          'Failed to fetch response body content: ${response.statusCode}',
        );
        throw Exception(
          'Failed to fetch response body content: ${response.statusCode}',
        );
      }
    } catch (e) {
      _log.error('Error fetching response body: $e');
      throw Exception('Error fetching response body: $e');
    }
  }

  /// Fetches all existing flows and adds them to the FlowStore
  static Future<void> loadFlowsIntoStore(FlowsProvider flowStore) async {
    try {
      final flows = await getFlows();
      flowStore.addAll(flows);
      _log.info('Added ${flows.length} flows to FlowStore');
    } catch (e) {
      _log.error('Error loading flows into store: $e');
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

  /// copy curl request
  static Future<String> getExportReq(
    String flowId,
    RequestExport exportType,
  ) async {
    try {
      final response = await _dio.post(
        '/commands/export',
        data: {
          "arguments": [exportType.name, "@$flowId"],
        },
      );

      if (response.statusCode == 200) {
        _log.info('Curl request fetched successfully for flow $flowId');
        return response.data['value'];
      } else {
        _log.error('Failed to fetch curl request: ${response.statusCode}');
        throw Exception('Failed to fetch curl request: ${response.statusCode}');
      }
    } catch (e) {
      _log.error('Error fetching curl request: $e');
      throw Exception('Error fetching curl request: $e');
    }
  }

  static Future<void> deleteFlow(String flowId) async {
    try {
      final response = await _dio.delete('/flows/$flowId');
      if (response.statusCode == 200) {
        _log.info('Flow $flowId deleted successfully');
      } else {
        _log.error('Failed to delete flow $flowId: ${response.statusCode}');
        throw Exception(
          'Failed to delete flow $flowId: ${response.statusCode}',
        );
      }
    } catch (e) {
      _log.error('Error deleting flow $flowId: $e');
      throw Exception('Error deleting flow $flowId: $e');
    }
  }
}

enum RequestExport { curl, httpie, raw_request, raw_response, raw }
