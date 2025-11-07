import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mitmui/http_docs.dart';
import 'package:mitmui/widgets/tab_input.dart';

class InputItems extends StatefulWidget {
  final String flowId;
  final List<List<String>> items;
  final List<bool> states;
  final Function(int, bool) onItemToggled;
  final Function(int, int) onItemReordered;
  final Function(int, String, String) onItemChanged;
  final Function(List<String>, int) onItemAdded;
  final String title;
  const InputItems({
    required this.flowId,
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
  late List<List<String>> items = widget.items;
  late List<bool> checked = widget.states;

  @override
  void didUpdateWidget(covariant InputItems oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint("widget update: input_items");
    items = widget.items;
    checked = widget.states;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("rebuilding: InputItems");
    const itemHeight = 40.0;
    return FocusTraversalGroup(
      // child: ReorderableListView.builder(
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 10),
        itemCount: items.length + 1,
        itemExtent: itemHeight,
        // buildDefaultDragHandles: false,
        // onReorder: (oldIndex, newIndex) {
        //   if (oldIndex >= items.length || newIndex > items.length) {
        //     // to prevent reordering the extra row
        //     return;
        //   }
        //   // Don't allow reordering the last empty row
        //   if (oldIndex == items.length - 1 || newIndex == items.length) {
        //     return;
        //   }
        //   widget.onItemReordered(
        //     oldIndex,
        //     newIndex > oldIndex ? newIndex - 1 : newIndex,
        //   );
        // },
        itemBuilder: (context, i) {
          final isExtra = i == items.length;

          return SizedBox(
            // key: ValueKey(i.toString()),
            // key: ValueKey(index.toString() + item[0] + item[1]),
            height: itemHeight,
            // child: Builder(
            //   builder: (context) {
            //     bool isHovered = false;
            //     return StatefulBuilder(
            //       builder: (context, setState) {
            //         return MouseRegion(
            //           onEnter: (_) => setState(() => isHovered = true),
            //           onExit: (_) => setState(() => isHovered = false),
            //           child:
            //         );
            //       },
            //     );
            //   },
            // ),
            child: Row(
              children: [
                // Drag indicator (visible on hover)
                // AnimatedOpacity(
                //   opacity: isHovered ? 1.0 : 0.0,
                //   duration: const Duration(milliseconds: 200),
                //   child: ReorderableDragStartListener(
                //     index: i,
                //     child: Container(
                //       width: 10,
                //       padding: const EdgeInsets.all(0),
                //       child: Icon(
                //         Icons.drag_indicator,
                //         color: Colors.grey[400],
                //         size: 16,
                //       ),
                //     ),
                //   ),
                // ),
                // const SizedBox(width: 8),

                // Checkbox
                if (!isExtra) ...[
                  Transform.scale(
                    scale: 0.87,
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: Focus(
                        autofocus: false,
                        canRequestFocus: false,
                        descendantsAreFocusable: false,
                        child: Checkbox(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: BorderSide(
                            style: BorderStyle.solid,
                            color: Colors.grey[600]!,
                            width: 1,
                          ),
                          fillColor: WidgetStateColor.resolveWith((states) {
                            return checked[i]
                                ? const Color(0xFFFF7474)
                                : const Color.fromARGB(255, 68, 68, 68);
                          }),
                          value: checked[i],
                          onChanged: (value) {
                            widget.onItemToggled(i, value ?? false);
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Info icon for headers
                  if (widget.title.startsWith("Headers")) ...[
                    Tooltip(
                      message: getHeaderDocs(items[i][0])?.summary ?? '',
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ] else
                    SizedBox(width: 8),
                ] else
                  SizedBox(width: 50),

                // Key input field
                SizedBox(width: 180, child: buildInput(i, true)),
                const SizedBox(width: 12),

                // Value input field
                Expanded(child: buildInput(i, false)),
                const SizedBox(width: 8),

                // Copy button
                Focus(
                  autofocus: false,
                  canRequestFocus: false,
                  descendantsAreFocusable: false,
                  child: IconButton(
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildInput(int i, bool isKey) {
    final extra = i == items.length;

    return CustomInput(
      flowId: widget.flowId,
      value: extra ? '' : (isKey ? items[i][0] : items[i][1]),
      isExtra: i == items.length,
      isEnabled: !extra && checked[i],
      onFocusExtraInput: () {
        setState(() {
          items.add(['', '']);
          checked.add(false);
          checked[i] = true;
        });
      },
      onUpdate: (value) {
        if (extra) return;
        debugPrint("updating item at index $i: $value");
        widget.onItemChanged(
          i,
          isKey ? value : items[i][0],
          !isKey ? value : items[i][1],
        );
      },
    );
  }
}
