// websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/io.dart';
import '../models/flow_store.dart';

class WebSocketService {
  static const String websocketUrl = 'ws://127.0.0.1:9090';
  static const String cookieHeader =
      ' mitmproxy-auth-8081="2|1:0|10:1753187602|19:mitmproxy-auth-8081|4:eQ==|89ed72c87fc0c9a43e0e6b75c54347899e3842fa6c075c13a7f04da4c43d3bc5"; _xsrf=2|fcf806bb|e5372d26882fc6c2c6b6c23742626c5b|1753187602';

  IOWebSocketChannel? _channel;
  WebSocket? _webSocket;
  StreamSubscription? _subscription;
  final FlowStore _flowStore;

  // Stream controller for connection status updates
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  WebSocketService(this._flowStore);

  Future<void> connect() async {
    if (_isConnected) {
      print('WebSocket already connected');
      return;
    }

    final wsUrl =
        '$websocketUrl/updates?token=39d24913dbee653e3157035f5193e045';
    print('Attempting to connect to WebSocket: $wsUrl with cookies');

    try {
      _webSocket = await WebSocket.connect(
        wsUrl,
        headers: {'Cookie': cookieHeader},
      );

      _channel = IOWebSocketChannel(_webSocket!);
      _isConnected = true;
      _connectionStatusController.add(
        ConnectionStatus(isConnected: true, message: 'Connected to mitmproxy'),
      );

      print('WebSocket connected successfully');

      // Set up stream listener
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );
    } catch (e) {
      _isConnected = false;
      _connectionStatusController.add(
        ConnectionStatus(
          isConnected: false,
          message: 'Connection error: $e',
          error: e,
        ),
      );
      print('WebSocket connection failed: $e');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final decodedMessage = jsonDecode(message);
      final flowType = decodedMessage['type'];
      final flow = decodedMessage['payload']['flow'];
      if (flowType == "flows/add" || flowType == "flows/update") {
        print(
          "$flowType: ${flow['request']['pretty_host']}, id: ${flow['id']}",
        );

        // Update the FlowStore
        _flowStore.handleMessage(message);

        // Notify listeners about new flow
        _connectionStatusController.add(
          ConnectionStatus(
            isConnected: true,
            message:
                'Flow received: ${flow['request']['pretty_host'] ?? flow['request']['host']}',
            hasNewData: true,
          ),
        );
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  void _handleError(dynamic error) {
    print('WebSocket Error: $error');
    _connectionStatusController.add(
      ConnectionStatus(
        isConnected: false,
        message: 'Connection error: $error',
        error: error,
      ),
    );
  }

  void _handleDisconnection() {
    print('WebSocket Disconnected');
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

    print('WebSocket connection closed');
  }

  void dispose() {
    disconnect();
    _connectionStatusController.close();
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
