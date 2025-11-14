import 'package:flutter/material.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:mitmui/models/filter_models.dart';
import 'package:mitmui/screens/filter_manager.dart';
import 'package:mitmui/theme.dart';
import 'package:mitmui/widgets/filter/filter_connector.dart';

const _kBorderClr = Color.fromARGB(255, 138, 138, 138);

class FilterConditionWidget extends StatefulWidget {
  const FilterConditionWidget({
    super.key,
    required this.condition,
    required this.manager,
    required this.onRemove,
    required this.onWrapInGroup,
    required this.hasNextChild,
    required this.onOperatorToggle,
    this.showConnector = false,
    this.connectorOperator,
    required this.index,
  });

  final bool hasNextChild;
  final int index;
  final FilterCondition condition;
  final FilterManager manager;
  final VoidCallback onRemove;
  final VoidCallback onWrapInGroup;
  final VoidCallback? onOperatorToggle;
  final bool showConnector;
  final LogicalOperator? connectorOperator;

  @override
  State<FilterConditionWidget> createState() => _FilterConditionWidgetState();
}

class _FilterConditionWidgetState extends State<FilterConditionWidget> {
  late final TextEditingController _valueController;
  final _keyPickerKey = GlobalKey<CustomPopupState>();
  final _operatorPickerKey = GlobalKey<CustomPopupState>();
  final _menuKey = GlobalKey<CustomPopupState>();
  final focusNode = FocusNode();
  final GlobalKey _containerKey = GlobalKey();
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: widget.condition.value);
  }

  @override
  void didUpdateWidget(covariant FilterConditionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.condition.value != _valueController.text) {
      _valueController.text = widget.condition.value;
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final operatorText =
        (widget.condition.isNegated ? '!' : '') +
        widget.condition.operator.symbol;
    final theme = AppTheme.from(Theme.brightnessOf(context));
    final popupClr = theme.surfaceLight;

    return Row(
      crossAxisAlignment: .start,
      children: [
        // Left connector indicator or space (if has next child)
        if (widget.showConnector)
          FilterConnector(
            operator: widget.connectorOperator!,
            onToggle: widget.onOperatorToggle,
          )
        else if (widget.hasNextChild)
          SizedBox(width: 40),
        Expanded(
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: Container(
              key: _containerKey,
              height: 32,
              margin: const .only(top: 8),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isHovered
                      ? _kBorderClr.withValues(alpha: 0.6)
                      : _kBorderClr.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Drag Handle
                  SizedBox(
                    width: 32,
                    child: Icon(
                      Icons.drag_indicator,
                      size: 16,
                      color: Colors.grey.withValues(alpha: 0.4),
                    ),
                  ),

                  // Key Picker
                  SizedBox(
                    child: CustomPopup(
                      key: _keyPickerKey,
                      arrowColor: popupClr,
                      backgroundColor: popupClr,
                      content: _KeyPickerPopup(
                        onSelected: (key) {
                          if (key == FilterKey.statusCode) {
                            _valueController.text = '';
                          }
                          setState(() => widget.condition.keyType = key);
                          widget.manager.update();
                          Navigator.of(context).pop();
                          focusNode.requestFocus();
                        },
                      ),
                      child: InkWell(
                        onTap: () => _keyPickerKey.currentState?.show(),
                        child: Container(
                          padding: const .symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: _kBorderClr.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: .spaceBetween,
                            children: [
                              SizedBox(
                                width: 110,
                                child: Text(
                                  widget.condition.keyType.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Operator Picker
                  CustomPopup(
                    key: _operatorPickerKey,
                    backgroundColor: popupClr,
                    arrowColor: popupClr,
                    content: _OperatorPickerPopup(
                      condition: widget.condition,
                      onChanged: () {
                        setState(() {});
                        widget.manager.update();
                        Navigator.of(context).pop();
                      },
                      onWrapInGroup: () {
                        widget.onWrapInGroup();
                        Navigator.of(context).pop();
                      },
                      onRemove: () {
                        widget.onRemove();
                        Navigator.of(context).pop();
                      },
                    ),
                    child: InkWell(
                      onTap: () => _operatorPickerKey.currentState?.show(),
                      child: Container(
                        width: 50,
                        padding: const .symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: _kBorderClr.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          operatorText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Value Input
                  Expanded(
                    child: TextField(
                      controller: _valueController,
                      focusNode: focusNode,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Enter value...',
                        hintStyle: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const .symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) {
                        widget.condition.value = value;
                        widget.manager.update();
                      },
                    ),
                  ),

                  // More Menu
                  SizedBox(
                    width: 32,
                    child: CustomPopup(
                      key: _menuKey,
                      backgroundColor: popupClr,
                      arrowColor: popupClr,
                      content: _ConditionMenuPopup(
                        condition: widget.condition,
                        onChanged: () {
                          setState(() {});
                          widget.manager.update();
                          Navigator.of(context).pop();
                        },
                        onWrapInGroup: widget.onWrapInGroup,
                        onRemove: widget.onRemove,
                      ),
                      child: InkWell(
                        onTap: () => _menuKey.currentState?.show(),
                        child: Icon(
                          Icons.more_vert,
                          size: 16,
                          color: Colors.grey.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Condition Menu Popup
class _ConditionMenuPopup extends StatelessWidget {
  const _ConditionMenuPopup({
    required this.onWrapInGroup,
    required this.onRemove,
    required this.condition,
    required this.onChanged,
  });

  final VoidCallback onWrapInGroup;
  final VoidCallback onRemove;
  final FilterCondition condition;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const .symmetric(vertical: 4),
      child: Column(
        mainAxisSize: .min,
        children: [
          TextButton(
            onPressed: onWrapInGroup,
            style: TextButton.styleFrom(
              padding: .symmetric(horizontal: 16, vertical: 8),
            ),
            child: const SizedBox(
              width: double.infinity,
              child: Text(
                '(...) Wrap in Group',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              condition.isNegated = !condition.isNegated;
              onChanged();
            },
            style: TextButton.styleFrom(
              padding: .symmetric(horizontal: 16, vertical: 8),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                condition.isNegated ? '!  Remove Negation' : '!  Negate',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          const Divider(height: 12, thickness: 1),
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(
              padding: .symmetric(horizontal: 16, vertical: 8),
            ),
            child: const SizedBox(
              width: double.infinity,
              child: Text(
                'Remove Condition',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Operator Picker Popup
class _OperatorPickerPopup extends StatelessWidget {
  const _OperatorPickerPopup({
    required this.condition,
    required this.onChanged,
    required this.onWrapInGroup,
    required this.onRemove,
  });

  final FilterCondition condition;
  final VoidCallback onChanged;
  final VoidCallback onWrapInGroup;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const .symmetric(vertical: 8),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: const .symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Operators',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          for (final op in FilterOperator.values)
            GestureDetector(
              onDoubleTap: () {
                condition.operator = op;
                condition.isNegated = true;
                onChanged();
              },
              child: TextButton(
                onPressed: () {
                  condition.operator = op;
                  condition.isNegated = false;
                  onChanged();
                },
                style: TextButton.styleFrom(
                  padding: .symmetric(horizontal: 16, vertical: 8),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    '${op.symbol}   :  ${op.name}',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          const Divider(),
          TextButton(
            onPressed: () {
              condition.isNegated = !condition.isNegated;
              onChanged();
            },
            style: TextButton.styleFrom(
              padding: .symmetric(horizontal: 16, vertical: 8),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                condition.isNegated ? '!  Remove Negation' : '!  Negate',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// #############################################################################
// ## Key Picker Popup
// #############################################################################
class _KeyPickerPopup extends StatefulWidget {
  const _KeyPickerPopup({required this.onSelected});
  final ValueChanged<FilterKey> onSelected;

  @override
  State<_KeyPickerPopup> createState() => _KeyPickerPopupState();
}

class _KeyPickerPopupState extends State<_KeyPickerPopup> {
  String _searchTerm = '';
  List<FilterKey> get _filteredKeys {
    if (_searchTerm.isEmpty) return FilterKey.values;
    return FilterKey.values
        .where(
          (key) =>
              key.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
              key.prettyName.toLowerCase().contains(_searchTerm.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.from(Theme.brightnessOf(context));
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const .all(8),
        width: 220,
        height: 320,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              onChanged: (val) => setState(() => _searchTerm = val),
              style: TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search key...',
                hintStyle: TextStyle(fontSize: 13),
                isDense: true,
                filled: true,
                fillColor: theme.surfaceBright,
                prefixIcon: Icon(Icons.search, size: 16),
                contentPadding: .symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredKeys.length,
                itemBuilder: (context, index) {
                  final key = _filteredKeys[index];
                  return InkWell(
                    onTap: () => widget.onSelected(key),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const .symmetric(horizontal: 12, vertical: 8),
                      child: Text(key.name, style: TextStyle(fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
