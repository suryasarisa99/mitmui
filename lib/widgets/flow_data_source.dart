import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../models/flow.dart' as models;
import '../utils/extensions.dart';

class FlowDataSource extends DataGridSource {
  List<models.Flow> _flows = [];
  List<DataGridRow> _flowRows = [];
  String? _selectedFlowId;
  int? _currentlyHighlightedRowIndex;

  // Getter to expose the flows list
  List<models.Flow> get flows => _flows;

  // Setter for selectedFlowId
  set selectedFlowId(String? id) {
    _selectedFlowId = id;
    notifyListeners();
  }

  FlowDataSource(this._flows) {
    _flowRows = _getFlowRows();
  }

  void updateFlows(List<models.Flow> flows) {
    _flows = flows;
    _flowRows = _getFlowRows();
    notifyListeners();
  }

  void setHighlightedRowIndex(int? index) {
    _currentlyHighlightedRowIndex = index;
    notifyListeners();
  }

  List<DataGridRow> _getFlowRows() {
    return _flows.mapIndexed<DataGridRow>((i, flow) {
      final hasResponse = flow.response != null;
      final methodColor = getMethodColor(flow.request.method);
      final statusColor = getStatusColor(
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
                ? formatBytes(flow.request.contentLength!)
                : '-',
          ),

          // Response Length Cell
          DataGridCell<String>(
            columnName: 'resLen',
            value: hasResponse && flow.response?.contentLength != null
                ? formatBytes(flow.response!.contentLength!)
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
    int? rowIndex;

    var idCell = row.getCells().firstWhere(
      (cell) => cell.columnName == 'id',
      orElse: () => DataGridCell<String>(columnName: 'id', value: ''),
    );

    rowIndex = int.tryParse(idCell.value);
    if (rowIndex != null && rowIndex >= 0 && rowIndex < _flows.length) {
      flowId = _flows[rowIndex].id;
    }

    // Check if this row is selected by the user
    final isSelected = flowId != null && flowId == _selectedFlowId;

    // Check if this row is highlighted by keyboard navigation
    final isHighlighted =
        rowIndex != null && rowIndex == _currentlyHighlightedRowIndex;

    // Determine the row color based on selection and highlighting states
    Color? rowColor;
    if (isSelected) {
      // Selected row gets a darker color
      rowColor = const Color.fromARGB(255, 39, 39, 42);
    }
    if (isHighlighted) {
      // Highlighted row (keyboard navigation) gets a slightly different color
      rowColor = const Color.fromARGB(255, 85, 85, 85);
    }

    return DataGridRowAdapter(
      color: rowColor,
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

  /// Get the color for a HTTP method (GET, POST, etc.)
  Color getMethodColor(String method) {
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

  /// Get the color for a HTTP status code
  Color getStatusColor(int? statusCode) {
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
  String formatBytes(int bytes) {
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
