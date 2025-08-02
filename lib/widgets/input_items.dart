import 'package:flutter/material.dart';
import 'package:mitmui/http_docs.dart';
import 'package:mitmui/widgets/tab_input.dart';

class InputItems extends StatefulWidget {
  final List<List<String>> items;
  final List<bool>? states;
  final Function(int, bool) onItemToggled;
  final Function(int, int) onItemReordered;
  final Function(int, String, String) onItemChanged;
  final Function(List<String>, int) onItemAdded;
  final String title;
  const InputItems({
    required this.title,
    required this.items,
    required this.states,
    required this.onItemToggled,
    required this.onItemReordered,
    required this.onItemChanged,
    required this.onItemAdded,
    super.key,
  });

  @override
  State<InputItems> createState() => _InputItemsState();
}

class _InputItemsState extends State<InputItems> {
  final List<List<String>> displayItems = [];
  final List<({bool enabled, bool extra, FocusNode kf, FocusNode vf})>
  displayStates = [];

  @override
  void initState() {
    displayItems.addAll(widget.items);
    displayStates.addAll(generateEnabledStates());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      addNewRow(true);
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant InputItems oldWidget) {
    super.didUpdateWidget(oldWidget);
    displayItems.clear();
    displayItems.addAll(widget.items);
    displayStates.clear();
    displayStates.addAll(generateEnabledStates());
    addNewRow(true);
    if (oldWidget.items != widget.items || oldWidget.states != widget.states) {
    } else {
      print(
        "No changes in items or states, not updating displayItems or displayStates",
      );
    }
  }

  generateEnabledStates() {
    if (widget.states == null) {
      return List.filled(widget.items.length, (
        enabled: true,
        extra: false,
        kf: FocusNode(),
        vf: FocusNode(),
      ));
    } else {
      return widget.states!.map(
        (s) => (enabled: s, extra: false, kf: FocusNode(), vf: FocusNode()),
      );
    }
  }

  void addNewRow([bool initial = false]) {
    if (!initial) {
      widget.onItemAdded(['', ''], displayItems.length - 1);
    }
    displayItems.add(['', '']);
    displayStates.add((
      enabled: false,
      extra: true,
      kf: FocusNode(),
      vf: FocusNode(),
    ));
  }

  void checkStateAndUpdate(int index) {
    if (displayStates[index].extra && !displayStates[index].enabled) {
      setState(() {
        displayStates[index] = (
          enabled: true,
          extra: false,
          kf: displayStates[index].kf,
          vf: displayStates[index].vf,
        );
        addNewRow();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: EdgeInsets.only(bottom: 10),
      itemCount: displayItems.length,
      itemExtent: 40,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        // Don't allow reordering the last empty row
        if (oldIndex == displayItems.length - 1 ||
            newIndex == displayItems.length) {
          return;
        }
        widget.onItemReordered(
          oldIndex,
          newIndex > oldIndex ? newIndex - 1 : newIndex,
        );
      },
      itemBuilder: (context, index) {
        final item = displayItems[index];
        final isEnabled = displayStates[index].enabled;

        return SizedBox(
          key: ValueKey(index.toString() + item[0] + item[1]),
          height: 40,
          child: MouseRegion(
            onEnter: (_) => {},
            onExit: (_) => {},
            child: Builder(
              builder: (context) {
                bool isHovered = false;
                return StatefulBuilder(
                  builder: (context, setState) {
                    return MouseRegion(
                      onEnter: (_) => setState(() => isHovered = true),
                      onExit: (_) => setState(() => isHovered = false),
                      child: Row(
                        children: [
                          // Drag indicator (visible on hover)
                          AnimatedOpacity(
                            opacity: isHovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: ReorderableDragStartListener(
                              index: index,
                              child: Container(
                                width: 10,
                                padding: const EdgeInsets.all(0),
                                child: Icon(
                                  Icons.drag_indicator,
                                  color: Colors.grey[400],
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Checkbox
                          Transform.scale(
                            scale: 0.87,
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: Checkbox(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: BorderSide(
                                  style: BorderStyle.solid,
                                  color: Colors.grey[600]!,
                                  width: 1,
                                ),
                                fillColor: WidgetStateColor.resolveWith((
                                  states,
                                ) {
                                  return isEnabled
                                      ? const Color(0xFFFF7474)
                                      : const Color.fromARGB(255, 68, 68, 68);
                                }),
                                value: isEnabled,
                                onChanged: (value) {
                                  widget.onItemToggled(index, value ?? false);
                                },
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Info icon for headers
                          if (widget.title.startsWith("Headers")) ...[
                            Tooltip(
                              message: getHeaderDocs(item[0])?.summary ?? '',
                              child: Icon(
                                Icons.info_outline,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],

                          // Key input field
                          SizedBox(
                            width: 180,
                            child: buildInput(isEnabled, index, true),
                          ),
                          const SizedBox(width: 12),

                          // Value input field
                          Expanded(child: buildInput(isEnabled, index, false)),
                          const SizedBox(width: 8),

                          // Copy button
                          IconButton(
                            icon: const Icon(
                              Icons.content_copy,
                              size: 14,
                              color: Colors.grey,
                            ),
                            tooltip: 'Copy item',
                            onPressed: () {
                              // Clipboard.setData(
                              //   ClipboardData(
                              //     text: '${item[0]}$keyValueJoiner${item[1]}',
                              //   ),
                              // );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget buildInput(bool isEnabled, int index, bool isKey) {
    final item = displayItems[index];
    final state = displayStates[index];

    return CustomInput(
      value: isKey ? item[0] : item[1],
      focusNode: isKey ? state.kf : state.vf,
      onFieldSubmitted: (value) {
        widget.onItemChanged(index, item[0], item[1]);
      },
      // onChanged: (value) {
      //   if (isKey) {
      //     widget.onItemChanged(index, value, item[1]);
      //   } else {
      //     widget.onItemChanged(index, item[0], value);
      //   }
      // },
      onTap: () {
        checkStateAndUpdate(index);
      },
      onTapOutside: (v) {
        if (!state.extra) {
          widget.onItemChanged(index, isKey ? v : item[0], isKey ? item[1] : v);
        }
      },
      onTab: (v) {
        if (index < displayItems.length - 1) {
          print("Moving focus to next item");
          // displayStates[index + 1].focusNode.requestFocus();
          if (isKey) {
            state.vf.requestFocus();
          } else {
            // widget.onItemChanged(index, item[0], item[1]);
            if (index + 1 < displayItems.length) {
              // Move focus to the next item
              final nextState = displayStates[index + 1];
              nextState.kf.requestFocus();
              if (nextState.extra) checkStateAndUpdate(index + 1);
            }
          }
        }
        checkStateAndUpdate(index);
        if (!state.extra) {
          widget.onItemChanged(index, isKey ? v : item[0], isKey ? item[1] : v);
        }
      },
    );
  }
}
