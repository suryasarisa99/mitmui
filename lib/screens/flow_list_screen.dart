// flow_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../models/flow.dart' as models;
import '../models/flow_store.dart';
import '../services/websocket_service.dart';

class FlowListScreen extends StatefulWidget {
  const FlowListScreen({super.key});

  @override
  State<FlowListScreen> createState() => _FlowListScreenState();
}

class _FlowListScreenState extends State<FlowListScreen> {
  // Single data source for all flows
  late _FlowDataSource _flowDataSource;

  @override
  void initState() {
    super.initState();
    // Initialize with empty data - will be updated by the Consumer
    _flowDataSource = _FlowDataSource([]);
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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          webSocketService.disconnect();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MITMproxy Flows'),
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

  Widget _buildFlowList(List<models.Flow> Function(FlowStore) flowSelector) {
    // Make sure we can access the provider
    print('Trying to access FlowStore provider...');

    try {
      // Try to verify provider is available
      final directCheck = Provider.of<FlowStore>(context, listen: false);
      print(
        'SUCCESS: Direct Provider check - FlowStore found with ${directCheck.count} flows',
      );
    } catch (e) {
      print('ERROR: Direct Provider check failed: $e');
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
        print(
          'SUCCESS: Consumer builder called with FlowStore, count: ${flowStore.count}',
        );

        final flows = flowSelector(flowStore);
        print('Filtered ${flows.length} flows based on selector');

        if (flows.isEmpty) {
          return const Center(child: Text('No flows available'));
        }

        return _buildDataTable(flows);
      },
    );
  }

  Widget _buildDataTable(List<models.Flow> flows) {
    // Update the data source with the flows
    _flowDataSource.updateFlows(flows);
    return _buildSyncfusionDataGrid(_flowDataSource);
  }

  // Store column widths
  final Map<String, double> _columnWidths = {
    'url': 1100,
    'method': 80,
    'status': 80,
    'type': 150,
    'time': 100,
  };

  // Reset all column widths to their default values
  void _resetColumnWidths() {
    setState(() {
      _columnWidths['url'] = 1100;
      _columnWidths['method'] = 100;
      _columnWidths['status'] = 80;
      _columnWidths['type'] = 150;
      _columnWidths['time'] = 100;
    });
  }

  Widget _buildSyncfusionDataGrid(_FlowDataSource dataSource) {
    return Scrollbar(
      thickness: 6.0,
      radius: const Radius.circular(8.0),
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          // Show context menu on right-click
          final RenderBox overlay =
              Overlay.of(context).context.findRenderObject() as RenderBox;

          showMenu(
            context: context,
            position: RelativeRect.fromRect(
              details.globalPosition & const Size(1, 1),
              Offset.zero & overlay.size,
            ),
            items: [
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: const [
                    Icon(Icons.restore),
                    SizedBox(width: 8),
                    Text('Reset Column Widths'),
                  ],
                ),
              ),
            ],
          ).then((value) {
            if (value == 'reset') {
              _resetColumnWidths();
            }
          });
        },
        child: SfDataGrid(
          source: dataSource,
          allowColumnsResizing: true,
          allowSorting: true,
          allowMultiColumnSorting: true,
          allowTriStateSorting: true,
          isScrollbarAlwaysShown: true,
          columnResizeMode: ColumnResizeMode.onResize,
          columnWidthMode: ColumnWidthMode.fill, // Fill available space
          showColumnHeaderIconOnHover: true, // Show resize indicator on hover
          highlightRowOnHover: true, // Better UX for desktop
          navigationMode: GridNavigationMode.cell, // Enable keyboard navigation
          rowHeight: 35,
          frozenColumnsCount:
              1, // Freeze the method column for better usability
          onColumnResizeUpdate: (ColumnResizeUpdateDetails details) {
            // Don't allow columns to be sized too small
            if (details.width < 60) {
              return false;
            }

            setState(() {
              // Update the column width in our map
              _columnWidths[details.column.columnName] = details.width;
              print(
                "Column ${details.column.columnName} resized to ${details.width}",
              );
            });
            return true;
          },
          gridLinesVisibility: GridLinesVisibility.both,
          headerGridLinesVisibility: GridLinesVisibility.both,
          columns: <GridColumn>[
            GridColumn(
              columnName: 'url',
              width: _columnWidths['url']!,
              label: Container(
                padding: const EdgeInsets.all(8),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'URL',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            GridColumn(
              columnName: 'method',
              width: _columnWidths['method']!,
              label: Container(
                // padding: const EdgeInsets.all(8),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'METHOD',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            GridColumn(
              columnName: 'status',
              width: _columnWidths['status']!,
              label: Container(
                // padding: const EdgeInsets.all(8),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'STATUS',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            GridColumn(
              columnName: 'type',
              width: _columnWidths['type']!,
              label: Container(
                // padding: const EdgeInsets.all(8),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'TYPE',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            GridColumn(
              columnName: 'time',
              width: _columnWidths['time']!,
              label: Container(
                padding: const EdgeInsets.all(8),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'TIME',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Our _getMethodColor has been moved to the DataSource class
}

class _FlowDataSource extends DataGridSource {
  List<models.Flow> _flows = [];
  List<DataGridRow> _flowRows = [];

  _FlowDataSource(this._flows) {
    _flowRows = _getFlowRows();
  }

  void updateFlows(List<models.Flow> flows) {
    _flows = flows;
    _flowRows = _getFlowRows();
    notifyListeners();
  }

  List<DataGridRow> _getFlowRows() {
    return _flows.map<DataGridRow>((flow) {
      final hasResponse = flow.response != null;
      final methodColor = _getMethodColor(flow.request.method);
      final statusColor = _getStatusColor(
        hasResponse ? flow.response!.statusCode : null,
      );

      // Combine host and path into a URL
      final String url =
          "${flow.request.prettyHost ?? flow.request.host}${flow.request.path}";

      return DataGridRow(
        cells: [
          // URL Cell (combined host + path)
          DataGridCell<String>(columnName: 'url', value: url),

          // Method Cell
          DataGridCell<Widget>(
            columnName: 'method',
            value: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              decoration: BoxDecoration(
                color: methodColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                flow.request.method,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: methodColor,
                ),
              ),
            ),
          ),

          // Status Cell
          DataGridCell<Widget>(
            columnName: 'status',
            value: flow.isWebSocket
                ? const Text('WS')
                : hasResponse
                ? Text(
                    flow.response!.statusCode.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  )
                : const Text('-'),
          ),

          // Type Cell
          DataGridCell<String>(
            columnName: 'type',
            value: flow.isWebSocket
                ? 'WebSocket'
                : flow.response?.contentType?.split(';').first ?? '-',
          ),

          // Time Cell
          DataGridCell<String>(
            columnName: 'time',
            value: flow.createdDateTime.toLocal().toString().substring(11, 19),
          ),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _flowRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((dataGridCell) {
        // For cells that contain a Widget directly
        if (dataGridCell.value is Widget) {
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(8.0),
            child: dataGridCell.value as Widget,
          );
        }

        // For text cells (strings)
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(8.0),
          child: Text(
            dataGridCell.value.toString(),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(int? statusCode) {
    if (statusCode == null) return Colors.grey;

    if (statusCode >= 200 && statusCode < 300) {
      return Colors.green;
    } else if (statusCode >= 300 && statusCode < 400) {
      return Colors.blue;
    } else if (statusCode >= 400 && statusCode < 500) {
      return Colors.orange;
    } else if (statusCode >= 500) {
      return Colors.red;
    }
    return Colors.grey;
  }
}
