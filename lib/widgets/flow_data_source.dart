import 'package:flutter/material.dart';
import 'package:mitmui/utils/statusCode.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../models/flow.dart' as models;
import '../utils/extensions.dart';

class FlowDataSource extends DataGridSource {
  List<models.MitmFlow> _flows = [];
  List<DataGridRow> _flowRows = [];
  String? _selectedFlowId;

  // Getter to expose the flows list
  List<models.MitmFlow> get flows => _flows;

  // Setter for selectedFlowId
  set selectedFlowId(String? id) {
    _selectedFlowId = id;
    notifyListeners();
  }

  FlowDataSource(this._flows) {
    _flowRows = _getFlowRows();
  }

  void updateFlows(List<models.MitmFlow> flows) {
    _flows = flows;
    _flowRows = _getFlowRows();
    notifyListeners();
  }

  List<DataGridRow> _getFlowRows() {
    return _flows.mapIndexed<DataGridRow>((i, flow) {
      final hasResponse = flow.response != null;
      final methodColor = getMethodColor(flow.request.method);
      final statusColor = getStatusCodeColor(
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
                children: [
                  // Hostname part styled differently
                  TextSpan(
                    text: flow.request.prettyHost ?? flow.request.host,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFFEEEEEE),
                    ),
                  ),
                  // Path part
                  TextSpan(
                    text: flow.request.path,
                    style: const TextStyle(
                      color: Color.fromARGB(221, 230, 230, 230),
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
                ? '${((flow.response!.timestampEnd! - flow.request.timestampStart!) * 1000).round()} ms'
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

  // Override the sorting behavior to handle numeric columns correctly
  @override
  int compare(DataGridRow? a, DataGridRow? b, SortColumnDetails sortColumn) {
    // Get the column name that's being sorted
    final String columnName = sortColumn.name;

    // Handle numeric columns specially
    if (columnName == 'id' ||
        columnName == 'status' ||
        columnName == 'duration' ||
        columnName == 'reqLen' ||
        columnName == 'resLen') {
      // Get the cell values
      final aCellValue = getCellValue(a!, columnName);
      final bCellValue = getCellValue(b!, columnName);
      print('Comparing $columnName: $aCellValue vs $bCellValue');

      // Parse as integers if possible
      late int? aValue;
      late int? bValue;
      if (aCellValue is Text) {
        print(
          "Parsing Text cell values for $columnName, ${int.tryParse(aCellValue.data ?? '')}",
        );
        aValue = int.tryParse(aCellValue.data ?? '');
        bValue = int.tryParse(bCellValue.data ?? '');
      } else {
        aValue = int.tryParse(aCellValue);
        bValue = int.tryParse(bCellValue);
      }

      // If both values are valid integers, compare them numerically
      if (aValue != null && bValue != null) {
        return sortColumn.sortDirection == DataGridSortDirection.ascending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      } else {
        // may have null or parse fails
        return sortColumn.sortDirection == DataGridSortDirection.ascending
            ? aCellValue.toString().compareTo(bCellValue.toString())
            : bCellValue.toString().compareTo(aCellValue.toString());
      }
    } else {
      return super.compare(a, b, sortColumn);
    }
    // For all other columns or if numeric parsing failed, use default behavior
  }

  // Helper method to get a cell's value by column name
  dynamic getCellValue(DataGridRow row, String columnName) {
    final cell = row.getCells().firstWhere(
      (cell) => cell.columnName == columnName,
      orElse: () => DataGridCell<String>(columnName: columnName, value: ''),
    );
    return cell.value;
  }

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

    // Get the actual displayed index of this row after sorting/filtering
    final actualDisplayIndex = effectiveRows.indexOf(row);
    final isEvenRow = actualDisplayIndex % 2 == 0;

    // Check if this row is selected by the user
    final isSelected = flowId != null && flowId == _selectedFlowId;
    const textStyle = TextStyle(fontSize: 15, color: Color(0xFFEEEEEE));

    // Determine the row color based on selection and even/odd alternating pattern
    Color? rowColor;
    if (isSelected) {
      // Selected row gets priority with a distinctive color
      rowColor = const Color(0xffD13639);
    } else {
      // Use alternating colors for even/odd rows
      rowColor = isEvenRow
          ? const Color(0xff1E1E1E) // Even rows - darker (same as background)
          : const Color(0xff26282A); // Odd rows - slightly lighter
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
            style: textStyle,
          ),
        );
      }).toList(),
    );
  }

  /// Get the color for a HTTP method (GET, POST, etc.)
  Color getMethodColor(String method) {
    switch (method) {
      case 'GET':
        return const Color.fromARGB(255, 102, 186, 255);
      case 'POST':
        return const Color(0xFF74E277);
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
