import 'package:flutter/material.dart';
import 'package:mitmui/dt_table/dt_table.dart';
import 'package:mitmui/widgets/resize.dart';
import 'package:mitmui/utils/logger.dart';

import '../models/flow.dart' as models;
import '../store/flows_provider.dart';
import '../widgets/flow_data_grid.dart';
import '../widgets/flow_detail_panels.dart';

const _log = Logger("flow_list_screen");

class FlowListScreen extends StatefulWidget {
  const FlowListScreen({super.key});

  @override
  State<FlowListScreen> createState() => _FlowListScreenState();
}

class _FlowListScreenState extends State<FlowListScreen> {
  // Single data source for all flows

  // Controller for the data grid to track selection and highlighting
  final _dtController = DtController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the WebSocket service
    // final webSocketService = Provider.of<WebSocketService>(
    //   context,
    //   listen: false,
    // );
    final bg = Color(0xff1D1F21);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // if (didPop) {
        //   // webSocketService.disconnect();
        // }
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: kTextTabBarHeight - 10,
          actions: [
            // WebSocket connection status indicator
            // StreamBuilder<ConnectionStatus>(
            //   stream: webSocketService.connectionStatus,
            //   builder: (context, snapshot) {
            //     final isConnected =
            //         snapshot.hasData && snapshot.data!.isConnected;
            //     return IconButton(
            //       icon: Icon(
            //         isConnected ? Icons.cloud_done : Icons.cloud_off,
            //         color: isConnected ? Colors.green : Colors.red,
            //       ),
            //       onPressed: () {
            //         if (isConnected) {
            //           webSocketService.disconnect();
            //         } else {
            //           webSocketService.connect();
            //         }
            //       },
            //       tooltip: isConnected
            //           ? 'Connected to mitmproxy'
            //           : 'Disconnected',
            //     );
            //   },
            // ),
            // IconButton(
            //   icon: const Icon(Icons.delete_sweep),
            //   onPressed: () {
            //     showDialog(
            //       context: context,
            //       builder: (context) => AlertDialog(
            //         title: const Text('Clear Flows'),
            //         content: const Text(
            //           'Are you sure you want to clear all flows?',
            //         ),
            //         actions: [
            //           TextButton(
            //             onPressed: () => Navigator.pop(context),
            //             child: const Text('Cancel'),
            //           ),
            //           TextButton(
            //             onPressed: () {
            //               Provider.of<FlowsProvider>(
            //                 context,
            //                 listen: false,
            //               ).clear();
            //               Navigator.pop(context);
            //             },
            //             child: const Text('Clear'),
            //           ),
            //         ],
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return ResizableContainer(
      axis: Axis.vertical,
      dividerColor: Colors.grey[600]!,
      onDragDividerColor: Colors.red,
      onDragDividerWidth: 3,
      dividerWidth: 1,
      dividerHandleWidth: 18,
      maxRatio: 1,
      child1: FlowDataGrid(controller: _dtController),
      child2: BottomPannel(dtController: _dtController),
    );
  }
}
