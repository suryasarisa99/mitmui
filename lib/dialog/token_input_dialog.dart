import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/services/websocket_service.dart';
import 'package:mitmui/theme.dart';

class TokenInputDialog extends StatefulWidget {
  const TokenInputDialog({super.key});

  @override
  State<TokenInputDialog> createState() => _TokenInputDialogState();
}

class _TokenInputDialogState extends State<TokenInputDialog> {
  final TextEditingController _tokenController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void handleSubmit() async {
    final token = _tokenController.text.trim();
    if (token.isNotEmpty) {
      if (await MitmproxyClient.getCookieFromToken(token)) {
        _focusNode.unfocus();
        Navigator.of(context).pop();
      }
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    final command = "mitmweb --web-port 9090 --no-web-open-browser";
    final appTheme = AppTheme.from(Theme.brightnessOf(context));
    return Dialog(
      backgroundColor: appTheme.surfaceBright,
      child: Container(
        width: 450,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        decoration: BoxDecoration(
          // color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter this command in terminal:"),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: appTheme.surfaceDark,
              ),
              child: Row(
                children: [
                  Expanded(child: SelectableText(command)),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: command));
                    },
                    icon: Icon(Icons.copy, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text("Paste the token here:"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tokenController,
                    autofocus: true,
                    onSubmitted: (_) => handleSubmit(),
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your token here',
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                IconButton.filled(
                  iconSize: 20,
                  onPressed: () {
                    handleSubmit();
                    // _focusNode.unfocus();
                    // Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
