import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/tomorrow-night.dart';
import 'package:mitmui/widgets/small_icon_btn.dart';
import 'package:re_editor/re_editor.dart';

// languages
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/xml.dart';

// themes
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/tomorrow-night.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/night-owl.dart';
import 'package:flutter_highlight/themes/nord.dart';

// 1. tommorrow-night
// 2. atom-one-dark
// 3. a11y-dark
// 4. monokithems

class ReEditor extends StatefulWidget {
  final String text;
  final String lang;
  const ReEditor({super.key, required this.text, required this.lang});

  @override
  State<ReEditor> createState() => _ReEditorState();
}

class _ReEditorState extends State<ReEditor> {
  final TextEditingController searchController = TextEditingController();
  late final codeController = CodeLineEditingController.fromText(widget.text);
  // late final CodeFindController findController = CodeFindController(
  //   codeController,
  //   CodeFindValue(
  //     replaceMode: false,
  //     searching: true,
  //     option: CodeFindOption(pattern: '', caseSensitive: true, regex: false),
  //   ),
  // );
  bool findPanelVisible = true;

  @override
  void dispose() {
    codeController.dispose();
    // findController.dispose();
    super.dispose();
  }

  // late final toolBarController = SelectionToolbarController();
  @override
  Widget build(BuildContext context) {
    return CodeEditor(
      readOnly: true,
      showCursorWhenReadOnly: true,
      autofocus: false,

      // findController: findController,
      controller: codeController,
      style: CodeEditorStyle(
        fontSize: 16,
        backgroundColor: Colors.transparent,
        codeTheme: CodeHighlightTheme(
          languages: {
            // 'json': CodeHighlightThemeMode(mode: langJson),
            // 'javascript': CodeHighlightThemeMode(mode: langJavascript),
            'css': CodeHighlightThemeMode(mode: langCss),
            // 'xml': CodeHighlightThemeMode(mode: langXml),
          },
          theme: tomorrowNightTheme,
        ),
      ),

      // for line numbers and chunk indicators
      indicatorBuilder:
          (context, editingController, chunkController, notifier) {
            return Row(
              children: [
                DefaultCodeLineNumber(
                  controller: editingController,
                  notifier: notifier,
                ),
                DefaultCodeChunkIndicator(
                  width: 20,
                  controller: chunkController,
                  notifier: notifier,
                ),
              ],
            );
          },

      // for search functionality
      // findBuilder: findPanelVisible
      //     ? (context, controller, readOnly) => CodeFindPanel(
      //         controller: controller,
      //         readOnly: readOnly,
      //         onClose: () {
      //           setState(() {
      //             findPanelVisible = false;
      //           });
      //         },
      //       )
      //     : null,

      // findBuilder: (context, controller, readOnly) => CodeFindPanel(
      //   controller: controller,
      //   readOnly: readOnly,
      //   onClose: () {
      //     setState(() {
      //       findPanelVisible = false;
      //     });
      //   },
      // ),

      // for right click context menu
      // toolbarController:
    );
  }
}

/// make this preffered size widget

/// A custom widget for the find panel UI.
class CodeFindPanel extends StatefulWidget implements PreferredSizeWidget {
  final CodeFindController controller;
  final bool readOnly;
  final VoidCallback onClose;

  const CodeFindPanel({
    super.key,
    required this.controller,
    required this.readOnly,
    required this.onClose,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48.0);

  @override
  State<CodeFindPanel> createState() => _CodeFindPanelState();
}

class _CodeFindPanelState extends State<CodeFindPanel> {
  late final TextEditingController _searchController =
      widget.controller.findInputController;

  @override
  void initState() {
    super.initState();
    // Listen to the find controller to rebuild the UI when matches change.
    widget.controller.addListener(_onFindControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onFindControllerChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onFindControllerChanged() {
    // Rebuild the widget to show updated match count, etc.
    if (mounted) {
      // setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = widget.controller.value;
    final matches = value?.result?.matches ?? [];
    final hasMatches = matches.isNotEmpty;
    final currentIndex = hasMatches ? value?.result?.index ?? 0 : 0;
    final totalMatches = matches.length;

    return Positioned(
      right: 5,
      top: 2,
      child: Container(
        width: 400,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8.0),
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The search input field
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Find',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            // Display for match count (e.g., "1 / 5")
            if (_searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('$currentIndex / $totalMatches'),
              ),
            // Button to go to the previous match
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              onPressed: hasMatches ? widget.controller.previousMatch : null,
              tooltip: 'Previous Match',
              iconSize: 20,
            ),
            // Button to go to the next match
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              onPressed: hasMatches ? widget.controller.nextMatch : null,
              tooltip: 'Next Match',
              iconSize: 20,
            ),

            // Button to close the find panel
            SmIconButton(
              icon: Icons.abc,
              color: widget.controller.value?.option.caseSensitive ?? false
                  ? Colors.white
                  : Colors.grey,
              onPressed: () {
                widget.controller.toggleCaseSensitive();
              },
            ),
            SmIconButton(
              icon: Icons.code,
              size: 18,
              color: widget.controller.value?.option.regex ?? false
                  ? Colors.white
                  : Colors.grey,
              onPressed: () {
                widget.controller.toggleRegex();
              },
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                // Use the controller to hide the panel
                // widget.controller.close();
                widget.controller.close();
                widget.onClose();
              },
              tooltip: 'Close',
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }
}
