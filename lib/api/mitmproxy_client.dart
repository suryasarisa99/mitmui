import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:mitmui/models/flow.dart';
import 'package:mitmui/models/response_body.dart';
import '../models/flow_store.dart';

/// Base URL for mitmproxy web interface
const String baseUrl = 'http://127.0.0.1:9090';
const int port = 9090;

class MitmproxyClient {
  // Use Dio's cookie manager to automatically handle cookies
  static final Dio _dio = _createDioInstance();
  static const String _baseUrl = 'http://127.0.0.1:$port';
  static const String websocketUrl = 'ws://127.0.0.1:$port';
  static String cookies = '';
  // Private constructor for singleton
  MitmproxyClient._internal();

  // Create Dio instance with cookie jar
  static Dio _createDioInstance() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
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
    //       if (cookies != null && cookies.isNotEmpty) {
    //         print('Received cookies: $cookies');
    //       }
    //       return handler.next(response);
    //     },
    //   ),
    // );
    return dio;
  }

  static Future<void> startMitm() async {
    // start mitmproxy with a random password
    final password = generateRandomString(32);
    print("password: $password");
    final res = await Process.start('mitmweb', [
      '--web-port',
      port.toString(),
      '--no-web-open-browser',
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
          print('Cookies set: $cookies');
        })
        .catchError((error) {
          print('Error setting cookies: $error');
        });
    print('MITM Proxy started: $stdout');
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
      print('Fetching flows from $_baseUrl/flows');
      final response = await _dio.get('/flows');

      if (response.statusCode == 200) {
        final List<dynamic> flows = response.data;
        print('Received ${flows.length} flows from API');
        return flows.map((f) => MitmFlow.fromJson(f)).toList();
      } else {
        print('Failed to fetch flows: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching flows: $e');
      return [];
    }
  }

  static Future<MitmBody> getMitmBody(String flowId, String type) async {
    try {
      final response = await _dio.get(
        '/flows/$flowId/$type/content/Auto.json',
        queryParameters: {'lines': 513},
      );

      if (response.statusCode == 200) {
        print('Response body fetched successfully for flow $flowId');
        return MitmBody.fromJson(response.data);
      } else {
        print('Failed to fetch response body: ${response.statusCode}');
        throw Exception(
          'Failed to fetch response body: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching response body: $e');
      throw Exception('Error fetching response body: $e');
    }
  }

  static Future<String> getMitmContent(String flowId, String type) async {
    try {
      final response = await _dio.get('/flows/$flowId/$type/content.data');

      if (response.statusCode == 200) {
        print('Response body fetched successfully for flow $flowId');
        return response.data;
      } else {
        print('Failed to fetch response body: ${response.statusCode}');
        throw Exception(
          'Failed to fetch response body: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching response body: $e');
      throw Exception('Error fetching response body: $e');
    }
  }

  /// Fetches all existing flows and adds them to the FlowStore
  static Future<void> loadFlowsIntoStore(FlowStore flowStore) async {
    try {
      final flows = await getFlows();
      flowStore.addMultiple(flows);
      print('Added ${flows.length} flows to FlowStore');
    } catch (e) {
      print('Error loading flows into store: $e');
    }
  }

  /// Update cookies manually if needed
  static void updateCookies(String newCookies) {
    cookies = newCookies;
    _dio.options.headers['Cookie'] = newCookies;
    print('Updated cookies, newCookies: $newCookies ');
  }
}
