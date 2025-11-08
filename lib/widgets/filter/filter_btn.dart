import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mitmui/screens/filter_manager.dart';
import 'package:mitmui/widgets/filter/filter_popup.dart';

class FilterBtn extends StatefulWidget {
  const FilterBtn({
    super.key,
    required this.filterManager,
    required this.title,
  });
  final FilterManager filterManager;
  final String title;

  @override
  State<FilterBtn> createState() => _FilterBtnState();
}

class _FilterBtnState extends State<FilterBtn> {
  @override
  void initState() {
    super.initState();
    widget.filterManager.addListener(() {
      setState(() {});
    });
    final hk = HardwareKeyboard.instance;

    final shortCutKey = widget.title == "filter"
        ? LogicalKeyboardKey.keyF
        : LogicalKeyboardKey.keyI;

    // hk.addHandler((event) {
    //   final isCtrlPressed = Platform.isMacOS
    //       ? hk.isMetaPressed
    //       : hk.isControlPressed;
    //   if (event is KeyDownEvent &&
    //       event.logicalKey == shortCutKey &&
    //       isCtrlPressed) {
    //     _showFilterManager();
    //     return true;
    //   }
    //   return false;
    // });
  }

  void _showFilterManager() {
    showDialog(
      context: context,
      builder: (context) {
        return FilterPopup(
          filterManager: widget.filterManager,
          title: widget.title,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final clr = const Color.fromARGB(255, 147, 147, 147);
    final selectedClr = const Color.fromARGB(255, 253, 148, 125);
    return InkWell(
      onTap: _showFilterManager,
      child: SizedBox(
        height: 20,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              width: 0.5,
              color: widget.filterManager.mitmproxyString.isEmpty
                  ? clr
                  : selectedClr,
            ),
          ),
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: 12,
              color: widget.filterManager.mitmproxyString.isEmpty
                  ? clr
                  : selectedClr,
            ),
          ),
        ),
      ),
    );
  }
}
