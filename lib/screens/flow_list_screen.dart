import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/dialog/token_input_dialog.dart';
import 'package:mitmui/dt_table/dt_models.dart';
import 'package:mitmui/dt_table/dt_table.dart';
import 'package:mitmui/global.dart';
import 'package:mitmui/services/websocket_service.dart';
import 'package:mitmui/theme.dart';
import 'package:mitmui/widgets/filter/filter_btn.dart';
import 'package:mitmui/widgets/bottom_panel/bottom_panel.dart';
import 'package:mitmui/widgets/resize.dart';
import '../widgets/flow_data_grid.dart';

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
  final resizeController = ResizableController();
  final flowId = ValueNotifier<String?>(null);

  @override
  void initState() {
    // webSocketService.connect();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Subscribe to WebSocket service after the first frame
      check();
    });
    // hide bottom panel initially
    resizeController.hideSecondChild();
    _dtController.addSpecificListener(_flowIdListener);
  }

  void _flowIdListener(DtControllerChange change) {
    if (change.type == ChangeType.focusedRow) {
      String? rowId = _dtController.focusedRowId;
      if (rowId == null) {
        resizeController.hideSecondChild();
        return;
      }
      if (rowId != flowId.value) {
        if (resizeController.isChild2Hidden) {
          resizeController.showSecondChild();
        }
        setState(() {
          flowId.value = rowId;
        });
      }
    }
  }

  void check() async {
    final status = await MitmproxyClient.isRunning();
    debugPrint('mitm status: $status');
    if (status == 1 || status == 2) {
      // 1 - mitm is running (no password)
      // 2 - mitm is running (with password)
      final token = prefs.getString(status == 1 ? 'token' : 'password')!;
      handleToken(token);
    } else if (status == -1) {
      // mitm is not running
      showInputPopup();
    } else if (status == 3) {
      // port is used by other process
    }
  }

  void handleToken(token) async {
    final result = await MitmproxyClient.getCookieFromToken(token);
    if (result) {
      return webSocketService.connect();
    }
    showInputPopup();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void showInputPopup() {
    showDialog(
      barrierDismissible: false,
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
          centerTitle: true,
          title: const Text(
            'MitmUI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          toolbarHeight: kTextTabBarHeight - 16,
          actionsPadding: const EdgeInsets.only(right: 8, top: 6, bottom: 5),
          actions: [
            FilterBtn(filterManager: filterManager, title: "filter"),
            SizedBox(width: 8),
            FilterBtn(filterManager: interceptManager, title: "intercept"),
            SizedBox(width: 8),
            // WebSocket connection status indicator
            StreamBuilder<ConnectionStatus>(
              stream: webSocketService.connectionStatus,
              builder: (context, snapshot) {
                final isConnected =
                    snapshot.hasData && snapshot.data!.isConnected;
                return IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
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
        controller: resizeController,
        axis: Axis.vertical,
        dividerColor: Colors.grey[600]!,
        onDragDividerColor: Colors.red,
        onDragDividerWidth: 3,
        dividerWidth: 1,
        dividerHandleWidth: 18,
        maxRatio: 1,
        child1: FlowDataGrid(controller: _dtController),
        child2: BottomPanel(dtController: _dtController, flowId: flowId),
      ),
    );
  }
}
