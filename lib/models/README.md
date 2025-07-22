# MITM UI - Flow Models

This folder contains model classes for working with mitmproxy flows in your Flutter application.

## Model Structure

The primary models created for handling mitmproxy flows are:

1. `Flow` - Represents a complete mitmproxy flow with all its components
2. `ClientConnection` - Contains client connection details
3. `ServerConnection` - Contains server connection details
4. `Certificate` - Represents a TLS certificate
5. `HttpRequest` - Contains HTTP request details
6. `HttpResponse` - Contains HTTP response details
7. `WebSocketInfo` - Contains information about WebSocket connections

## Usage

### Integration with mitmproxy WebSocket

Your `TestScreen` already connects to a mitmproxy WebSocket. To process flows:

```dart
import 'models/flow.dart';
import 'models/flow_store.dart';

// In your WebSocket listener
void handleWebSocketMessage(String message) {
  // Parse the flow from the WebSocket message
  final flow = Flow.parseFlowMessage(message);
  if (flow != null) {
    // Add it to the flow store
    flowStore.addOrUpdateFlow(flow);
  }
}
```

### Setting Up with Provider

1. Make sure you've added provider to your dependencies:

```yaml
dependencies:
  provider: ^6.1.2
```

2. Wrap your app with a MultiProvider:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (context) => FlowStore()),
  ],
  child: MaterialApp(
    // ...
  ),
)
```

3. Access the FlowStore in your widgets:

```dart
// Read only
final flowStore = context.watch<FlowStore>();

// For methods that modify state
Provider.of<FlowStore>(context, listen: false).addOrUpdateFlow(flow);
```

## Customizing the Flow Display

The `FlowListScreen` provides a basic UI for displaying flows. You can customize it further by:

1. Adding a detail screen for viewing flow details
2. Implementing filtering and searching features
3. Adding export functionality for flows
4. Adding visualizations for response times, content types, etc.

## Mitmproxy WebSocket Protocol

The mitmproxy WebSocket protocol sends messages with the following format:

```json
{
  "type": "flows/add",
  "payload": {
    "flow": {
      // Flow data
    }
  }
}
```

The model handles parsing these messages automatically through the `Flow.parseFlowMessage()` method.

## Example Integration

The `main_example.dart` file shows how to integrate the Flow models with your existing WebSocket test screen.
