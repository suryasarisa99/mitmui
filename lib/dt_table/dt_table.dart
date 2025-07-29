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
  double _actualTableWidth = 0;

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isResizing = false;
  double _resizeIndicatorPosition = 0;

  // ## ADDED: For long press navigation ##
  Timer? _scrollTimer;
  LogicalKeyboardKey? _heldKey;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? DtController();
    widget.source.addListener(_onDataSourceChanged);
    _controller.addListener(_onControllerChanged);
    _columnWidths = widget.headerColumns.map((c) => c.initialWidth).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialColumnWidths();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // update table width,if window size changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.sizeOf(context).width;
      if (widget.tableWidth == double.infinity) {
        _actualTableWidth = size;
      }
      _redistributeWidth();
      setState(() {});
    });
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
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
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
      int targetIndex = widget.headerColumns.indexWhere((c) => c.isExpand);
      if (targetIndex == -1) {
        targetIndex = widget.headerColumns.length - 1; // Use last column
      } else {
        _columnWidths[targetIndex] += extraSpace;
      }
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

  // ## ADDED: Helper function for navigation ##
  void _navigateByOneStep({required bool isDown}) {
    if (widget.source.rowCount == 0) return;

    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    int currentIndex = -1;
    if (_controller.focusedRowId != null) {
      currentIndex = widget.source.effectiveRows.indexWhere(
        (r) => r.id == _controller.focusedRowId,
      );
    }

    int nextIndex = currentIndex;
    if (isDown) {
      if (currentIndex < widget.source.rowCount - 1) {
        nextIndex = currentIndex + 1;
      } else if (currentIndex == -1) {
        nextIndex = 0;
      }
    } else {
      // isUp
      if (currentIndex > 0) {
        nextIndex = currentIndex - 1;
      } else if (currentIndex == -1) {
        nextIndex = 0;
      }
    }

    if (nextIndex != currentIndex && nextIndex >= 0) {
      final nextRow = widget.source.effectiveRows[nextIndex];
      _controller.updateFocusedRow(nextRow.id);

      if (isShiftPressed) {
        final anchorIndex = _controller.selectionAnchorId != null
            ? widget.source.effectiveRows.indexWhere(
                (r) => r.id == _controller.selectionAnchorId,
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

  // ## MODIFIED: The final, robust key handler ##
  // ## MODIFIED: Re-introducing Cmd/Ctrl + Arrow functionality ##
  KeyEventResult _handleKeyEvent(KeyEvent event) {
    final isArrowDown = event.logicalKey == LogicalKeyboardKey.arrowDown;
    final isArrowUp = event.logicalKey == LogicalKeyboardKey.arrowUp;
    final isCtrlPressed =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // --- Single-Step and Long-Press Navigation (No Ctrl) ---
    if ((isArrowDown || isArrowUp) && !isCtrlPressed) {
      if (event is KeyDownEvent) {
        if (_heldKey != event.logicalKey) {
          _heldKey = event.logicalKey;
          _navigateByOneStep(isDown: isArrowDown);
          _scrollTimer?.cancel();
          // 2. Start a one-shot timer for the initial 1-second delay.
          // 4. Now, start the fast periodic timer for all subsequent steps.
          _scrollTimer = Timer.periodic(const Duration(milliseconds: 220), (
            timer,
          ) {
            _navigateByOneStep(isDown: isArrowDown);
          });
          // Timer(const Duration(milliseconds: 350), () {
          //   // After 1 second, if the key is still held down...
          //   if (_heldKey == null) return;

          //   // 3. Perform the second navigation step.
          //   _navigateByOneStep(isDown: isArrowDown);

          // });
        }
      } else if (event is KeyUpEvent) {
        if (_heldKey == event.logicalKey) {
          _scrollTimer?.cancel();
          _heldKey = null;
        }
      }
      return KeyEventResult.handled;
    }
    // --- End Single-Step Logic ---

    // --- All other KeyDown shortcuts (Select All, Esc, Jumps) ---
    if (event is KeyDownEvent) {
      // --- JUMP TO START/END (With Ctrl) ---
      if ((isArrowDown || isArrowUp) && isCtrlPressed) {
        if (widget.source.rowCount > 0) {
          final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
          final targetIndex = isArrowDown ? widget.source.rowCount - 1 : 0;
          final targetRow = widget.source.effectiveRows[targetIndex];

          _controller.updateFocusedRow(targetRow.id);

          if (isShiftPressed) {
            final anchorIndex = _controller.selectionAnchorId != null
                ? widget.source.effectiveRows.indexWhere(
                    (r) => r.id == _controller.selectionAnchorId,
                  )
                : -1;

            if (anchorIndex != -1) {
              final start = min(anchorIndex, targetIndex);
              final end = max(anchorIndex, targetIndex);
              final rangeIds = widget.source.effectiveRows
                  .sublist(start, end + 1)
                  .map((r) => r.id)
                  .toSet();
              _controller.updateSelectedRows(rangeIds);
            }
          } else {
            _controller.updateSelectedRows({targetRow.id});
            _controller.updateSelectionAnchor(targetRow.id);
          }
          _scrollToIndex(targetIndex);
        }
        return KeyEventResult.handled;
      }
      // --- End Jump Logic ---

      // --- Other Shortcuts ---
      if (widget.onKeyEvent != null && widget.onKeyEvent!(event)) {
        return KeyEventResult.handled;
      }

      if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
        final allIds = widget.source.effectiveRows.map((r) => r.id).toList();
        _controller.selectAll(allIds);
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _controller.clearSelection();
        return KeyEventResult.handled;
      }

      if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_horizontalScrollController.hasClients) {
          _horizontalScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
        return KeyEventResult.handled;
      }

      if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_horizontalScrollController.hasClients) {
          _horizontalScrollController.animateTo(
            _horizontalScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
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

      final lastColumn = widget.headerColumns.last;
      final lastColumnMaxWidth = lastColumn.maxWidth ?? lastColumn.initialWidth;

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

      // when expanded column is decreasing and table columns width is less than actual table width increase the last column width
      //- check if this is an expanded column a (column.isExpand)
      //- check we're trying to decrease it (constrainedWidth < oldWidth)
      //- check when total width <= table width (totalColsWidth <= _actualTableWidth)
      final totalColsWidth = _columnWidths.reduce((a, b) => a + b);
      if (column.isExpand &&
          constrainedWidth < oldWidth && // when decreasing width
          totalColsWidth <= _actualTableWidth) {
        // print("<<<<<<<<<<<<<<<<<< Last column is increasing >>>>>>>>>>>>>>>>>");
        // Give the extra space to the last column instead
        final lastColumnIndex = widget.headerColumns.length - 1;
        final extraSpace = oldWidth - constrainedWidth;
        _columnWidths[lastColumnIndex] += extraSpace;
      }
      //  else {
      //   print(
      //     "first cond failed: ${column.isExpand} and ($constrainedWidth < $oldWidth) and ($totalColsWidth >= $_actualTableWidth)",
      //   );
      // }

      // when any column is expanded and last column is taken extra space deduct it from last column extra space
      // check if we are increasing the width of expanded column (column.isExpand and constrainedWidth > oldWidth)
      // check last column is takes extra space (because of previous step)
      if (constrainedWidth > oldWidth && // when increasing width
          _columnWidths.last > lastColumnMaxWidth) {
        // print("<<<<<<<<<<<<<<<<<< Last column is decreasing >>>>>>>>>>>>>>>>>");
        final increasedWidth = constrainedWidth - oldWidth;
        final lastColumnIndex = widget.headerColumns.length - 1;

        // extra space taken by last column
        var extraSpace = _columnWidths.last - lastColumnMaxWidth;
        // reduce from extra space
        extraSpace = max(0, extraSpace - increasedWidth);
        _columnWidths[lastColumnIndex] = lastColumnMaxWidth + extraSpace;
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
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) => _handleKeyEvent(event),
      child: SizedBox(
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
                      // width: MediaQuery.sizeOf(context).width,
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
                          if (widget.source.sortColumnIndex == actualIndex)
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
