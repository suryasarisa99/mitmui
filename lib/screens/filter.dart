// lib/filter_models.dart
import 'package:flutter/material.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:mitmui/models/filter_models.dart';
import 'package:mitmui/screens/filter_manager.dart';
import 'package:mitmui/theme.dart';
import 'package:mitmui/widgets/resizable_text_field.dart';

// lib/filter_ui.dart
// lib/filter_ui.dart
const _kBorderClr = Color.fromARGB(255, 138, 138, 138);
const _kBorderRadius = Radius.circular(4);
const _kInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(_kBorderRadius),
  borderSide: BorderSide(color: Colors.grey),
);

// #############################################################################
// ## Filter Condition Widget (Leaf Node)
// #############################################################################
class FilterConditionWidget extends StatefulWidget {
  const FilterConditionWidget({
    super.key,
    required this.condition,
    required this.manager,
    required this.onRemove,
    required this.onWrapInGroup,
  });

  final FilterCondition condition;
  final FilterManager manager;
  final VoidCallback onRemove;
  final VoidCallback onWrapInGroup;

  @override
  State<FilterConditionWidget> createState() => _FilterConditionWidgetState();
}

class _FilterConditionWidgetState extends State<FilterConditionWidget> {
  late final TextEditingController _valueController;
  // ✨ CHANGED: Controller for the popup
  // final CustomPopupController _keyPickerController = CustomPopupController();
  final GlobalKey<CustomPopupState> _keyPickerKey =
      GlobalKey<CustomPopupState>();
  final GlobalKey<CustomPopupState> _operatorPickerKey =
      GlobalKey<CustomPopupState>();
  final focusNode = FocusNode();

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
    // _keyPickerController.dispose(); // ✨ CHANGED: Dispose the controller
    super.dispose();
  }

  // void _showOperatorPicker(BuildContext context) {
  //   showMenu(
  //     context: context,
  //     position: const RelativeRect.fromLTRB(0, 40, 0, 0),
  //     items: [
  //       for (final op in FilterOperator.values)
  //         PopupMenuItem(
  //           value: op,
  //           child: Text('Operator: ${op.symbol} (${op.name})'),
  //           onTap: () {
  //             setState(() => widget.condition.operator = op);
  //             widget.onChanged();
  //           },
  //         ),
  //       // const PopupMenuDivider(),
  //       PopupMenuItem(
  //         child: Text(
  //           widget.condition.isNegated ? 'Remove Negation (!)' : 'Negate (!)',
  //         ),
  //         onTap: () {
  //           setState(
  //             () => widget.condition.isNegated = !widget.condition.isNegated,
  //           );
  //           widget.onChanged();
  //         },
  //       ),
  //       PopupMenuItem(
  //         child: const Text('Wrap in Group (...)'),
  //         onTap: widget.onWrapInGroup,
  //       ),
  //       // const PopupMenuDivider(),
  //       PopupMenuItem(
  //         child: const Text(
  //           'Remove Condition',
  //           style: TextStyle(color: Colors.red),
  //         ),
  //         onTap: widget.onRemove,
  //       ),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final operatorText =
        (widget.condition.isNegated ? '!' : '') +
        widget.condition.operator.symbol;
    final theme = AppTheme.from(Theme.brightnessOf(context));
    final popupClr = theme.surfaceLight;

    return SizedBox(
      height: 22,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✨ CHANGED: The entire key picker button is now wrapped in CustomPopup
          SizedBox(
            height: 22,
            child: CustomPopup(
              key: _keyPickerKey,
              arrowColor: popupClr,
              backgroundColor: popupClr,
              // barrierColor: Colors.red,
              content: _KeyPickerPopup(
                onSelected: (key) {
                  if (key == FilterKey.statusCode) {
                    // clear text and only allow numbers
                    _valueController.text = '';
                  }
                  setState(() => widget.condition.keyType = key);
                  widget.manager.update();
                  Navigator.of(context).pop(); // Hide after selection
                  // focus on the value field
                  focusNode.requestFocus();
                },
              ),
              child: TextButton(
                onPressed: () {
                  _keyPickerKey.currentState?.show(); // Show the popup
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  side: const BorderSide(color: _kBorderClr),
                ),
                child: Text(widget.condition.keyType.name),
              ),
            ),
          ),

          // 2. Operator / Action Button
          SizedBox(
            height: 22,
            width: 24,
            child: CustomPopup(
              key: _operatorPickerKey,
              backgroundColor: popupClr,
              arrowColor: popupClr,
              content: _OperatorPickerPopup(
                condition: widget.condition,
                onChanged: () {
                  setState(() {}); // Re-render to show new state
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
              // child: TextButton(
              //   onPressed: () => _operatorPickerKey.currentState?.show(),
              //   style: TextButton.styleFrom(
              //     padding: EdgeInsets.zero,
              //     shape: const RoundedRectangleBorder(),
              //     side: const BorderSide(
              //       color: Color.fromARGB(0, 158, 158, 158),
              //       width: 0.5,
              //       style: BorderStyle.solid,
              //     ),
              //   ),
              //   child: Text(
              //     operatorText,
              //     style: const TextStyle(fontWeight: FontWeight.bold),
              //   ),
              // ),
              child: InkWell(
                onTap: () => _operatorPickerKey.currentState?.show(),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: _kBorderClr, width: 1),
                      top: BorderSide(color: _kBorderClr, width: 1),
                    ),
                    color: theme.surface,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    operatorText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),

          // 3. Value Input Field
          SizedBox(
            height: 22,
            // child: TextFormField(
            //   controller: _valueController,
            //   onChanged: (value) {
            //     widget.condition.value = value;
            //     widget.manager.update();
            //   },
            //   decoration: const InputDecoration(
            //     contentPadding: EdgeInsets.symmetric(
            //       horizontal: 8,
            //       vertical: 6,
            //     ),
            //     isDense: true,
            //     border: _kInputBorder,
            //     enabledBorder: _kInputBorder,
            //     focusedBorder: _kInputBorder,
            //     filled: true,
            //     // fillColor: Colors.white,
            //   ),
            // ),
            child: ResizableTextField(
              controller: _valueController,
              maxWidth: 300,
              minWidth: 100,
              onlyNumbers: widget.condition.keyType == FilterKey.statusCode,
              style: TextStyle(fontSize: 14),
              focusNode: focusNode,
              borderRadius: const BorderRadius.only(
                topRight: _kBorderRadius,
                bottomRight: _kBorderRadius,
              ),
              unfocusedBorderColor: _kBorderClr,
              focusedBorderColor: const Color.fromARGB(255, 192, 192, 192),
              onChanged: (value) {
                widget.condition.value = value;
                widget.manager.update();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ✨ ADDED: The popup widget for the central operator.
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
      width: 180,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    '${op.symbol}   :  ${op.name} ',
                    textAlign: TextAlign.left,
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
            child: SizedBox(
              width: double.infinity,
              child: Text(
                condition.isNegated ? '!  Remove Negation' : '!  Negate',
              ),
            ),
          ),
          TextButton(
            onPressed: onWrapInGroup,
            child: SizedBox(
              width: double.infinity,
              child: const Text('(...) Wrap in Group'),
            ),
          ),
          const Divider(),
          TextButton(
            onPressed: onRemove,
            child: SizedBox(
              width: double.infinity,
              child: const Text(
                'Remove Condition',
                style: TextStyle(color: Colors.red),
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
        padding: const EdgeInsets.all(8),
        width: 200,
        height: 300,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              onChanged: (val) => setState(() => _searchTerm = val),
              decoration: InputDecoration(
                hintText: 'Search key...',
                isDense: true,
                filled: true,
                fillColor: theme.surfaceBright,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredKeys.length,
                itemExtent: 36,
                itemBuilder: (context, index) {
                  final key = _filteredKeys[index];
                  return ListTile(
                    // focusColor: Colors.red,
                    // hoverColor: Colors.green,
                    // selectedColor: Colors.black,
                    // selectedTileColor: Colors.blueGrey.withOpacity(0.1),
                    dense: true,
                    minTileHeight: 36,
                    title: Text(key.name, style: TextStyle(fontSize: 14)),
                    // subtitle: Text(key.prettyName),
                    onTap: () => widget.onSelected(key),
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

// #############################################################################
// ## Filter Group Widget (Internal Node - Recursive)
// #############################################################################
// NOTE: NO CHANGES ARE NEEDED IN THE FilterGroupWidget
class FilterGroupWidget extends StatefulWidget {
  const FilterGroupWidget({
    super.key,
    required this.group,
    required this.manager,
    this.onRemove, // Optional: root group cannot be removed
    this.isRoot = false,
  });

  final FilterGroup group;
  final FilterManager manager;
  final VoidCallback? onRemove;
  final bool isRoot;

  @override
  State<FilterGroupWidget> createState() => _FilterGroupWidgetState();
}

class _FilterGroupWidgetState extends State<FilterGroupWidget> {
  void _addCondition() {
    setState(() {
      // If there's at least one child, we are creating a new "gap"
      // that needs an operator.
      if (widget.group.children.isNotEmpty) {
        widget.group.operators.add(LogicalOperator.and);
      }
      widget.group.children.add(FilterCondition());
    });
    widget.manager.update();
  }

  // void _showAddMenu(BuildContext context) {
  //   showMenu(
  //     context: context,
  //     position: const RelativeRect.fromLTRB(0, 40, 0, 0),
  //     items: [
  //       PopupMenuItem(
  //         onTap: () => _addCondition(LogicalOperator.and),
  //         child: const Text('AND (&)'),
  //       ),
  //       PopupMenuItem(
  //         onTap: () => _addCondition(LogicalOperator.or),
  //         child: const Text('OR (|)'),
  //       ),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: widget.isRoot
              ? Colors.transparent
              : const Color.fromARGB(255, 128, 116, 113).withOpacity(0.5),
        ),
      ),
      child: Wrap(
        spacing: 2,
        // spacing: 8,
        runSpacing: 3,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (int i = 0; i < widget.group.children.length; i++) ...[
            // Render the child node
            _buildChild(i),
            // Render the logical operator between children
            if (i < widget.group.children.length - 1) _buildLogicalOperator(i),
          ],

          // The '+' button
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: IconButton(
              iconSize: 20,
              constraints: const BoxConstraints.tightFor(width: 24, height: 22),
              splashRadius: 24,
              padding: const EdgeInsets.all(0),
              icon: const Icon(
                Icons.add,
                color: Color.fromARGB(255, 146, 155, 146),
              ),
              onPressed: _addCondition,
            ),
          ),
          if (!widget.isRoot)
            CustomPopup(
              arrowColor: AppTheme.from(
                Theme.brightnessOf(context),
              ).surfaceLight,
              backgroundColor: AppTheme.from(
                Theme.brightnessOf(context),
              ).surfaceLight,
              content: _GroupMenuPicker(
                group: widget.group,
                manager: widget.manager,
                onRemove: widget.onRemove!,
              ),
              child: Icon(Icons.more_vert, color: Colors.grey, size: 20),
            ),
          //       width: 24,
          //       height: 22,
          //     ),
          //     splashRadius: 24,
          //     padding: const EdgeInsets.all(0),
          //     icon: const Icon(
          //       Icons.cancel,
          //       color: Color.fromARGB(255, 105, 105, 105),
          //     ),
          //     onPressed: widget.onRemove,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildChild(int index) {
    final node = widget.group.children[index];

    void handleRemove() {
      setState(() {
        widget.group.children.removeAt(index);
        // ✨ CHANGED: Remove the corresponding operator when a child is removed.
        if (widget.group.operators.isNotEmpty) {
          widget.group.operators.removeAt(index > 0 ? index - 1 : 0);
        }
      });
      widget.manager.update();
    }

    void handleWrapInGroup() {
      setState(() {
        final originalNode = widget.group.children[index];
        final newGroup = FilterGroup(children: [originalNode]);
        widget.group.children[index] = newGroup;
      });
      widget.manager.update();
    }

    // We use a Key here to ensure Flutter replaces the widget correctly
    // when a condition is wrapped into a group.
    if (node is FilterGroup) {
      return FilterGroupWidget(
        key: ValueKey(node.key),
        group: node,
        manager: widget.manager,
        onRemove: handleRemove,
      );
    }

    if (node is FilterCondition) {
      return FilterConditionWidget(
        key: ValueKey(node.key),
        condition: node,
        manager: widget.manager,
        onRemove: handleRemove,
        onWrapInGroup: handleWrapInGroup,
      );
    }

    return Container(); // Should not happen
  }

  // ✨ CHANGED: This widget now takes an index and uses CustomPopup.
  Widget _buildLogicalOperator(int operatorIndex) {
    final key = GlobalKey<CustomPopupState>();
    final currentOperator = widget.group.operators[operatorIndex];
    final popupClr = AppTheme.from(Theme.brightnessOf(context)).surfaceLight;
    return SizedBox(
      height: 22,
      width: 40,
      child: CustomPopup(
        key: key,
        arrowColor: popupClr,
        backgroundColor: popupClr,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              child: const Text('AND'),
              onPressed: () {
                setState(
                  () => widget.group.operators[operatorIndex] =
                      LogicalOperator.and,
                );
                widget.manager.update();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OR'),
              onPressed: () {
                setState(
                  () => widget.group.operators[operatorIndex] =
                      LogicalOperator.or,
                );
                widget.manager.update();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        child: TextButton(
          onPressed: () => key.currentState?.show(),
          child: Text(
            currentOperator == LogicalOperator.and ? '&' : 'or',
            style: TextStyle(
              color: currentOperator == LogicalOperator.and
                  ? Colors.red
                  : const Color.fromARGB(255, 184, 223, 255),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupMenuPicker extends StatelessWidget {
  const _GroupMenuPicker({
    required this.group,
    required this.manager,
    required this.onRemove,
  });

  final FilterGroup group;
  final FilterManager manager;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () {
            group.isNegated = !group.isNegated;
            manager.update();
            Navigator.of(context).pop();
          },
          child: Text(
            !group.isNegated ? '! Negate Group' : '! Remove Negation',
          ),
        ),
        TextButton(onPressed: () {}, child: Text("Collapse Group")),
        TextButton(onPressed: () {}, child: Text("(...)  Wrap Group")),
        TextButton(
          onPressed: () {
            onRemove();
            manager.update();
            Navigator.of(context).pop();
          },
          child: Text("Remove Group"),
        ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.group,
    required this.manager,
    required this.onRemove,
  });

  final FilterGroup group;
  final FilterManager manager;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // height: 28,
      child: Row(
        children: [
          SizedBox(
            // width: 24,
            // height: 22,
            child: Checkbox(
              value: group.isNegated,
              visualDensity: VisualDensity.compact,
              onChanged: (val) {
                group.isNegated = val ?? false;
                manager.update();
              },
            ),
          ),
          const Text('Negate Group'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
