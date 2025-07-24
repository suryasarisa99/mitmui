import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/screens/status_screen.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart';
import 'screens/flow_list_screen.dart';
import 'store/flows_provider.dart';
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

  // Create the WebSocket service and pass the FlowStore

  debugPrint('Initializing FlowStore and WebSocket service...');

  // Run the app immediately
  runApp(ProviderScope(child: MainApp()));

  // Connect to the WebSocket server after app starts
  // This avoids potential issues with trying to update UI before it's ready
  await Future.delayed(const Duration(milliseconds: 500));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

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

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: baseTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system, // Use system theme preference
      routerConfig: router,
    );
  }
}

final GoRouter router = GoRouter(
  initialLocation: '/status',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const FlowListScreen()),
    GoRoute(path: '/status', builder: (context, state) => const StatusScreen()),
  ],
);
