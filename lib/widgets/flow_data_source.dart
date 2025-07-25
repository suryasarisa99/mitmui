import 'package:flutter/material.dart';
import 'package:mitmui/dt_table/dt_table.dart';
import 'package:mitmui/dt_table/dt_source.dart';
import 'package:mitmui/dt_table/dt_models.dart';
import 'package:mitmui/utils/statusCode.dart';

import '../models/flow.dart' as models;
import '../utils/extensions.dart';

class FlowDataSource extends DtSource {
  List<DtRow> _flowRows = [];
  final DtController dtController;

  FlowDataSource({
    required List<models.MitmFlow> initialFlows,
    required this.dtController,
  }) {
    handleFlows(initialFlows);
    dtController.addListener(() {
      notifyListeners(); // This will trigger widget rebuild
    });
  }

  void handleFlows(List<models.MitmFlow> flows) {
    buildFlowRows(flows);
    updateData();
  }

  void buildFlowRows(List<models.MitmFlow> flows) {
    _flowRows = flows.mapIndexed((i, flow) {
      final hasResponse = flow.response != null;
      final methodColor = getMethodColor(flow.request.method);
      final statusColor = getStatusCodeColor(
        hasResponse ? flow.response!.statusCode : null,
      );

      return DtRow(
        id: i.toString(),
        cells: [
          // ID Cell
          DtCell(
            // columnName: 'id',
            value: i,
            textAlign: TextAlign.right,
          ),

          // URL Cell with styled hostname and path
          DtCell(
            // columnName: 'url',
            value: flow.request.prettyHost ?? '' + flow.request.path,
          ),

          // Method Cell
          DtCell(
            // columnName: 'method',
            // fontWeight: FontWeight.w500,
            value: flow.request.method,
            color: methodColor,
          ),

          // Status Cell
          DtCell(
            // columnName: 'status',
            // fontWeight: FontWeight.bold,
            color: statusColor,
            value: flow.isWebSocket
                ? 'WS'
                : hasResponse
                ? flow.response!.statusCode.toString()
                : '-',
          ),

          // Type Cell
          DtCell<String>(
            // columnName: 'type',
            value: flow.isWebSocket
                ? 'WebSocket'
                : flow.response?.contentType?.split(';').first ?? '-',
          ),

          // Time Cell
          DtCell<String>(
            // columnName: 'time',
            value: flow.createdDateTime.toLocal().toString().substring(11, 19),
          ),

          // Duration Cell - time between request and response in ms
          DtCell<String>(
            // columnName: 'duration',
            value:
                hasResponse &&
                    flow.response?.timestampEnd != null &&
                    flow.request.timestampStart != null
                ? '${((flow.response!.timestampEnd! - flow.request.timestampStart!) * 1000).round()} ms'
                : '-',
          ),

          // Request Length Cell
          DtCell<String>(
            // columnName: 'reqLen',
            value: flow.request.contentLength != null
                ? formatBytes(flow.request.contentLength!)
                : '-',
          ),

          // Response Length Cell
          DtCell<String>(
            // columnName: 'resLen',
            value: hasResponse && flow.response?.contentLength != null
                ? formatBytes(flow.response!.contentLength!)
                : '-',
          ),
        ],
      );
    }).toList();
  }

  @override
  List<DtRow> get rows => _flowRows;

  @override
  DtRowAdapter buildRow(DtRow row, int index, bool isSelected, bool hasFocus) {
    // int? rowId = int.tryParse(row.getCells().first.value);
    late Color rowColor;
    if (isSelected) {
      rowColor = const Color(0xffD13639); // Selected row color
    } else {
      rowColor = index.isEven
          ? const Color(0xff1E1E1E) // Even rows - darker (same as background)
          : const Color(0xff26282A);
    }
    final cells = row.cells.mapIndexed((cIndex, cell) {
      return Text(
        cell.value.toString(),
        textAlign: cell.textAlign ?? TextAlign.start,
        style: TextStyle(color: cell.color, overflow: TextOverflow.ellipsis),
      );
    }).toList();
    return DtRowAdapter(color: rowColor, cells: cells);
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
