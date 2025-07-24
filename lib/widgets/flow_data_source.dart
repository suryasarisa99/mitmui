import 'package:flutter/material.dart';
import 'package:mitmui/utils/statusCode.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../models/flow.dart' as models;
import '../utils/extensions.dart';

class FlowDataSource extends DataGridSource {
  List<models.MitmFlow> initialFlows = [];
  List<DataGridRow> _flowRows = [];
  final DataGridController dataGridController;

  FlowDataSource({
    required this.initialFlows,
    required this.dataGridController,
  }) {
    buildFlowRows(initialFlows);
  }

  void updateFlows(List<models.MitmFlow> flows) {
    initialFlows = flows;
    buildFlowRows([]);
    // notifyListeners();
    // notifyDataSourceListeners();
  }

  @override
  Future<void> handleLoadMoreRows() async {
    // Implement your logic to load more rows here
  }

  void buildFlowRows(List<models.MitmFlow> flows) {
    print("buildFlowRows called with ${flows.length} flows");
    _flowRows = flows.mapIndexed<DataGridRow>((i, flow) {
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
    // notifyListeners();
    // notifyDataSourceListeners();
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

      // Parse as integers if possible
      late int? aValue;
      late int? bValue;
      if (aCellValue is Text) {
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
      } else if (aValue == null && bValue == null) {
        return 0;
      } else if (aValue == null) {
        return sortColumn.sortDirection == DataGridSortDirection.ascending
            ? -1
            : 1;
      } else {
        // bValue is null, aValue is not null
        return sortColumn.sortDirection == DataGridSortDirection.ascending
            ? 1
            : -1;
      }
    } else {
      return super.compare(a, b, sortColumn);
    }
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
    // int? rowId = int.tryParse(row.getCells().first.value);
    final actualDisplayIndex = effectiveRows.indexOf(row);
    final isEvenRow = actualDisplayIndex % 2 == 0;
    final Color rowColor = isEvenRow
        ? const Color(0xff1E1E1E) // Even rows - darker (same as background)
        : const Color(0xff26282A); // Odd rows - slightly lighter
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
            style: TextStyle(fontSize: 15, color: Color(0xFFEEEEEE)),
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
