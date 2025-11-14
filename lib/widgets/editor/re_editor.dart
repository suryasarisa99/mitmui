import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mitmui/services/code_controller_service.dart';
import 'package:mitmui/widgets/editor/context_menu.dart';
import 'package:mitmui/widgets/editor/find.dart';
import 'package:re_editor/re_editor.dart';

// languages
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/graphql.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/protobuf.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';

// themes

// 1. tommorrow-night
// 2. atom-one-dark
// 3. a11y-dark
// 4. monokithems

class ReEditor extends StatefulWidget {
  final String text;

  final CodeControllerService codeControllerService;

  const ReEditor({
    super.key,
    required this.text,
    required this.codeControllerService,
  });

  @override
  State<ReEditor> createState() => _ReEditorState();
}

class _ReEditorState extends State<ReEditor> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.codeControllerService.init(widget.text);
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
    widget.codeControllerService.dispose();
  }

  // late final toolBarController = SelectionToolbarController();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Expanded(
          child: Focus(
            autofocus: false,
            canRequestFocus: false,
            onKeyEvent: (has, e) {
              final hk = HardwareKeyboard.instance;
              if (!widget.codeControllerService.isModified.value) {
                return KeyEventResult.ignored;
              }
              if (e.logicalKey == LogicalKeyboardKey.keyS &&
                  (hk.isMetaPressed || hk.isControlPressed)) {
                widget.codeControllerService.handleSave();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: CodeEditor(
              readOnly: false,
              showCursorWhenReadOnly: true,
              autofocus: false,
              // findController: findController, // Connect the find controller
              controller: widget.codeControllerService.codeController,
              style: CodeEditorStyle(
                fontSize: 16,
                backgroundColor: Colors.transparent,
                codeTheme: CodeHighlightTheme(
                  languages: {
                    'json': CodeHighlightThemeMode(mode: langJson),
                    'javascript': CodeHighlightThemeMode(mode: langJavascript),
                    'css': CodeHighlightThemeMode(mode: langCss),
                    'xml': CodeHighlightThemeMode(mode: langXml),
                    'yaml': CodeHighlightThemeMode(mode: langYaml),
                    'graphql': CodeHighlightThemeMode(mode: langGraphql),
                    'protobuf': CodeHighlightThemeMode(mode: langProtobuf),
                    'markdown': CodeHighlightThemeMode(mode: langMarkdown),
                  },
                  // theme: tomorrowNightTheme,
                  theme: atomOneDarkTheme,
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

              findBuilder: (context, controller, readOnly) =>
                  CodeFindPanelView(controller: controller, readOnly: readOnly),
              // for right click context menu
              toolbarController: const ContextMenuControllerImpl(),

              shortcutOverrideActions: <Type, Action<Intent>>{},
            ),
          ),
        ),
      ],
    );
  }
}
