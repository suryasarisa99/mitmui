import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mitmui/dt_table/dt_table.dart';
import 'package:mitmui/dt_table/dt_models.dart';

abstract class DtSource extends ChangeNotifier {
  List<DtRow> rows = [];
  List<DtRow> _effectiveRows = [];

  List<DtRow> get effectiveRows => _effectiveRows;
  int get rowCount => _effectiveRows.length;

  int? _sortColumnIndex;
  SortType _sortType = SortType.none;

  int? get sortColumnIndex => _sortColumnIndex;
  SortType get sortType => _sortType;

  DtController get controller;

  DtRowAdapter buildRow(DtRow row, int index, bool isSelected, bool hasFocus);

  void updateData() {
    _effectiveRows = List.from(rows);
    if (controller.sortColumnIndex != null &&
        controller.sortType != SortType.none) {
      _applySort(controller.sortColumnIndex!, false);
    }
    notifyListeners();
  }

  void sort(int colIndex, bool isNumeric) {
    if (_sortColumnIndex == colIndex) {
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
          _sortColumnIndex = null;
          break;
      }
    } else {
      _sortColumnIndex = colIndex;
      _sortType = SortType.ascending;
    }

    controller.updateSort(_sortColumnIndex, _sortType);
    _applySort(colIndex, isNumeric);
    notifyListeners();
  }

  void _applySort(int colIndex, bool isNumeric) {
    // log('apply sort', stackTrace: StackTrace.current);
    _effectiveRows = List.from(rows);
    if (_sortColumnIndex != null && _sortType != SortType.none) {
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
