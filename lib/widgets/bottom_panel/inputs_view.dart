import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mitmui/widgets/input_items.dart';

class InputsView extends StatelessWidget {
  const InputsView({
    required this.title,
    required this.id,
    required this.items,
    this.enabled,
    required this.onItemToggled,
    required this.onItemReordered,
    required this.onItemChanged,
    required this.onItemAdded,
    required this.keyValueJoiner,
    required this.linesJoiner,
    super.key,
  });

  final String title;
  final String id;
  final List<List<String>> items;
  final List<bool>? enabled;
  final Function(int, bool) onItemToggled;
  final Function(int, int) onItemReordered;
  final Function(int, String, String) onItemChanged;
  final Function(List<String>, int) onItemAdded;
  final String keyValueJoiner;
  final String linesJoiner;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: Icon(Icons.copy, size: 16, color: Colors.grey[400]),
                tooltip: 'Copy all items',
                onPressed: () {
                  final itemText = [
                    for (var (i, item) in items.indexed)
                      if (enabled?[i] ?? true)
                        '${item[0]}$keyValueJoiner${item[1]}',
                  ].join(linesJoiner);

                  Clipboard.setData(ClipboardData(text: itemText));
                },
              ),
            ],
          ),
        ),
        // Items List
        Expanded(
          child: InputItems(
            flowId: id,
            title: title,
            items: items,
            states: enabled,
            onItemToggled: onItemToggled,
            onItemReordered: onItemReordered,
            onItemChanged: onItemChanged,
            onItemAdded: onItemAdded,
          ),
        ),
      ],
    );
  }
}
