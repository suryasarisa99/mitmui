import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../models/flow.dart' as models;
import '../store/flow_store.dart';
import '../services/websocket_service.dart';
import '../widgets/flow_data_grid.dart';
import '../widgets/flow_data_source.dart';
import '../widgets/flow_detail_panels.dart';

const _log = Logger("flow_list_screen");

class FlowListScreen extends StatefulWidget {
  const FlowListScreen({super.key});

  @override
  State<FlowListScreen> createState() => _FlowListScreenState();
}

class _FlowListScreenState extends State<FlowListScreen> {
  // Single data source for all flows
  late FlowDataSource _flowDataSource;

  // Controller for the data grid to track selection and highlighting
  final DataGridController _dataGridController = DataGridController();

  @override
  void initState() {
    super.initState();
    _flowDataSource = FlowDataSource(
      [],
      dataGridController: _dataGridController,
    );
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
        body: _buildFlowList((store) => store.flows),
      ),
    );
  }

  Widget _buildFlowList(
    List<models.MitmFlow> Function(FlowsProvider) flowSelector,
  ) {
    return ResizableContainer(
      direction: Axis.vertical,
      children: [
        ResizableChild(
          divider: ResizableDivider(
            padding: 5,
            thickness: 0.6,
            color: Colors.grey[800]!,
          ),
          child: _buildDataTable(),
        ),
        ResizableChild(
          child: BottomPannel(dataGridController: _dataGridController),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return Consumer(
      builder: (context, ref, child) {
        final flowsMap = ref.watch(flowsProvider);
        _flowDataSource.updateFlows(flowsMap.values.toList());
        return FlowDataGrid(
          dataSource: _flowDataSource,
          controller: _dataGridController,
        );
      },
    );
  }
}
