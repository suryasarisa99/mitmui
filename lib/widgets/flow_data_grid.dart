import 'package:flutter/material.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../models/flow.dart' as models;
import 'flow_data_source.dart';

const _log = Logger("flow_data_grid");

class FlowDataGrid extends StatefulWidget {
  final FlowDataSource dataSource;
  final Function(models.MitmFlow) onFlowSelected;
  final DataGridController controller;

  const FlowDataGrid({
    super.key,
    required this.dataSource,
    required this.onFlowSelected,
    required this.controller,
  });

  @override
  State<FlowDataGrid> createState() => _FlowDataGridState();
}

class _FlowDataGridState extends State<FlowDataGrid> {
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
                child: const Row(
                  children: [
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
          source: widget.dataSource,
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
          navigationMode: GridNavigationMode.cell, // Enable keyboard navigation
          rowHeight: 36,
          headerRowHeight: 26,
          showHorizontalScrollbar: false,
          allowColumnsDragging: true,
          frozenColumnsCount: 1,
          selectionMode: SelectionMode.multiple,
          gridLinesVisibility: GridLinesVisibility.none,
          headerGridLinesVisibility: GridLinesVisibility.both,

          // Track keyboard navigation and select row
          onCurrentCellActivated:
              (
                RowColumnIndex newRowColumnIndex,
                RowColumnIndex oldRowColumnIndex,
              ) {
                // no need of rowIndex-1, it does not calls for header row
                if (newRowColumnIndex.rowIndex < 0) return;
                try {
                  // Get the actual row based on current display order (after sorting)
                  final actualRowIndex = newRowColumnIndex.rowIndex;
                  if (actualRowIndex < 0 ||
                      actualRowIndex >=
                          widget.dataSource.effectiveRows.length) {
                    return;
                  }

                  // Get the effective row at the current position
                  final actualRow =
                      widget.dataSource.effectiveRows[actualRowIndex];

                  // Find the ID cell to identify which flow this represents
                  final idCell = actualRow.getCells().firstWhere(
                    (cell) => cell.columnName == 'id',
                    orElse: () =>
                        DataGridCell<String>(columnName: 'id', value: ''),
                  );

                  // Parse the ID to get the original flow index
                  final originalIndex = int.tryParse(idCell.value.toString());
                  if (originalIndex != null &&
                      originalIndex >= 0 &&
                      originalIndex < widget.dataSource.flows.length) {
                    final selectedFlow = widget.dataSource.flows[originalIndex];
                    widget.onFlowSelected(selectedFlow);
                  }
                } catch (e) {
                  _log.error('Error selecting flow: $e');
                }
              },
          onColumnResizeUpdate: (ColumnResizeUpdateDetails details) {
            if (details.width < 44) {
              return false;
            }
            setState(() {
              _columnWidths[details.column.columnName] = details.width;
            });
            return true;
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
        ),
      ),
    );
  }
}
