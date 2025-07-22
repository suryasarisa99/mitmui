import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mitmui/models/flow.dart';
import 'package:mitmui/models/response_body.dart';
import '../models/flow_store.dart';

/// Base URL for mitmproxy web interface
const String baseUrl = 'http://127.0.0.1:9090';

/// Cookie header for authentication
const String cookieHeader =
    '_xsrf=2|86f6d839|79a267d98bb715d1e7cfaeedbe13690c|1753192344; mitmproxy-auth-8081="2|1:0|10:1753192428|19:mitmproxy-auth-8081|4:eQ==|706d3645a40d02ac50a4b30c8ddf57a03661b40a64e2189c2ec70cf6990bed26"';

class MitmproxyClient {
  final Dio _dio;

  /// Constructor that initializes the HTTP client
  MitmproxyClient() : _dio = Dio() {
    // Configure default options
    _dio.options.headers = {
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Connection': 'keep-alive',
      'Cookie': cookieHeader,
      'Referer': baseUrl,
      'User-Agent': 'Flutter/MITMUI',
    };
    _dio.options.baseUrl = baseUrl;
  }

  /// Fetches all existing flows from mitmproxy
  Future<List<MitmFlow>> getFlows() async {
    try {
      print('Fetching flows from $baseUrl/flows');
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

  Future<MitmBody> getMitmBody(String flowId, String type) async {
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

  Future<String> getMitmContent(String flowId, String type) async {
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
  Future<void> loadFlowsIntoStore(FlowStore flowStore) async {
    try {
      final flows = await getFlows();
      flowStore.addMultiple(flows);
      print('Added ${flows.length} flows to FlowStore');
    } catch (e) {
      print('Error loading flows into store: $e');
    }
  }
}
