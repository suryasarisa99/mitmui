import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:mitmui/widgets/flow_detail_url.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../models/flow.dart' as models;
import '../models/flow_store.dart';
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

  // Selected flow for details view
  models.MitmFlow? _selectedFlow;
  String? _selectedFlowId;

  @override
  void initState() {
    super.initState();
    // Initialize with empty data - will be updated by the Consumer
    _flowDataSource = FlowDataSource([]);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the WebSocket service
    final webSocketService = Provider.of<WebSocketService>(
      context,
      listen: false,
    );
    final bg = Color(0xff1D1F21);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          webSocketService.disconnect();
        }
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
            StreamBuilder<ConnectionStatus>(
              stream: webSocketService.connectionStatus,
              builder: (context, snapshot) {
                final isConnected =
                    snapshot.hasData && snapshot.data!.isConnected;
                return IconButton(
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
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Flows'),
                    content: const Text(
                      'Are you sure you want to clear all flows?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Provider.of<FlowStore>(
                            context,
                            listen: false,
                          ).clear();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: _buildFlowList((store) => store.flows),
      ),
    );
  }

  Widget _buildFlowList(
    List<models.MitmFlow> Function(FlowStore) flowSelector,
  ) {
    try {
      // Try to verify provider is available
      Provider.of<FlowStore>(context, listen: false);
    } catch (e) {
      _log.error('ERROR: Direct Provider check failed: $e');
      // Return an error placeholder if provider is not available
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Provider error: ${e.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Force rebuild of the widget
                setState(() {});
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // If we get here, the provider exists, use a Consumer to listen to changes
    return Consumer<FlowStore>(
      builder: (context, flowStore, child) {
        _log.info(
          'Consumer builder called with FlowStore, count: ${flowStore.count}',
        );

        final flows = flowSelector(flowStore);
        _log.debug('Filtered ${flows.length} flows based on selector');

        if (flows.isEmpty) {
          return const Center(child: Text('No flows available'));
        }

        return ResizableContainer(
          direction: Axis.vertical,
          children: [
            ResizableChild(
              divider: ResizableDivider(
                padding: 5,
                thickness: 0.6,

                color: Colors.grey[800]!,
              ),
              child: _buildDataTable(flows),
            ),
            if (_selectedFlowId != null)
              ResizableChild(
                // divider: ResizableDivider(thickness: 8.0, color: Colors.red),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FlowDetailURL(
                        scheme: _selectedFlow?.request.scheme ?? '',
                        host: _selectedFlow?.request.prettyHost ?? '',
                        path: _selectedFlow?.request.path ?? '',
                        statusCode: _selectedFlow?.response?.statusCode ?? 0,
                        method: _selectedFlow?.request.method ?? '',
                      ),
                      Expanded(
                        child: ResizableContainer(
                          children: [
                            // selected flow request summary
                            ResizableChild(
                              divider: ResizableDivider(
                                thickness: 1.0,
                                padding: 18,
                                color: const Color.fromARGB(255, 56, 57, 63),
                              ),
                              child: RequestDetailsPanel(flow: _selectedFlow),
                            ),
                            // selected flow response summary
                            ResizableChild(
                              child: ResponseDetailsPanel(flow: _selectedFlow),
                            ),
                          ],
                          direction: Axis.horizontal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDataTable(List<models.MitmFlow> flows) {
    // Update the data source with the flows
    _flowDataSource.updateFlows(flows);

    // Set the selected flow ID in the data source using the public setter
    _flowDataSource.selectedFlowId = _selectedFlowId;

    return FlowDataGrid(
      dataSource: _flowDataSource,
      controller: _dataGridController,
      onFlowSelected: (flow) {
        setState(() {
          _selectedFlow = flow;
          _selectedFlowId = flow.id;
          _log.debug(
            'Selected flow: ${_selectedFlow?.id} - ${_selectedFlow?.request.url}',
          );
        });
      },
    );
  }
}
