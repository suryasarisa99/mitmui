import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  String _message = 'Press and hold a key...';
  final focusScoeNode = FocusScopeNode();
  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    focusScoeNode.requestFocus();
    // _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    // _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  // void _onFocusChange() {
  //   if (!_focusNode.hasFocus) {
  //     setState(() {
  //       _message = 'Click to focus';
  //       _pressedKeys.clear(); // Clear pressed keys if focus is lost
  //     });
  //   }
  // }

  void _handleKeyEvent(KeyEvent event) {
    _log.info(
      'Key event: ${event.runtimeType} - ${event.logicalKey.debugName}',
    );
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
    // setState(() {
    //   if (_pressedKeys.isEmpty) {
    //     _message = 'No key held';
    //   } else {
    //     _message =
    //         'Keys held: ${_pressedKeys.map((key) => key.debugName ?? key.keyLabel).join(', ')}';
    //   }
    // });
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
    debugPrint("Building Syncfusion DataGrid, with: ${_focusNode.hasFocus}");
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
    return FocusScope(
      node: focusScoeNode,
      autofocus: true,
      debugLabel: 'focusScope',
      onFocusChange: (f) {
        _log.debug('focusScopeNode focus changed: $f');
        if (f) {
          _focusNode.requestFocus();
        }
      },
      child: CallbackShortcuts(
        bindings: {
          LogicalKeySet(
            // LogicalKeyboardKey.meta,
            LogicalKeyboardKey.keyA,
          ): () {
            _log.success("A is Pressed");
          },
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onFocusChange: (f) {
            _log.debug('Focus changed: $f');
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
            navigationMode:
                GridNavigationMode.cell, // Enable keyboard navigation
            rowHeight: 36,
            headerRowHeight: 26,
            showHorizontalScrollbar: false,
            allowColumnsDragging: true,
            frozenColumnsCount: 1,
            selectionMode: SelectionMode.multiple,
            gridLinesVisibility: GridLinesVisibility.none,
            headerGridLinesVisibility: GridLinesVisibility.both,
            onSelectionChanging: (oldDataGrid, newDataGrid) {
              _log.info("keys: ${_pressedKeys.join(', ')}");
              if (_pressedKeys.firstWhereOrNull(
                    (key) =>
                        key == LogicalKeyboardKey.meta ||
                        key == LogicalKeyboardKey.metaLeft ||
                        key == LogicalKeyboardKey.metaRight,
                  ) !=
                  null) {
                _log.info("Meta key pressed, allowing selection change");
                return true;
              }
              return false;
            },
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
                      final selectedFlow =
                          widget.dataSource.flows[originalIndex];
                      widget.onFlowSelected(selectedFlow);
                    }
                  } catch (e) {
                    _log.error('Error selecting flow: $e');
                  }
                },
            onColumnResizeUpdate: (ColumnResizeUpdateDetails details) {
              if (details.width < 44) return false;
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
                    padding: EdgeInsets.only(
                      left: header.key == 'url' ? 8.0 : 0,
                    ),
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
      ),
    );
  }
}
