import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/store/flows_provider.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import 'flow_data_source.dart';
import '../store/selected_ids_notifier.dart';

const _log = Logger("flow_data_grid");

class FlowDataGrid extends ConsumerStatefulWidget {
  final DataGridController controller;

  const FlowDataGrid({super.key, required this.controller});

  @override
  ConsumerState<FlowDataGrid> createState() => _FlowDataGridState();
}

class _FlowDataGridState extends ConsumerState<FlowDataGrid> {
  late final FlowDataSource _flowDataSource = FlowDataSource(
    initialFlows: ref.read(flowsProvider).values.toList(),
    dataGridController: widget.controller,
  );
  @override
  void initState() {
    super.initState();
    ref.listenManual(flowsProvider, (oldFlows, newFlows) {
      int flowsAdded = newFlows.length - (oldFlows?.length ?? 0);
      if (flowsAdded > 0) {}
      _flowDataSource.buildFlowRows(newFlows.values.toList());
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

  // Reset all column widths to their default values
  // void _resetColumnWidths() {
  //   setState(() {
  //     _columnWidths['url'] = 1100;
  //     _columnWidths['method'] = 85;
  //     _columnWidths['status'] = 65;
  //     _columnWidths['type'] = 150;
  //     _columnWidths['time'] = 100;
  //     _columnWidths['duration'] = 90;
  //     _columnWidths['reqLen'] = 90;
  //     _columnWidths['resLen'] = 90;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return _buildSyncfusionDataGrid();
  }

  Widget _buildSyncfusionDataGrid() {
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
    return SfDataGrid(
      source: _flowDataSource,
      controller: widget.controller,
      allowColumnsResizing: true,
      allowSorting: true,
      allowMultiColumnSorting: true,
      allowTriStateSorting: true,
      isScrollbarAlwaysShown: true,
      columnResizeMode: ColumnResizeMode.onResize,
      columnWidthMode: ColumnWidthMode.fill, // Fill available space
      showColumnHeaderIconOnHover: true, // Show resize indicator on hover
      highlightRowOnHover: true, // Better UX for desktop
      navigationMode: GridNavigationMode.row, // Enable keyboard navigation
      rowHeight: 36,
      headerRowHeight: 26,
      showHorizontalScrollbar: false,
      allowColumnsDragging: true,
      frozenColumnsCount: 1,
      selectionMode: SelectionMode.multiple,
      gridLinesVisibility: GridLinesVisibility.none,
      headerGridLinesVisibility: GridLinesVisibility.both,
      onKeyEvent: (keyEvent) {
        _log.info("Key event: ${keyEvent.logicalKey.debugName}");
        if (HardwareKeyboard.instance.isMetaPressed &&
            keyEvent.logicalKey == LogicalKeyboardKey.keyC) {
          _log.info(
            "Copying selected flows: ${widget.controller.selectedRow?.getCells().first.value}",
          );
          return true; // Indicate that we handled this key event
        }
        return false; // Let the grid handle other key events
      },
      onColumnResizeUpdate: (ColumnResizeUpdateDetails details) {
        if (details.width < 44) return false;
        setState(() {
          _columnWidths[details.column.columnName] = details.width;
        });
        return true;
      },
      onSelectionChanged: (addedRows, removedRows) {
        final addedRowIds = addedRows
            .map((row) => row.getCells().first.value)
            .toList();
        final removedRowIds = removedRows
            .map((row) => row.getCells().first.value)
            .toList();
        // Update the notifier
        selectedIdsNotifier.addIds(addedRowIds);
        selectedIdsNotifier.removeIds(removedRowIds);
      },
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
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 11,
                  color: Color(0xFFEEEEEE),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
