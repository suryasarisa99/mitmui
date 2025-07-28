import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mitmui/dt_table/dt_models.dart';
import 'package:mitmui/dt_table/dt_source.dart';
import 'package:super_context_menu/super_context_menu.dart';

class DtController extends ChangeNotifier {
  Set<String> _selectedRowIds = {};
  String? _focusedRowId;
  String? _selectionAnchorId;
  int? _sortColumnIndex;
  SortType _sortType = SortType.none;

  // Callback for specific change types
  void Function(DtControllerChange change)? _onSpecificChange;

  Set<String> get selectedRowIds => Set.from(_selectedRowIds);
  String? get focusedRowId => _focusedRowId;
  String? get selectionAnchorId => _selectionAnchorId;
  int? get sortColumnIndex => _sortColumnIndex;
  SortType get sortType => _sortType;

  void addSpecificListener(void Function(DtControllerChange change) listener) {
    _onSpecificChange = listener;
  }

  void removeSpecificListener() {
    _onSpecificChange = null;
  }

  void _notifySpecificChange(
    ChangeType type,
    dynamic oldValue,
    dynamic newValue,
  ) {
    if (type == ChangeType.selectedRows) {
      if (oldValue.toString() != newValue.toString()) {
        _onSpecificChange?.call(
          DtControllerChange(
            type: type,
            oldValue: oldValue,
            newValue: newValue,
          ),
        );
        notifyListeners();
      }
    } else if (oldValue != newValue) {
      _onSpecificChange?.call(
        DtControllerChange(type: type, oldValue: oldValue, newValue: newValue),
      );
      notifyListeners();
    }
  }

  void setSelectedRows(Set<String> rowIds) {
    final oldValue = Set.from(_selectedRowIds);
    _selectedRowIds = Set.from(rowIds);
    _notifySpecificChange(ChangeType.selectedRows, oldValue, _selectedRowIds);
  }

  void setFocusedRow(String? rowId) {
    final oldValue = _focusedRowId;
    _focusedRowId = rowId;
    _notifySpecificChange(ChangeType.focusedRow, oldValue, _focusedRowId);
  }

  void setSelectionAnchor(String? rowId) {
    final oldValue = _selectionAnchorId;
    _selectionAnchorId = rowId;
    _notifySpecificChange(
      ChangeType.selectionAnchor,
      oldValue,
      _selectionAnchorId,
    );
  }

  void selectAll(List<String> allRowIds) {
    final oldValue = Set.from(_selectedRowIds);
    _selectedRowIds = Set.from(allRowIds);
    _notifySpecificChange(ChangeType.selectedRows, oldValue, _selectedRowIds);
  }

  void clearSelection() {
    final oldSelectedRows = Set.from(_selectedRowIds);
    final oldFocusedRow = _focusedRowId;
    final oldSelectionAnchor = _selectionAnchorId;

    _selectedRowIds.clear();
    _focusedRowId = null;
    _selectionAnchorId = null;

    _notifySpecificChange(
      ChangeType.selectedRows,
      oldSelectedRows,
      _selectedRowIds,
    );
    _notifySpecificChange(ChangeType.focusedRow, oldFocusedRow, _focusedRowId);
    _notifySpecificChange(
      ChangeType.selectionAnchor,
      oldSelectionAnchor,
      _selectionAnchorId,
    );
  }

  // Internal methods for the widget to use
  void updateSelectedRows(Set<String> rowIds) {
    final oldValue = Set.from(_selectedRowIds);
    _selectedRowIds = Set.from(rowIds);
    _notifySpecificChange(ChangeType.selectedRows, oldValue, _selectedRowIds);
  }

  void updateFocusedRow(String? rowId) {
    final oldValue = _focusedRowId;
    _focusedRowId = rowId;
    _notifySpecificChange(ChangeType.focusedRow, oldValue, _focusedRowId);
  }

  void updateSelectionAnchor(String? rowId) {
    final oldValue = _selectionAnchorId;
    _selectionAnchorId = rowId;
    _notifySpecificChange(
      ChangeType.selectionAnchor,
      oldValue,
      _selectionAnchorId,
    );
  }

  void updateSort(int? columnIndex, SortType sortType) {
    final oldColumnIndex = _sortColumnIndex;
    final oldSortType = _sortType;

    _sortColumnIndex = columnIndex;
    _sortType = sortType;

    _notifySpecificChange(
      ChangeType.sortColumn,
      oldColumnIndex,
      _sortColumnIndex,
    );
    _notifySpecificChange(ChangeType.sortType, oldSortType, _sortType);
  }
}

class DtTable extends StatefulWidget {
  const DtTable({
    required this.source,
    required this.headerColumns,
    this.controller,
    this.rowHeight = 48.0,
    this.headerHeight = 56.0,
    this.frozenColumnsCount = 0,
    this.resizeIndicatorColor = Colors.blueAccent,
    super.key,
    this.tableWidth,
    this.onKeyEvent,
    required this.menuProvider,
  });

  final DtSource source;
  final DtController? controller;
  final double rowHeight;
  final List<DtColumn> headerColumns;
  final double headerHeight;
  final Color resizeIndicatorColor;
  final int frozenColumnsCount;
  final double? tableWidth;
  final bool Function(KeyEvent event)? onKeyEvent;
  final FutureOr<Menu?> Function(MenuRequest) menuProvider;

  @override
  State<DtTable> createState() => _DtTableState();
}

class _DtTableState extends State<DtTable> {
  late List<double> _columnWidths;
  late DtController _controller;
  late double _actualTableWidth;

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isResizing = false;
  double _resizeIndicatorPosition = 0;

  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? DtController();
    widget.source.addListener(_onDataSourceChanged);
    _controller.addListener(_onControllerChanged);
    // widget.source.sort('id', 0, false, _controller); // Initial sort
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setInitialColumnWidths();
  }

  @override
  void didUpdateWidget(DtTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.source != oldWidget.source) {
      oldWidget.source.removeListener(_onDataSourceChanged);
      widget.source.addListener(_onDataSourceChanged);
    }
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _controller.removeListener(_onControllerChanged);
      }
      _controller = widget.controller ?? DtController();
      _controller.addListener(_onControllerChanged);
    }
    if (widget.tableWidth != oldWidget.tableWidth ||
        widget.headerColumns != oldWidget.headerColumns) {
      _setInitialColumnWidths();
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    widget.source.removeListener(_onDataSourceChanged);
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setInitialColumnWidths() {
    final totalInitialWidth = widget.headerColumns
        .map((column) => column.initialWidth)
        .reduce((a, b) => a + b);

    _actualTableWidth = widget.tableWidth ?? totalInitialWidth;
    if (widget.tableWidth == double.infinity) {
      _actualTableWidth = MediaQuery.sizeOf(context).width;
    }

    _columnWidths = widget.headerColumns.map((c) => c.initialWidth).toList();

    if (totalInitialWidth < _actualTableWidth) {
      final extraSpace = _actualTableWidth - totalInitialWidth;
      final expandColumnIndex = widget.headerColumns.indexWhere(
        (c) => c.isExpand,
      );
      if (expandColumnIndex != -1) {
        _columnWidths[expandColumnIndex] += extraSpace;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _redistributeWidth() {
    final currentTotalWidth = _columnWidths.reduce((a, b) => a + b);
    if (currentTotalWidth < _actualTableWidth) {
      final extraSpace = _actualTableWidth - currentTotalWidth;
      // Find the last column that can be expanded or just use the last column
      int targetIndex = widget.headerColumns.length - 1;
      for (int i = widget.headerColumns.length - 1; i >= 0; i--) {
        if (widget.headerColumns[i].isExpand) {
          targetIndex = i;
          break;
        }
      }
      _columnWidths[targetIndex] += extraSpace;
    }
  }

  void _onDataSourceChanged() {
    setState(() {
      final allIds = widget.source.effectiveRows.map((e) => e.id).toSet();
      final selectedIds = Set<String>.from(_controller._selectedRowIds);
      selectedIds.removeWhere((id) => !allIds.contains(id));
      _controller.updateSelectedRows(selectedIds);

      if (_controller._focusedRowId != null &&
          !allIds.contains(_controller._focusedRowId)) {
        _controller.updateFocusedRow(null);
      }
      if (_controller._selectionAnchorId != null &&
          !allIds.contains(_controller._selectionAnchorId)) {
        _controller.updateSelectionAnchor(null);
      }
    });
  }

  void _onControllerChanged() {
    setState(() {});
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (widget.onKeyEvent != null && widget.onKeyEvent!(event)) {
      return; // Custom event handling,it returns true if it handles the event
    }

    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final isCtrlPressed =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // Handle Cmd+A (Select All)
    if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
      final allIds = widget.source.effectiveRows.map((r) => r.id).toList();
      _controller.selectAll(allIds);
      return;
    }

    // Handle Escape (Clear Selection)
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _controller.clearSelection();
      return;
    }

    // Handle horizontal scrolling
    if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_horizontalScrollController.hasClients) {
        _horizontalScrollController.animateTo(
          max(0, _horizontalScrollController.offset - 100),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      return;
    }

    if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_horizontalScrollController.hasClients) {
        _horizontalScrollController.animateTo(
          min(
            _horizontalScrollController.position.maxScrollExtent,
            _horizontalScrollController.offset + 100,
          ),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      return;
    }

    int currentIndex = -1;
    if (_controller._focusedRowId != null) {
      currentIndex = widget.source.effectiveRows.indexWhere(
        (r) => r.id == _controller._focusedRowId,
      );
    }

    int nextIndex = currentIndex;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (isCtrlPressed) {
        // Jump to last item
        nextIndex = widget.source.rowCount - 1;
      } else if (currentIndex < widget.source.rowCount - 1) {
        nextIndex = currentIndex + 1;
      } else if (currentIndex == -1 && widget.source.rowCount > 0) {
        nextIndex = 0;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (isCtrlPressed) {
        // Jump to first item
        nextIndex = 0;
      } else if (currentIndex > 0) {
        nextIndex = currentIndex - 1;
      } else if (currentIndex == -1 && widget.source.rowCount > 0) {
        nextIndex = 0;
      }
    }

    if (nextIndex != currentIndex && nextIndex >= 0) {
      final nextRow = widget.source.effectiveRows[nextIndex];
      _controller.updateFocusedRow(nextRow.id);

      if (isShiftPressed) {
        final anchorIndex = _controller._selectionAnchorId != null
            ? widget.source.effectiveRows.indexWhere(
                (r) => r.id == _controller._selectionAnchorId,
              )
            : -1;
        if (anchorIndex != -1) {
          final start = min(anchorIndex, nextIndex);
          final end = max(anchorIndex, nextIndex);
          final rangeIds = widget.source.effectiveRows
              .sublist(start, end + 1)
              .map((r) => r.id)
              .toSet();
          _controller.updateSelectedRows(rangeIds);
        }
      } else {
        _controller.updateSelectedRows({nextRow.id});
        _controller.updateSelectionAnchor(nextRow.id);
      }

      _scrollToIndex(nextIndex);
    }
  }

  void _handleKeyUp(KeyEvent event) {
    if (event is KeyUpEvent) {
      _longPressTimer?.cancel();
    }
  }

  void _scrollToIndex(int index) {
    if (!_verticalScrollController.hasClients) return;
    final viewportHeight = _verticalScrollController.position.viewportDimension;
    final currentVisibleStartOffset = _verticalScrollController.offset;
    final currentVisibleEndOffset = currentVisibleStartOffset + viewportHeight;
    final targetItemTopOffset = index * widget.rowHeight;
    final targetItemBottomOffset = targetItemTopOffset + widget.rowHeight;

    if (targetItemTopOffset < currentVisibleStartOffset) {
      _verticalScrollController.jumpTo(targetItemTopOffset);
    } else if (targetItemBottomOffset > currentVisibleEndOffset) {
      _verticalScrollController.jumpTo(targetItemBottomOffset - viewportHeight);
    }
  }

  void _handleRowTap(DtRow row) {
    FocusScope.of(context).requestFocus(_focusNode);
    final isCtrlPressed =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    _controller.updateFocusedRow(row.id);

    if (isShiftPressed && _controller._selectionAnchorId != null) {
      final anchorIndex = widget.source.effectiveRows.indexWhere(
        (r) => r.id == _controller._selectionAnchorId,
      );
      final currentIndex = widget.source.effectiveRows.indexWhere(
        (r) => r.id == row.id,
      );
      if (anchorIndex != -1 && currentIndex != -1) {
        final start = min(anchorIndex, currentIndex);
        final end = max(anchorIndex, currentIndex);
        final rangeIds = widget.source.effectiveRows
            .sublist(start, end + 1)
            .map((r) => r.id)
            .toSet();
        if (isCtrlPressed) {
          final selectedIds = Set<String>.from(_controller._selectedRowIds);
          selectedIds.addAll(rangeIds);
          _controller.updateSelectedRows(selectedIds);
        } else {
          _controller.updateSelectedRows(rangeIds);
        }
      }
    } else if (isCtrlPressed) {
      final selectedIds = Set<String>.from(_controller._selectedRowIds);
      if (selectedIds.contains(row.id)) {
        selectedIds.remove(row.id);
      } else {
        selectedIds.add(row.id);
      }
      _controller.updateSelectedRows(selectedIds);
      _controller.updateSelectionAnchor(row.id);
    } else {
      _controller.updateSelectedRows({row.id});
      _controller.updateSelectionAnchor(row.id);
    }
  }

  void _onColumnResizeStart(int columnIndex, DragStartDetails details) {
    double position = 0;
    for (int i = 0; i < columnIndex + 1; i++) {
      position += _columnWidths[i];
    }
    setState(() {
      _isResizing = true;
      _resizeIndicatorPosition = position - _horizontalScrollController.offset;
    });
  }

  // void _onColumnResizeUpdate(int columnIndex, DragUpdateDetails details) {
  // setState(() {
  //   final column = widget.headerColumns[columnIndex];
  //   final newWidth = _columnWidths[columnIndex] + details.delta.dx;

  //   // Apply min/max width constraints
  //   double constrainedWidth = newWidth;
  //   if (column.minWidth != null && constrainedWidth < column.minWidth!) {
  //     constrainedWidth = column.minWidth!;
  //   }
  //   if (column.maxWidth != null && constrainedWidth > column.maxWidth!) {
  //     constrainedWidth = column.maxWidth!;
  //   }

  //   _columnWidths[columnIndex] = constrainedWidth;
  //   _resizeIndicatorPosition += details.delta.dx;
  // });
  // }
  void _onColumnResizeUpdate(int columnIndex, DragUpdateDetails details) {
    setState(() {
      final column = widget.headerColumns[columnIndex];
      final newWidth = _columnWidths[columnIndex] + details.delta.dx;

      // Apply min/max width constraints
      double constrainedWidth = newWidth;
      if (constrainedWidth < column.minWidth) {
        constrainedWidth = column.minWidth;
      }
      if (column.maxWidth != null && constrainedWidth > column.maxWidth!) {
        constrainedWidth = column.maxWidth!;
      }

      final oldWidth = _columnWidths[columnIndex];
      _columnWidths[columnIndex] = constrainedWidth;

      // Check if this is an expanded column and we're trying to decrease it
      // when total width <= table width
      final currentTotalWidth = _columnWidths.reduce((a, b) => a + b);
      if (column.isExpand &&
          constrainedWidth < oldWidth &&
          currentTotalWidth <= _actualTableWidth) {
        // Give the extra space to the last column instead
        final lastColumnIndex = widget.headerColumns.length - 1;
        final extraSpace = oldWidth - constrainedWidth;
        _columnWidths[lastColumnIndex] += extraSpace;
      }

      _resizeIndicatorPosition += details.delta.dx;
    });
  }

  void _onColumnResizeEnd(int columnIndex, DragEndDetails details) {
    setState(() {
      _isResizing = false;
    });

    // Redistribute width if needed
    _redistributeWidth();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        _handleKeyEvent(event);
        _handleKeyUp(event);
      },
      child: Stack(
        children: [
          Row(
            children: [
              // Frozen columns
              if (widget.frozenColumnsCount > 0) _buildFrozenColumns(),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _getScrollableWidth(),
                    child: Column(
                      children: [
                        _buildHeader(startIndex: widget.frozenColumnsCount),
                        Expanded(
                          child: _buildRows(
                            startIndex: widget.frozenColumnsCount,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isResizing)
            Positioned(
              left: _resizeIndicatorPosition,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: widget.resizeIndicatorColor),
            ),
        ],
      ),
    );
  }

  Widget _buildFrozenColumns() {
    if (widget.frozenColumnsCount <= 0) return const SizedBox.shrink();

    final frozenWidth = _columnWidths
        .take(widget.frozenColumnsCount)
        .reduce((a, b) => a + b);

    return SizedBox(
      width: frozenWidth,
      child: Column(
        children: [
          _buildHeader(endIndex: widget.frozenColumnsCount),
          Expanded(child: _buildRows(endIndex: widget.frozenColumnsCount)),
        ],
      ),
    );
  }

  double _getScrollableWidth() {
    final scrollableColumnsWidth = _columnWidths
        .skip(widget.frozenColumnsCount)
        .fold(0.0, (sum, width) => sum + width);

    if (widget.tableWidth != null) {
      final frozenWidth = widget.frozenColumnsCount > 0
          ? _columnWidths
                .take(widget.frozenColumnsCount)
                .reduce((a, b) => a + b)
          : 0.0;
      return max(scrollableColumnsWidth, _actualTableWidth - frozenWidth);
    }

    return scrollableColumnsWidth;
  }

  Widget _buildHeader({int startIndex = 0, int? endIndex}) {
    final end = endIndex ?? widget.headerColumns.length;
    final columnsToShow = widget.headerColumns.sublist(startIndex, end);

    return Material(
      color: Colors.grey[850],
      child: Row(
        children: List.generate(columnsToShow.length, (index) {
          final actualIndex = startIndex + index;
          final column = columnsToShow[index];

          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[700]!, width: 1),
                right: actualIndex < widget.headerColumns.length - 1
                    ? BorderSide(color: Colors.grey[700]!, width: 1)
                    : BorderSide.none,
              ),
            ),
            width: _columnWidths[actualIndex],
            height: widget.headerHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        widget.source.sort(actualIndex, column.isNumeric),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              column.title,
                              style: TextStyle(
                                fontSize: column.fontSize,
                                overflow: TextOverflow.ellipsis,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (widget.source.sortColumnIndex == index)
                            Icon(
                              widget.source.sortType == SortType.ascending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    onHorizontalDragStart: (details) =>
                        _onColumnResizeStart(actualIndex, details),
                    onHorizontalDragUpdate: (details) =>
                        _onColumnResizeUpdate(actualIndex, details),
                    onHorizontalDragEnd: (details) =>
                        _onColumnResizeEnd(actualIndex, details),
                    child: Container(
                      width: 8,
                      height: double.infinity,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRows({int startIndex = 0, int? endIndex}) {
    return ListView.builder(
      controller: startIndex == 0 ? _verticalScrollController : null,
      itemCount: widget.source.rowCount,
      itemExtent: widget.rowHeight,
      itemBuilder: (context, index) {
        final row = widget.source.effectiveRows[index];
        final isSelected = _controller._selectedRowIds.contains(row.id);
        final hasFocus = _controller._focusedRowId == row.id;

        final dataRowAdapter = widget.source.buildRow(
          row,
          index,
          isSelected,
          hasFocus,
        );
        final end = endIndex ?? widget.headerColumns.length;

        return Container(
          decoration: BoxDecoration(color: dataRowAdapter.color),
          child: ContextMenuWidget(
            menuProvider: (e) {
              if (!(widget.controller?._selectedRowIds.contains(row.id) ??
                  false)) {
                // if we right click on unselected row, unselect all rows and select this row
                _controller.updateSelectedRows({row.id});
                _controller.updateFocusedRow(row.id);
                _controller.updateSelectionAnchor(row.id);
              }
              return widget.menuProvider(e);
            },
            child: InkWell(
              onTap: () => _handleRowTap(row),
              child: Row(
                children: dataRowAdapter.cells
                    .sublist(startIndex, end)
                    .mapIndexed((cIndex, cell) {
                      final actualIndex = startIndex + cIndex;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        width: _columnWidths[actualIndex],
                        child: cell,
                      );
                    })
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
