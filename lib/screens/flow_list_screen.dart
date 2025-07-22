// flow_list_screen.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
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

  // Selected flow for details view
  models.Flow? _selectedFlow;
  String? _selectedFlowId;

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

        return ResizableContainer(
          direction: Axis.vertical,
          children: [
            ResizableChild(
              divider: ResizableDivider(
                thickness: 1.0,
                padding: 18,
                color: const Color.fromARGB(255, 41, 42, 48),
              ),
              child: _buildDataTable(flows),
            ),
            ResizableChild(
              // divider: ResizableDivider(thickness: 8.0, color: Colors.red),
              child: ResizableContainer(
                children: [
                  // selected flow request summary
                  ResizableChild(
                    divider: ResizableDivider(
                      thickness: 1.0,
                      padding: 18,
                      color: const Color.fromARGB(255, 56, 57, 63),
                    ),
                    child: _buildRequestPanel(),
                  ),
                  // selected flow response summary
                  ResizableChild(
                    child: _buildResponsePanel(),
                  ),
                ],
                direction: Axis.horizontal,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataTable(List<models.Flow> flows) {
    // Update the data source with the flows
    _flowDataSource.updateFlows(flows);
    _flowDataSource._selectedFlowId = _selectedFlowId;
    return _buildSyncfusionDataGrid(_flowDataSource);
  }

  // Store column widths
  final Map<String, double> _columnWidths = {
    'id': 50,
    'url': 1100,
    'method': 80,
    'status': 60,
    'type': 150,
    'time': 100,
    'duration': 100,
    'reqLen': 100,
    'resLen': 100,
  };

  // Reset all column widths to their default values
  void _resetColumnWidths() {
    setState(() {
      _columnWidths['url'] = 1100;
      _columnWidths['method'] = 85;
      _columnWidths['status'] = 65;
      _columnWidths['type'] = 150;
      _columnWidths['time'] = 100;
      _columnWidths['duration'] = 90;
      _columnWidths['reqLen'] = 90;
      _columnWidths['resLen'] = 90;
    });
  }

  Widget _buildSyncfusionDataGrid(_FlowDataSource dataSource) {
    final headerCells = [
      (title: "Id", key: 'id'),
      (title: "URL", key: 'url'),
      (title: "Method", key: 'method'),
      (title: "Status", key: 'status'),
      (title: "Type", key: 'type'),
      (title: "Time", key: 'time'),
      (title: "Duration", key: 'duration'),
      (title: "Req", key: 'reqLen'),
      (title: "Res", key: 'resLen'),
    ];
    return Scrollbar(
      thickness: 8,
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
          rowHeight: 33,
          headerRowHeight: 30,
          showHorizontalScrollbar: false,
          allowColumnsDragging: true,
          // Freeze the method column for better usability
          frozenColumnsCount: 1,
          selectionMode: SelectionMode.single,
          onCellTap: (details) {
            if (details.rowColumnIndex.rowIndex > 0) {
              // Skip header row (index 0)
              int rowIndex = details.rowColumnIndex.rowIndex - 1;
              if (rowIndex < dataSource._flows.length) {
                setState(() {
                  _selectedFlow = dataSource._flows[rowIndex];
                  _selectedFlowId = _selectedFlow?.id;
                  print(
                    'Selected flow: ${_selectedFlow?.id} - ${_selectedFlow?.request.url}',
                  );
                });
              }
            }
          },
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
            for (final header in headerCells)
              GridColumn(
                columnName: header.key,
                width: _columnWidths[header.key]!,
                label: Container(
                  padding: EdgeInsets.only(left: header.key == 'url' ? 8.0 : 0),
                  alignment: header.key == 'url'
                      ? Alignment.centerLeft
                      : Alignment.center,
                  child: Text(
                    header.title,
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build the request panel with details from the selected flow
  Widget _buildRequestPanel() {
    if (_selectedFlow == null) {
      return const Center(child: Text('Select a flow to view details'));
    }

    final flow = _selectedFlow!;
    final request = flow.request;

    return Container(
      color: const Color.fromARGB(255, 25, 26, 32),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Request summary title
          Text(
            'Request',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _flowDataSource._getMethodColor(request.method),
            ),
          ),
          const SizedBox(height: 12),

          // Request URL
          Text(
            'URL: ${request.url}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          // Request method and HTTP version
          Text(
            'Method: ${request.method} (HTTP/${request.httpVersion})',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          // Content length if available
          if (request.contentLength != null)
            Text(
              'Content Length: ${_flowDataSource._formatBytes(request.contentLength!)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          const SizedBox(height: 16),

          // Headers section
          const Text(
            'Headers:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Headers list
          Expanded(
            child: ListView.builder(
              itemCount: request.headers.length,
              itemBuilder: (context, index) {
                final header = request.headers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14),
                      children: [
                        TextSpan(
                          text: '${header[0]}: ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 174, 185, 252),
                          ),
                        ),
                        TextSpan(
                          text: header[1],
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build the response panel with details from the selected flow
  Widget _buildResponsePanel() {
    if (_selectedFlow == null) {
      return const Center(child: Text('Select a flow to view details'));
    }

    final flow = _selectedFlow!;
    final response = flow.response;

    if (response == null) {
      return const Center(
        child: Text(
          'No response available',
          style: TextStyle(color: Colors.orange),
        ),
      );
    }

    final statusColor = _flowDataSource._getStatusColor(response.statusCode);

    return Container(
      color: const Color.fromARGB(255, 25, 26, 32),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Response summary title with status code
          Row(
            children: [
              const Text(
                'Response',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${response.statusCode} ${response.reason}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // HTTP version
          Text(
            'HTTP Version: ${response.httpVersion}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          // Content type if available
          if (response.contentType != null)
            Text(
              'Content Type: ${response.contentType}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          const SizedBox(height: 8),

          // Content length if available
          if (response.contentLength != null)
            Text(
              'Content Length: ${_flowDataSource._formatBytes(response.contentLength!)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          const SizedBox(height: 16),

          // Headers section
          const Text(
            'Headers:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Headers list
          Expanded(
            child: ListView.builder(
              itemCount: response.headers.length,
              itemBuilder: (context, index) {
                final header = response.headers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14),
                      children: [
                        TextSpan(
                          text: '${header[0]}: ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 174, 185, 252),
                          ),
                        ),
                        TextSpan(
                          text: header[1],
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowDataSource extends DataGridSource {
  List<models.Flow> _flows = [];
  List<DataGridRow> _flowRows = [];
  String? _selectedFlowId;

  _FlowDataSource(this._flows) {
    _flowRows = _getFlowRows();
  }

  void updateFlows(List<models.Flow> flows) {
    _flows = flows;
    _flowRows = _getFlowRows();
    notifyListeners();
  }

  List<DataGridRow> _getFlowRows() {
    return _flows.mapIndexed<DataGridRow>((i, flow) {
      final hasResponse = flow.response != null;
      final methodColor = _getMethodColor(flow.request.method);
      final statusColor = _getStatusColor(
        hasResponse ? flow.response!.statusCode : null,
      );

      return DataGridRow(
        cells: [
          // ID Cell
          DataGridCell<String>(columnName: 'id', value: i.toString()),

          // URL Cell with styled hostname and path
          DataGridCell<Widget>(
            columnName: 'url',
            value: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  // Hostname part styled differently
                  TextSpan(
                    text: flow.request.prettyHost ?? flow.request.host,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 174, 185, 252),
                    ),
                  ),
                  // Path part
                  TextSpan(
                    text: flow.request.path,
                    style: const TextStyle(
                      color: Color.fromARGB(221, 159, 173, 183),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Method Cell
          DataGridCell<Widget>(
            columnName: 'method',
            value: Container(
              // padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              // decoration: BoxDecoration(
              //   color: methodColor.withOpacity(0.2),
              //   borderRadius: BorderRadius.circular(4),
              // ),
              child: Text(
                flow.request.method,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
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

          // Duration Cell - time between request and response in ms
          DataGridCell<String>(
            columnName: 'duration',
            value:
                hasResponse &&
                    flow.response?.timestampEnd != null &&
                    flow.request.timestampStart != null
                ? '${((flow.response!.timestampEnd - flow.request.timestampStart!) * 1000).round()} ms'
                : '-',
          ),

          // Request Length Cell
          DataGridCell<String>(
            columnName: 'reqLen',
            value: flow.request.contentLength != null
                ? _formatBytes(flow.request.contentLength!)
                : '-',
          ),

          // Response Length Cell
          DataGridCell<String>(
            columnName: 'resLen',
            value: hasResponse && flow.response?.contentLength != null
                ? _formatBytes(flow.response!.contentLength!)
                : '-',
          ),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _flowRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    // Get the flow ID from this row to check if it's selected
    String? flowId;
    var idCell = row.getCells().firstWhere(
      (cell) => cell.columnName == 'id',
      orElse: () => DataGridCell<String>(columnName: 'id', value: ''),
    );
    
    int? index = int.tryParse(idCell.value.toString());
    if (index != null && index >= 0 && index < _flows.length) {
      flowId = _flows[index].id;
    }
    
    final isSelected = flowId != null && flowId == _selectedFlowId;
    
    return DataGridRowAdapter(
      color: isSelected ? const Color.fromARGB(255, 45, 47, 59) : null,
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

  /// Format bytes into a human-readable string (KB, MB, etc.)
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
