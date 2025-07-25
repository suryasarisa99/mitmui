import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mitmui/dt_table/dt_table.dart';
import 'package:mitmui/dt_table/dt_models.dart';

abstract class DtSource extends ChangeNotifier {
  List<DtRow> rows = [];
  List<DtRow> _effectiveRows = [];

  List<DtRow> get effectiveRows => _effectiveRows;
  int get rowCount => _effectiveRows.length;

  String? _sortColumnKey;
  SortType _sortType = SortType.none;

  String? get sortColumnKey => _sortColumnKey;
  SortType get sortType => _sortType;

  DtRowAdapter buildRow(DtRow row, int index, bool isSelected, bool hasFocus);

  void updateData() {
    _effectiveRows = List.from(rows);
    notifyListeners();
  }

  void sort(
    String columnKey,
    int colIndex,
    bool isNumeric, [
    DtController? controller,
  ]) {
    if (_sortColumnKey == columnKey) {
      // Cycle through sort states: none -> ascending -> descending -> none
      switch (_sortType) {
        case SortType.none:
          _sortType = SortType.ascending;
          break;
        case SortType.ascending:
          _sortType = SortType.descending;
          break;
        case SortType.descending:
          _sortType = SortType.none;
          _sortColumnKey = null;
          break;
      }
    } else {
      _sortColumnKey = columnKey;
      _sortType = SortType.ascending;
    }

    controller?.updateSort(_sortColumnKey, _sortType);
    _applySort(colIndex, isNumeric);
    notifyListeners();
  }

  void _applySort(int colIndex, bool isNumeric) {
    log('apply sort', stackTrace: StackTrace.current);
    _effectiveRows = List.from(rows);
    if (_sortColumnKey != null && _sortType != SortType.none) {
      _effectiveRows.sort((a, b) {
        late int compare;
        if (isNumeric) {
          final aValue = a.cells[colIndex].value as num;
          final bValue = b.cells[colIndex].value as num;
          compare = aValue.compareTo(bValue);
        } else {
          final aValue = a.cells[colIndex].value;
          final bValue = b.cells[colIndex].value;
          compare = aValue.compareTo(bValue);
        }
        return _sortType == SortType.ascending ? compare : -compare;
      });
    }
  }
}
