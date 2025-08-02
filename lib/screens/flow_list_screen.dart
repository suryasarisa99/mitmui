import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/dialog/token_input_dialog.dart';
import 'package:mitmui/dt_table/dt_table.dart';
import 'package:mitmui/services/websocket_service.dart';
import 'package:mitmui/theme.dart';
import 'package:mitmui/widgets/resize.dart';
import 'package:mitmui/utils/logger.dart';
import '../widgets/flow_data_grid.dart';
import '../widgets/flow_detail_panels.dart';

const _log = Logger("flow_list_screen");

class FlowListScreen extends ConsumerStatefulWidget {
  const FlowListScreen({super.key});

  @override
  ConsumerState<FlowListScreen> createState() => _FlowListScreenState();
}

class _FlowListScreenState extends ConsumerState<FlowListScreen> {
  // Single data source for all flows

  // Controller for the data grid to track selection and highlighting
  final _dtController = DtController();
  late final WebSocketService webSocketService = ref.read(
    websocketServiceProvider,
  );

  @override
  void initState() {
    // webSocketService.connect();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Subscribe to WebSocket service after the first frame
      showInputPopup();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void showInputPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return TokenInputDialog();
      },
    ).then((_) {
      webSocketService.connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.from(Theme.brightnessOf(context));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          webSocketService.disconnect();
        }
      },
      child: Scaffold(
        backgroundColor: theme.surfaceDark,
        appBar: AppBar(
          backgroundColor: theme.surfaceDark,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: kTextTabBarHeight - 20,
          actions: [
            // WebSocket connection status indicator
            StreamBuilder<ConnectionStatus>(
              stream: webSocketService.connectionStatus,
              builder: (context, snapshot) {
                final isConnected =
                    snapshot.hasData && snapshot.data!.isConnected;
                return IconButton(
                  iconSize: 18,
                  icon: Icon(
                    isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                  onPressed: () {
                    if (isConnected) {
                      webSocketService.disconnect();
                    } else {
                      webSocketService.connect();
                    }
                  },
                  tooltip: isConnected
                      ? 'Connected to mitmproxy'
                      : 'Disconnected',
                );
              },
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final theme = AppTheme.from(Theme.brightnessOf(context));
    return Container(
      color: theme.surfaceDark,
      child: ResizableContainer(
        axis: Axis.vertical,
        dividerColor: Colors.grey[600]!,
        onDragDividerColor: Colors.red,
        onDragDividerWidth: 3,
        dividerWidth: 1,
        dividerHandleWidth: 18,
        maxRatio: 1,
        child1: FlowDataGrid(controller: _dtController),
        child2: BottomPannel(dtController: _dtController),
      ),
    );
  }
}
