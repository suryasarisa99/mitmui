import 'package:flutter/material.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:mitmui/models/filter_models.dart';
import 'package:mitmui/screens/filter_manager.dart';
import 'package:mitmui/theme.dart';
import 'package:mitmui/widgets/filter/filter_condition.dart';
import 'package:mitmui/widgets/filter/filter_connector.dart';

const _kBorderClr = Color.fromARGB(255, 138, 138, 138);

class FilterGroupWidget extends StatefulWidget {
  const FilterGroupWidget({
    super.key,
    required this.index,
    required this.group,
    required this.manager,
    this.hasNextChild = false,
    this.onRemove,
    this.isRoot = false,
    this.showConnector = false,
    this.connectorOperator,
    this.onOperatorToggle,
  });
  final int index;
  final FilterGroup group;
  final FilterManager manager;
  final VoidCallback? onRemove;
  final VoidCallback? onOperatorToggle;
  final bool hasNextChild;
  final bool isRoot;
  final bool showConnector;
  final LogicalOperator? connectorOperator;

  @override
  State<FilterGroupWidget> createState() => _FilterGroupWidgetState();
}

class _FilterGroupWidgetState extends State<FilterGroupWidget> {
  bool _isHidden = false;
  final _groupActionsPickerKey = GlobalKey<CustomPopupState>();

  void _addCondition() {
    setState(() {
      widget.manager.addConditionTo(widget.group);
    });
  }

  void _addSubGroup() {
    setState(() {
      widget.manager.addSubgroupTo(widget.group);
    });
  }

  void _negateGroup() {
    setState(() {
      widget.group.isNegated = !widget.group.isNegated;
    });
    widget.manager.update();
  }

  void _hideGroup() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }

  void collapseGroup() {
    // TODO: implement collapse logic
    // This moves all children to parent and removes this group
  }

  Widget? _buildConnector() {
    if (widget.showConnector) {
      return FilterConnector(
        operator: widget.connectorOperator!,
        onToggle: widget.onOperatorToggle,
      );
    } else if (widget.hasNextChild) {
      return SizedBox(width: 40);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // is Hidden
    if (_isHidden && !widget.isRoot) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ?_buildConnector(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildGroupHeader(),
            ),
          ),
        ],
      );
    }

    final content = _buildContent();

    // is Root
    if (widget.isRoot) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(child: SingleChildScrollView(child: content)),
          SizedBox(height: 18),
          buildActions(),
        ],
      );
    }

    // is not Root
    final groupColors = [
      const Color.fromARGB(255, 44, 32, 46),
      const Color.fromARGB(255, 38, 36, 31),
      const Color.fromARGB(255, 25, 33, 25),
      const Color.fromARGB(255, 42, 52, 51),
      const Color.fromARGB(255, 37, 39, 46),
      const Color.fromARGB(255, 46, 37, 37),
    ];
    final color = groupColors[widget.index % groupColors.length];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ?_buildConnector(),
        if (!_isHidden)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: widget.isRoot ? 0 : 8),
              padding: !_isHidden
                  ? EdgeInsets.all(widget.isRoot ? 0 : 12)
                  : null,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: widget.isRoot
                    ? null
                    : Border.all(
                        color: widget.group.isNegated
                            ? Colors.red.withValues(alpha: 0.3)
                            : _kBorderClr.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                color: widget.isRoot
                    ? Colors.transparent
                    : color.withValues(alpha: 0.4),
              ),
              child: content,
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Group Header
        if (!widget.isRoot) _buildGroupHeader(),

        // Children with connectors
        for (int i = 0; i < widget.group.children.length; i++) _buildChild(i),

        SizedBox(height: 8),
        if (widget.isRoot) SizedBox(height: 12),

        // Action Buttons Row
        if (!widget.isRoot) buildActions(),
      ],
    );
  }

  Widget buildActions() {
    return Row(
      children: [
        // Add Condition btn
        SizedBox(
          height: 32,
          child: TextButton.icon(
            onPressed: _addCondition,
            icon: Icon(Icons.add, size: 14),
            label: Text('Add Condition', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Add Subgroup btn
        SizedBox(
          height: 32,
          child: TextButton.icon(
            onPressed: _addSubGroup,
            icon: Icon(Icons.folder_outlined, size: 14, color: Colors.grey),
            label: Text(
              'Add Subgroup',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),

        // for root group only
        if (widget.isRoot) ...[
          Spacer(),
          SizedBox(
            height: 28,
            child: FilledButton.tonalIcon(
              onPressed: () {
                setState(() {
                  widget.group.children.clear();
                  widget.group.operators.clear();
                });
                widget.manager.apply();
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  // vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              icon: Icon(Icons.refresh, size: 16),
              label: Text('Reset'),
            ),
          ),
          const SizedBox(width: 8),

          // apply btn
          if (!widget.manager.auto)
            SizedBox(
              height: 28,
              child: FilledButton.icon(
                onPressed: () {
                  widget.manager.apply();
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    // vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: Icon(Icons.check, size: 16),
                label: Text('Apply'),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildGroupHeader() {
    final childCount = widget.group.children.length;
    final theme = AppTheme.from(Theme.brightnessOf(context));
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.surfaceBright,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _kBorderClr.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator,
            size: 14,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 6),

          Text(
            widget.group.isNegated ? '! Group' : 'Group',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Text(
            // '($childCount condition${childCount != 1 ? 's' : ''})',
            '($childCount)',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.withValues(alpha: 0.7),
            ),
          ),

          const Spacer(),

          InkWell(
            onTap: _hideGroup,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                _isHidden ? Icons.expand_more : Icons.expand_less,
                size: 14,
              ),
            ),
          ),

          const SizedBox(width: 4),

          CustomPopup(
            arrowColor: theme.surfaceLight,
            backgroundColor: theme.surfaceLight,
            key: _groupActionsPickerKey,
            content: _GroupMenuPicker(
              group: widget.group,
              manager: widget.manager,
              onRemove: widget.onRemove!,
              onCollapse: collapseGroup,
              onNegate: _negateGroup,
            ),
            child: InkWell(
              onTap: () {
                _groupActionsPickerKey.currentState?.show();
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.more_vert,
                  size: 14,
                  color: Colors.grey.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChild(int index) {
    final node = widget.group.children[index];
    final showConnector = index > 0;
    final hasNextChild = index < widget.group.children.length - 1;
    final connectorOp = showConnector
        ? widget.group.operators[index - 1]
        : null;

    void handleRemove() {
      setState(() {
        widget.group.children.removeAt(index);
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

    void handleOperatorToggle() {
      debugPrint('Toggling operator at index $index');
      setState(() {
        if (connectorOp != null) {
          final currentOp = widget.group.operators[index - 1];
          widget.group.operators[index - 1] = currentOp == LogicalOperator.and
              ? LogicalOperator.or
              : LogicalOperator.and;
        }
      });
      widget.manager.update();
    }

    if (node is FilterGroup) {
      return FilterGroupWidget(
        index: index,
        group: node,
        hasNextChild: hasNextChild,
        manager: widget.manager,
        onRemove: handleRemove,
        showConnector: showConnector,
        connectorOperator: connectorOp,
        onOperatorToggle: handleOperatorToggle,
      );
    }

    if (node is FilterCondition) {
      return FilterConditionWidget(
        index: index,
        hasNextChild: hasNextChild,
        condition: node,
        manager: widget.manager,
        onRemove: handleRemove,
        onWrapInGroup: handleWrapInGroup,
        showConnector: showConnector,
        connectorOperator: connectorOp,
        onOperatorToggle: handleOperatorToggle,
      );
    }

    return Container();
  }
}

class _GroupMenuPicker extends StatelessWidget {
  const _GroupMenuPicker({
    required this.group,
    required this.manager,
    required this.onRemove,
    required this.onCollapse,
    required this.onNegate,
  });

  final FilterGroup group;
  final FilterManager manager;
  final VoidCallback onRemove;
  final VoidCallback onCollapse;
  final VoidCallback onNegate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              onNegate();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                !group.isNegated ? '! Negate Group' : '! Remove Negation',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              onCollapse();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const SizedBox(
              width: double.infinity,
              child: Text("Collapse", style: TextStyle(fontSize: 13)),
            ),
          ),
          const Divider(height: 12, thickness: 1),
          TextButton(
            onPressed: () {
              onRemove();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const SizedBox(
              width: double.infinity,
              child: Text(
                "Remove Group",
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
