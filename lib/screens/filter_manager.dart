import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mitmui/models/filter_models.dart';

class FilterManager extends ChangeNotifier {
  FilterManager({this.debounce = 250, this.auto = true}) {
    // Initialize with a root group containing one default condition
    _rootFilter = FilterGroup(children: [FilterCondition()]);
  }
  final int debounce;
  final bool auto;
  late final FilterGroup _rootFilter;
  late String _cachedMitmproxyString = '';
  FilterGroup get rootFilter => _rootFilter;

  Timer? _debounce;

  /// Returns the current filter as a mitmproxy-compatible string.
  String get mitmproxyString => _cachedMitmproxyString;

  /// Call this method after any part of the filter model has been changed
  /// to notify listeners and regenerate the filter string.
  void update() {
    if (!auto) return;

    // if debounce turned off
    if (debounce == 0) {
      apply();
    }
    // if debounce turned on
    else {
      _debounce?.cancel();
      _debounce = Timer(Duration(milliseconds: debounce), apply);
    }
  }

  void apply() {
    final newString = _toMitmproxyString(_rootFilter, true).trim();
    if (newString != _cachedMitmproxyString) {
      _cachedMitmproxyString = newString;
      notifyListeners();
    }
  }

  /// operations

  // add condition to group
  void addConditionTo(FilterGroup group) {
    if (group.children.isNotEmpty) {
      group.operators.add(LogicalOperator.and);
    }
    group.children.add(FilterCondition());
    update();
  }

  // add sub-group to group
  void addSubgroupTo(FilterGroup group) {
    if (group.children.isNotEmpty) {
      group.operators.add(LogicalOperator.and);
    }
    group.children.add(FilterGroup(children: [FilterCondition()]));
    update();
  }

  // add condition to root
  void addConditionToRoot() {
    addConditionTo(_rootFilter);
  }

  // add group to root
  void addSubgroupToRoot() {
    addSubgroupTo(_rootFilter);
  }

  // --- Conversion Logic ---

  /// Escapes characters that have a special meaning in regex.
  String _escapeRegex(String text) {
    return text.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (match) {
      return '\\${match.group(0)}';
    });
  }

  String _toMitmproxyString(FilterNode node, [bool isRoot = false]) {
    // Handle FilterCondition (a single rule)
    if (node is FilterCondition) {
      if (node.value.isEmpty) {
        return '';
      }

      String regexValue = getRegexValue(node);

      final valueStr = _quoteIfNeeded(regexValue);
      final conditionStr = '${node.keyType.prettyName} $valueStr';
      return node.isNegated ? '!$conditionStr' : conditionStr;
      // return node.isNegated ? '!($conditionStr)' : conditionStr;
    }

    // Handle FilterGroup (a collection of rules)
    if (node is FilterGroup) {
      final parts = node.children
          .map(_toMitmproxyString)
          .where((s) => s.isNotEmpty)
          .toList();

      if (parts.isEmpty) {
        return '';
      }

      if (parts.length == 1) {
        final singlePart = parts.first;
        return node.isNegated ? '!($singlePart)' : singlePart;
      }

      String result = parts.first;
      for (int i = 1; i < parts.length; i++) {
        final op = node.operators[i - 1] == LogicalOperator.and ? '&' : '|';
        result += ' $op ${parts[i]}';
      }

      if (isRoot) {
        return node.isNegated ? '!($result)' : result;
      }
      return node.isNegated ? '!($result)' : '($result)';
    }

    return '';
  }

  /// Adds quotes to a string if it contains spaces.
  String _quoteIfNeeded(String value) {
    if (value.contains(RegExp(r'\s')) && !value.startsWith('"')) {
      return '"$value"';
    }
    return value;
  }

  // String getRegexValue(FilterOperator operator, FilterCondition node) {
  //   return switch (operator) {
  //     .equals => '^${_escapeRegex(node.value)}\$',
  //     .startsWith => '^${_escapeRegex(node.value)}',
  //     .endsWith => '${_escapeRegex(node.value)}\$',
  //     .regex => node.value,
  //   };
  // }

  String getRegexValue(FilterCondition node) {
    String regexValue;
    String escapedValue = _escapeRegex(node.value);
    String value = node.value;
    switch (node.keyType) {
      case .fileExtension:
        regexValue = switch (node.operator) {
          .equals => '\\.$escapedValue(\\?|\$)',
          .startsWith => '\\.$escapedValue[^.?/]*?(\\?|\$)',
          .endsWith => '\\.[^.?/]*?$escapedValue(\\?|\$)',
          .regex => '\\.($value)(\\?|\$)',
        };
        break;
      case .queryParam:
        final searchPattern = (node.operator == FilterOperator.regex)
            ? value
            : escapedValue;
        regexValue = '\\?.*$searchPattern';
        break;
      case .queryKey:
        regexValue = switch (node.operator) {
          .equals => '=$escapedValue(&|\$)',
          .startsWith => '[?&]$escapedValue[^=&]*=',
          .endsWith => '=[^&]*?$escapedValue(&|\$)',
          .regex => '[?&]($value)[^=&]*=',
        };
        break;
      case .queryValue:
        regexValue = switch (node.operator) {
          .equals => '=$escapedValue(?=&|\$)',
          .startsWith => '=$escapedValue[^&]*',
          .endsWith => '=[^&]*$escapedValue(?=&|\$)',
          .regex => '=[^&]*($value)[^&]*',
        };
        break;

      default:
        regexValue = switch (node.operator) {
          .equals => '^${_escapeRegex(node.value)}\$',
          .startsWith => '^${_escapeRegex(node.value)}',
          .endsWith => '${_escapeRegex(node.value)}\$',
          .regex => node.value,
        };
    }
    return regexValue;
  }
}
