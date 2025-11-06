import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitmui/global.dart';
import 'package:mitmui/screens/filter_manager.dart';
import 'package:mitmui/screens/status_screen.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:mitmui/widgets/flow_detail_panels.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/flow_list_screen.dart';

void main(
  // List<String> args
) async {
  WidgetsFlutterBinding.ensureInitialized();
  // print('args: $args');

  // if (args.firstOrNull == 'multi_window') {
  //   final windowId = int.parse(args[1]);
  //   final argument = args[2].isEmpty ? const {} : jsonDecode(args[2]);
  //   runApp(
  //     PannelWindow(
  //       windowController: WindowController.fromWindowId(windowId),
  //       args: argument,
  //     ),
  //   );
  //   return;
  // }

  await windowManager.ensureInitialized();
  const WindowOptions windowOptions = WindowOptions(
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Set minimum window size for desktop platforms
  // setWindowTitle('MITMproxy UI');
  // setWindowMinSize(const Size(800, 600));
  // setWindowMaxSize(Size.infinite);

  // Default window size
  // getCurrentScreen().then((screen) {
  //   if (screen != null) {
  //     final screenFrame = screen.visibleFrame;
  //     final width = screenFrame.width * 0.8;
  //     final height = screenFrame.height * 0.8;
  //     setWindowFrame(
  //       Rect.fromCenter(
  //         center: Offset(screenFrame.center.dx, screenFrame.center.dy),
  //         width: width,
  //         height: height,
  //       ),
  //     );
  //   }
  // });
  Logger.logLevel = LogLevel.debug;
  filterManager = FilterManager(auto: false);
  interceptManager = FilterManager(auto: false);
  // await MitmproxyClient.startMitm();
  // Create and initialize the FlowStore

  // Create the WebSocket service and pass the FlowStore

  debugPrint('Initializing FlowStore and WebSocket service...');

  // Run the app immediately
  runApp(ProviderScope(child: MainApp()));

  // Connect to the WebSocket server after app starts
  // This avoids potential issues with trying to update UI before it's ready
  // await Future.delayed(const Duration(milliseconds: 500));
}

final colorScheme = ColorScheme.fromSeed(
  seedColor: Color(0xffD13639),
  brightness: Brightness.dark,
  surface: const Color(0xff1C1E20),
);

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
      colorScheme: colorScheme,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
      ),
      scaffoldBackgroundColor: Color(0xff1C1E20),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xff1C1E20),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 25,
      ),
      secondaryHeaderColor: Color(0xff1C1E20),
      // primaryColor: Colors.green,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        isDense: true,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.5),
            width: 2,
          ),
        ),
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
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const FlowListScreen()),
    GoRoute(path: '/status', builder: (context, state) => const StatusScreen()),
  ],
);

class PanelWindow extends StatelessWidget {
  const PanelWindow({
    super.key,
    required this.windowController,
    required this.args,
  });
  final WindowController windowController;
  final Map<String, dynamic> args;

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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: baseTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system, // Use system theme preference
      home: Scaffold(
        backgroundColor: Color(0xff1C1E20),
        body: Column(
          children: [
            // if (args != null)
            //   Text(
            //     'Arguments: ${args.toString()}',
            //     style: const TextStyle(fontSize: 20),
            //   ),
            // ValueListenableBuilder<bool>(
            //   valueListenable: DesktopLifecycle.instance.isActive,
            //   builder: (context, active, child) {
            //     if (active) {
            //       return const Text('Window Active');
            //     } else {
            //       return const Text('Window Inactive');
            //     }
            //   },
            // ),
            // TextButton(
            //   onPressed: () async {
            //     windowController.close();
            //   },
            //   child: const Text('Close this window'),
            // ),
            SizedBox(height: 20),
            Expanded(child: BottomPannelAsFullScreen(args: args)),
          ],
        ),
      ),
    );
  }
}
