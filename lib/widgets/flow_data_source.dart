import 'package:flutter/material.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/dt_table/dt_table.dart';
import 'package:mitmui/dt_table/dt_source.dart';
import 'package:mitmui/dt_table/dt_models.dart';
import 'package:mitmui/utils/statusCode.dart';
import 'package:mitmui/widgets/small_icon_btn.dart';

import '../models/flow.dart' as models;
import '../utils/extensions.dart';

class FlowDataSource extends DtSource {
  List<DtRow> _flowRows = [];
  final DtController dtController;
  void Function(String flowId, String oldState) resumeIntercept;

  FlowDataSource({
    required List<models.MitmFlow> initialFlows,
    required this.dtController,
    required this.resumeIntercept,
  }) {
    handleFlows(initialFlows);
  }

  void handleFlows(List<models.MitmFlow> flows) {
    buildFlowRows(flows);
    updateData();
  }

  void buildFlowRows(List<models.MitmFlow> flows) {
    _flowRows = flows.mapIndexed((i, flow) {
      final hasResponse = flow.response != null;

      return DtRow(
        id: flow.id,
        m: flow.marked,
        state: flow.interceptedState,
        cells: [
          // 0: ID Cell
          DtCell(value: i, textAlign: TextAlign.right),

          // 1: URL Cell with styled hostname and path
          DtCell(
            value: flow.request != null
                ? (flow.request?.prettyHost ??
                          '${flow.request?.host}:${flow.request?.port}') +
                      (flow.request?.path ?? '')
                : flow.url,
          ),

          // 2: Method Cell
          DtCell(value: flow.request?.method),

          // 3: Status Cell
          DtCell(value: flow.response?.statusCode),

          // 4: Type Cell
          DtCell(
            value: flow.request == null
                ? 'TCP'
                : flow.isWebSocket
                ? 'WebSocket'
                : flow.response?.contentType?.split(';').first,
          ),

          // 5: Time Cell
          DtCell(
            value: flow.createdDateTime.toLocal().toString().substring(11, 19),
          ),

          // 6: Duration Cell - time between request and response in ms
          DtCell(
            value:
                hasResponse &&
                    flow.response?.timestampEnd != null &&
                    flow.request?.timestampStart != null
                ? ((flow.response!.timestampEnd! -
                              flow.request!.timestampStart!) *
                          1000)
                      .round()
                : null,
          ),

          // 7: Request Length Cell
          DtCell(value: flow.request?.contentLength),

          // 8: Response Length Cell
          DtCell(value: flow.response?.contentLength),
        ],
      );
    }).toList();
  }

  @override
  List<DtRow> get rows => _flowRows;
  @override
  DtController get controller => dtController;

  void replaceData(List<models.MitmFlow> flows) {
    handleFlows(flows);
    dtController.clearSelection();
  }

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
      late String text;
      if (cell.value == null) {
        text = '-';
      } else {
        text = switch (cIndex) {
          // duration in ms
          6 => '${cell.value} ms',
          // request and response lengths
          7 || 8 => formatBytes(cell.value as int? ?? 0),
          _ => cell.value.toString(),
        };
      }

      Color cellColor = switch (cIndex) {
        1 =>
          row.m != null && row.m!.isNotEmpty
              ? MarkCircle.decode(row.m!).getColor(isSelected)
              : Colors.white,
        2 => getMethodColor(cell.value ?? ''),
        3 => getStatusCodeColor(cell.value as int?),
        _ => Colors.white,
      };

      if (cIndex == 1 && row.state != 'none') {
        return Row(
          children: [
            SmIconButton(
              icon: Icons.play_arrow,
              color: row.state == "server_block"
                  ? const Color(0xFF9399FF)
                  : const Color(0xFF8BEF8E),
              onPressed: () => resumeIntercept(row.id, row.state),
            ),
            SizedBox(width: 4),
            Text(
              text,
              textAlign: cell.textAlign ?? TextAlign.start,
              style: TextStyle(
                color: cellColor,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      } else {
        return Text(
          text,
          textAlign: cell.textAlign ?? TextAlign.start,
          style: TextStyle(color: cellColor, overflow: TextOverflow.ellipsis),
        );
      }
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
