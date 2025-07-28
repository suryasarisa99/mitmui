import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/dt_table/dt_table.dart';
import 'package:mitmui/dt_table/dt_models.dart';
import 'package:mitmui/widgets/filter.dart';
import 'package:mitmui/screens/filter_manager.dart';
import 'package:mitmui/services/websocket_service.dart';
import 'package:mitmui/store/filtered_flows_provider.dart';
import 'package:mitmui/store/flows_provider.dart';
import 'package:mitmui/utils/flowUtils.dart';
import 'package:mitmui/utils/logger.dart';

import 'flow_data_source.dart';

const _log = Logger("flow_data_grid");

class FlowDataGrid extends ConsumerStatefulWidget {
  final DtController controller;

  const FlowDataGrid({super.key, required this.controller});

  @override
  ConsumerState<FlowDataGrid> createState() => _FlowDataGridState();
}

class _FlowDataGridState extends ConsumerState<FlowDataGrid> {
  late final FlowDataSource _flowDataSource = FlowDataSource(
    initialFlows: ref.read(flowsProvider).values.toList(),
    dtController: widget.controller,
  );
  late final _filterManager = FilterManager();
  String mitmFilter = '';
  @override
  void initState() {
    super.initState();
    ref.listenManual(flowsProvider, (oldFlows, newFlows) {
      int flowsAdded = newFlows.length - (oldFlows?.length ?? 0);
      if (mitmFilter.isEmpty) {
        _flowDataSource.handleFlows(newFlows.values.toList());
      }
      if (flowsAdded > 0) {}
    });

    _filterManager.addListener(() {
      // trigger set filter in websocket service
      final webSocketService = ref.read(websocketServiceProvider);
      mitmFilter = _filterManager.mitmproxyString;
      if (mitmFilter.isNotEmpty) {
        webSocketService.updateFilter(mitmFilter);
      } else {
        // reset filter and show all flows
        webSocketService.updateFilter(mitmFilter);
        _flowDataSource.handleFlows(ref.read(flowsProvider).values.toList());
      }
    });
    ref.listenManual(filteredFlowsProvider, (_, newIds) {
      final filterdFlows = ref
          .read(flowsProvider.notifier)
          .getFlowsByIds(newIds);
      _flowDataSource.handleFlows(filterdFlows);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Store column widths
  final Map<String, double> _columnWidths = {
    'id': 44,
    'url': 1180,
    'method': 80,
    'status': 60,
    'type': 150,
    'time': 100,
    'duration': 100,
    'reqLen': 100,
    'resLen': 100,
  };

  @override
  Widget build(BuildContext context) {
    final headerCells = [
      (title: "ID", key: 'id'),
      (title: "URL", key: 'url'),
      (title: "Method", key: 'method'),
      (title: "Status", key: 'status'),
      (title: "Type", key: 'type'),
      (title: "Time", key: 'time'),
      (title: "Duration", key: 'duration'),
      (title: "Req", key: 'reqLen'),
      (title: "Res", key: 'resLen'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterGroupWidget(
          group: _filterManager.rootFilter,
          manager: _filterManager,
          isRoot: true,
        ),
        Expanded(
          child: DtTable(
            source: _flowDataSource,
            controller: widget.controller,
            // tableWidth: MediaQuery.sizeOf(context).width,
            tableWidth: double.infinity,
            headerHeight: 30,
            rowHeight: 32,
            onKeyEvent: (keyEvent) {
              final hk = HardwareKeyboard.instance;
              final isCtrl = hk.isControlPressed;
              final isShift = hk.isShiftPressed;
              final isMeta = hk.isMetaPressed;
              final isAlt = hk.isAltPressed;
              final k = keyEvent.logicalKey;
              final flowId = widget.controller.focusedRowId;
              if (flowId == null) return false;
              final flow = ref.read(flowsProvider)[flowId];
              if (flow == null) return false;
              _log.info("Key event: ${keyEvent.logicalKey.debugName}");
              if (isMeta && isAlt && k == LogicalKeyboardKey.keyC) {
                MitmproxyClient.getExportReq(flow.id, RequestExport.curl).then((
                  result,
                ) {
                  Clipboard.setData(ClipboardData(text: result));
                });
                return true; // Indicate that we handled this key event
              } else if (isMeta && k == LogicalKeyboardKey.keyC) {
                Clipboard.setData(ClipboardData(text: flow.url));
                return true; // Indicate that we handled this key event
              } else if (k == LogicalKeyboardKey.delete) {
                final selectedIds = widget.controller.selectedRowIds;
                ref.read(flowsProvider.notifier).removeFlows(selectedIds);
                for (final id in selectedIds) {
                  MitmproxyClient.deleteFlow(id);
                }
                return true; // Indicate that we handled this key event
              }
              return false; // Let the grid handle other key events
            },
            headerColumns: [
              for (final header in headerCells)
                DtColumn(
                  key: header.key,
                  title: header.title,
                  fontSize: 12,
                  initialWidth: _columnWidths[header.key]!,
                  isNumeric: header.key == 'id' || header.key == 'status',
                  isExpand: header.key == 'url',
                  // maxWidth: 1200,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
