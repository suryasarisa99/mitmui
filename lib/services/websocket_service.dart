// websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/store/filtered_flows_provider.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:web_socket_channel/io.dart';
import '../api/mitmproxy_client.dart';
import '../store/flows_provider.dart';

const _log = Logger("websocket_service");

final websocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(ref); // Pass the ref when creating the service
});

class WebSocketService {
  IOWebSocketChannel? _channel;
  WebSocket? _webSocket;
  StreamSubscription? _subscription;
  final Ref _ref;

  // Stream controller for connection status updates
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  WebSocketService(this._ref);

  // MitmproxyClient instance for API requests

  Future<void> connect() async {
    if (_isConnected) {
      _log.success('WebSocket already connected');
      return;
    }
    fetchExistingFlows();

    final wsUrl =
        '${MitmproxyClient.websocketUrl}/updates?token=39d24913dbee653e3157035f5193e045';
    _log.debug('Attempting to connect to WebSocket: $wsUrl with cookies');

    try {
      _webSocket = await WebSocket.connect(
        wsUrl,
        headers: {'Cookie': MitmproxyClient.cookies},
      );

      _channel = IOWebSocketChannel(_webSocket!);
      _isConnected = true;
      _connectionStatusController.add(
        ConnectionStatus(isConnected: true, message: 'Connected to mitmproxy'),
      );

      _log.success('WebSocket connected successfully');

      // Set up stream listener
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
        cancelOnError: false,
      );

      // Now fetch existing flows after connection is established
    } catch (e) {
      _isConnected = false;
      _connectionStatusController.add(
        ConnectionStatus(
          isConnected: false,
          message: 'Connection error: $e',
          error: e,
        ),
      );
      _log.error('WebSocket connection failed: $e');
    }
  }

  void updateFilter(String filter) {
    if (_webSocket == null || !_isConnected) {
      _log.error('WebSocket is not connected, cannot update filter');
      return;
    }

    final filterMessage = jsonEncode({
      'type': 'flows/updateFilter',
      'payload': {'name': 'search', 'expr': filter},
    });
    _log.info('filterMessage: $filterMessage');
    _webSocket!.add(filterMessage);
    _log.debug('Filter updated: $filter');
  }

  void _handleMessage(dynamic message) {
    try {
      final decodedMessage = jsonDecode(message);
      final flowType = decodedMessage['type'];
      if (flowType == "flows/add" || flowType == "flows/update") {
        final Map<String, dynamic> flow = decodedMessage['payload']['flow'];
        final flowId = flow['id'];
        _log.debug("$flowType: ${flow['id']}");

        // Update the Flows
        _ref.read(flowsProvider.notifier).handleMessage(flow);
        // Notify listeners about new flow
        _connectionStatusController.add(
          ConnectionStatus(
            isConnected: true,
            message: 'Flow received: $flowId',
            hasNewData: true,
          ),
        );
        if (decodedMessage['payload']['matching_filters']['search'] == true) {
          _ref.read(filteredFlowsProvider.notifier).addNew(flowId);
        }
      } else if (flowType == 'flows/filterUpdate') {
        final result = decodedMessage['payload']['matching_flow_ids'];
        if (result == null) {
          // it means filter was reset
        } else {
          final ids = Set<String>.from(
            decodedMessage['payload']['matching_flow_ids'],
          );
          _ref.read(filteredFlowsProvider.notifier).updateInitial(ids);
          _log.success('Filter updated: ${decodedMessage['payload']}');
        }
      }
    } catch (e) {
      _log.error('Error parsing WebSocket message: $e');
      _log.error("error for mesage: $message");
    }
  }

  void _handleError(dynamic error) {
    _log.error('WebSocket Error: $error');
    _connectionStatusController.add(
      ConnectionStatus(
        isConnected: false,
        message: 'Connection error: $error',
        error: error,
      ),
    );
  }

  void _handleDisconnection() {
    _log.warn('WebSocket Disconnected');
    _isConnected = false;
    _connectionStatusController.add(
      ConnectionStatus(
        isConnected: false,
        message: 'Disconnected from WebSocket',
      ),
    );
  }

  Future<void> disconnect() async {
    if (_subscription != null) {
      await _subscription!.cancel();
      _subscription = null;
    }

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    if (_webSocket != null) {
      await _webSocket!.close();
      _webSocket = null;
    }

    _isConnected = false;
    _connectionStatusController.add(
      ConnectionStatus(isConnected: false, message: 'Disconnected manually'),
    );

    _log.info('WebSocket connection closed');
  }

  void dispose() {
    disconnect();
    _connectionStatusController.close();
  }

  /// Fetches existing flows from mitmproxy API
  /// This is called automatically when connecting,
  /// but can also be called manually to refresh flows
  Future<void> fetchExistingFlows() async {
    try {
      final flows = await MitmproxyClient.getFlows();
      _ref.read(flowsProvider.notifier).addAll(flows);
    } catch (e) {
      _log.error('Error fetching existing flows: $e');
    }
  }
}

class ConnectionStatus {
  final bool isConnected;
  final String message;
  final dynamic error;
  final bool hasNewData;

  ConnectionStatus({
    required this.isConnected,
    required this.message,
    this.error,
    this.hasNewData = false,
  });
}
