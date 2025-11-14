import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/global.dart';
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
        prefs.setString('token', token);
        _focusNode.unfocus();
        if (!mounted) return;
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
        padding: const .symmetric(horizontal: 20, vertical: 32),
        decoration: BoxDecoration(
          // color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          children: [
            Text("Enter this command in terminal:"),
            const SizedBox(height: 8),
            Container(
              padding: const .symmetric(horizontal: 8, vertical: 6),
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

            const SizedBox(height: 12),
            // Separator: horizontal line with centered OR pill and labels below
            _OrSeparator(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await MitmproxyClient.startMitm();
                  Navigator.of(context).pop();
                },
                child: const Text("Run MitmProxy"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: [
        Expanded(
          child: Divider(
            thickness: 1,
            color: theme.dividerColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const .symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
            ),
          ),
          child: Text('OR', style: textStyle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(
            thickness: 1,
            color: theme.dividerColor.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
