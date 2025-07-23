import 'package:flutter/material.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart';
import 'screens/flow_list_screen.dart';
import 'models/flow_store.dart';
import 'services/websocket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set minimum window size for desktop platforms
  setWindowTitle('MITMproxy UI');
  setWindowMinSize(const Size(1200, 800));
  setWindowMaxSize(Size.infinite);

  // Default window size
  getCurrentScreen().then((screen) {
    if (screen != null) {
      final screenFrame = screen.visibleFrame;
      final width = screenFrame.width * 0.8;
      final height = screenFrame.height * 0.8;
      setWindowFrame(
        Rect.fromCenter(
          center: Offset(screenFrame.center.dx, screenFrame.center.dy),
          width: width,
          height: height,
        ),
      );
    }
  });
  Logger.logLevel = LogLevel.info;
  await MitmproxyClient.startMitm();
  // Create and initialize the FlowStore
  final flowStore = FlowStore();

  // Create the WebSocket service and pass the FlowStore
  final webSocketService = WebSocketService(flowStore);

  debugPrint('Initializing FlowStore and WebSocket service...');

  // Run the app immediately
  runApp(MainApp(flowStore: flowStore, webSocketService: webSocketService));

  // Connect to the WebSocket server after app starts
  // This avoids potential issues with trying to update UI before it's ready
  await Future.delayed(const Duration(milliseconds: 500));
  webSocketService.connect();
}

class MainApp extends StatelessWidget {
  final FlowStore flowStore;
  final WebSocketService webSocketService;

  const MainApp({
    super.key,
    required this.flowStore,
    required this.webSocketService,
  });

  @override
  Widget build(BuildContext context) {
    // Use a desktop-optimized theme with more neutral colors and less rounded corners
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.red,
      brightness: Brightness.light,
    );

    final darkTheme = ThemeData(
      useMaterial3: false,
      colorSchemeSeed: const Color.fromARGB(255, 255, 55, 55),
      brightness: Brightness.dark,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
      ),
    );

    return MultiProvider(
      providers: [
        // Use the pre-created FlowStore instance
        ChangeNotifierProvider.value(value: flowStore),
        // Provide the WebSocket service
        Provider.value(value: webSocketService),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: baseTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system, // Use system theme preference
        home: const FlowListScreen(),
      ),
    );
  }
}
