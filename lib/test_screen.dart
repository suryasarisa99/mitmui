import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

import 'models/flow_store.dart';

const websocketUrl = 'ws://127.0.0.1:9090';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  WebSocketChannel? _channel;
  final List<String> _receivedMessages = [];
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      // Define cookies to include with WebSocket connection
      // final cookies = <String, String>{
      //   'auth': 'your_auth_cookie_value',
      //   'session': 'your_session_cookie_value',
      //   // Add more cookies as needed
      // };

      // Format cookies for the header
      // final cookieHeader = cookies.entries
      //     .map((e) => '${e.key}=${e.value}')
      //     .join('; ');

      final wsUrl =
          '$websocketUrl/updates?token=39d24913dbee653e3157035f5193e045';
      print('Attempting to connect to WebSocket: $wsUrl with cookies');

      // Use WebSocket.connect with headers for cookies
      WebSocket.connect(
            wsUrl,
            headers: {
              'Cookie':
                  '_xsrf=2|f1437e72|506e0dd7fde1a4449f495f7b2e8bddcb|1753168013; mitmproxy-auth-8081="2|1:0|10:1753171749|19:mitmproxy-auth-8081|4:eQ==|d85006a8176533962943668e0d63209e5a8984a864da55ade234a63f4de2e93f"',
            },
          )
          .then((webSocket) {
            _channel = IOWebSocketChannel(webSocket);
            print('WebSocket connected with cookies');

            // Set up stream listener
            _channel!.stream.listen(
              (message) {
                if (!mounted) return; // Check if widget is still mounted

                try {
                  final decodedMessage = jsonDecode(message);
                  if (decodedMessage['type'] == "flows/add") {
                    final flowData = decodedMessage["payload"]["flow"];
                    print(
                      "host: ${flowData['request']['pretty_host']},id: ${flowData['id']}",
                    );

                    // Update the FlowStore - Get provider from a safe context
                    try {
                      // Try to find FlowStore from the provider
                      if (mounted) {
                        // Check again before accessing context
                        // This is safer than using Provider.of with listen: false
                        final flowStore = Provider.of<FlowStore>(
                          context,
                          listen: false,
                        );
                        flowStore.handleMessage(message);

                        // Update UI state only if still mounted
                        if (mounted) {
                          setState(() {
                            _receivedMessages.add(
                              'Flow processed: ${flowData['request']['pretty_host'] ?? flowData['request']['host']}',
                            );
                          });
                        }
                      }
                    } catch (e) {
                      print('Error updating FlowStore: $e');
                      if (mounted) {
                        setState(() {
                          _receivedMessages.add('Error updating FlowStore: $e');
                        });
                      }
                    }
                  }
                } catch (e) {
                  print('Error parsing WebSocket message: $e');
                }
              },
              onError: (error) {
                print('WebSocket Error: $error');
                if (mounted) {
                  setState(() {
                    _receivedMessages.add('Error: $error');
                  });
                }
              },
              onDone: () {
                print('WebSocket Disconnected');
                if (mounted) {
                  setState(() {
                    _receivedMessages.add('Disconnected from WebSocket');
                  });
                }
              },
            );
          })
          .catchError((error) {
            print('WebSocket connection error: $error');
            if (mounted) {
              setState(() {
                _receivedMessages.add('Connection error: $error');
              });
            }
          });
    } catch (e) {
      print('WebSocket error: $e');
      if (mounted) {
        setState(() {
          _receivedMessages.add('Failed to initialize WebSocket: $e');
        });
      }
    }
  }

  void _sendMessage() {
    if (_channel != null && _messageController.text.isNotEmpty && mounted) {
      final message = _messageController.text;
      _channel!.sink.add(message);
      if (mounted) {
        setState(() {
          _receivedMessages.add('Sent: $message');
        });
        _messageController.clear();
      }
    }
  }

  @override
  void dispose() {
    // Make sure to properly close the WebSocket connection
    if (_channel != null) {
      print('Closing WebSocket connection in dispose');
      _channel!.sink.close();
      _channel = null;
    }
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mitmproxy WebSocket Listener')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Send a message (for testing)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: const Text('Send Message'),
                ),
                ElevatedButton(
                  onPressed: _connectWebSocket,
                  child: const Text('Reconnect'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _receivedMessages.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_receivedMessages[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
