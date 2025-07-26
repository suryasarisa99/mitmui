// status_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';
import '../store/flows_provider.dart';

class StatusScreen extends ConsumerStatefulWidget {
  const StatusScreen({super.key});

  @override
  ConsumerState<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends ConsumerState<StatusScreen> {
  final List<String> _statusMessages = [];
  bool _isConnected = false;
  late final webSocketService = ref.read(websocketServiceProvider);

  @override
  void initState() {
    super.initState();
    // Connect to the WebSocket when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToWebSocketService();
    });
  }

  void _subscribeToWebSocketService() {
    if (!webSocketService.isConnected) {
      webSocketService.connect();
    }

    webSocketService.connectionStatus.listen((status) {
      if (mounted) {
        setState(() {
          _isConnected = status.isConnected;
          _statusMessages.add(
            '${DateTime.now().toString().substring(0, 19)}: ${status.message}',
          );

          // Limit the number of messages to prevent memory issues
          if (_statusMessages.length > 100) {
            _statusMessages.removeRange(0, 50);
          }
        });
      }
    });
  }

  void _reconnect() {
    // Disconnect first if already connected
    if (webSocketService.isConnected) {
      webSocketService.disconnect().then((_) {
        webSocketService.connect();
      });
    } else {
      webSocketService.connect();
    }
  }

  void _clearFlows() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Flows'),
        content: const Text('Are you sure you want to clear all flows?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(flowsProvider.notifier).clear();
              Navigator.pop(context);
              setState(() {
                _statusMessages.add(
                  '${DateTime.now().toString().substring(0, 19)}: Cleared all flows',
                );
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('mitmproxy Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reconnect,
            tooltip: 'Reconnect WebSocket',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearFlows,
            tooltip: 'Clear all flows',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.check_circle : Icons.error,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isConnected
                              ? 'Connected to mitmproxy'
                              : 'Disconnected',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Text('Total flows captured: ${flowStore.count}'),
                    // const SizedBox(height: 4),
                    // Text('HTTP flows: ${flowStore.httpFlows.length}'),
                    // const SizedBox(height: 4),
                    // Text('WebSocket flows: ${flowStore.webSocketFlows.length}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Connection Log',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Status messages list
            Expanded(
              child: Card(
                child: ListView.builder(
                  itemCount: _statusMessages.length,
                  itemBuilder: (context, index) {
                    final reversedIndex = _statusMessages.length - 1 - index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Text(_statusMessages[reversedIndex]),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Reconnect button
            SizedBox(
              width: 300,
              child: ElevatedButton.icon(
                onPressed: _reconnect,
                icon: const Icon(Icons.refresh),
                label: const Text('Reconnect'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () => GoRouter.of(context).replace('/filter'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Filter Demo Screen'),
              ),
            ),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () => GoRouter.of(context).replace('/'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Flow List'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
