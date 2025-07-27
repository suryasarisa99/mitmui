import 'dart:convert';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/mono-blue.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mitmui/models/flow.dart' as models;

import 'package:flutter/material.dart';
import 'package:mitmui/models/response_body.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/css.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/tomorrow-night.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/paraiso-dark.dart';
import 'package:flutter_highlight/themes/night-owl.dart';
import 'package:flutter_highlight/themes/nord.dart';

// 1. tommorrow-night
// 2. atom-one-dark
// 3. a11y-dark
// 4. monokithems
const _log = Logger("preview_body");

class PreviewBody extends StatelessWidget {
  const PreviewBody({
    super.key,
    required this.bodyFuture,
    required this.contentType,
    required this.contentLength,
    // this.dataFuture,
    this.flowId,
    required this.url,
  });

  final String? contentType;
  final int? contentLength;
  final Future<MitmBody>? bodyFuture;
  // final Future<dynamic>? dataFuture;
  final String url;
  final String? flowId; // Flow ID for API calls

  @override
  Widget build(BuildContext context) {
    final hasContent = contentLength != null && (contentLength ?? 0) > 0;

    if (!hasContent) {
      return const Center(child: Text('No content to preview 1'));
    }

    // Determine content type from headers
    final contentType = this.contentType ?? '';
    final theme = tomorrowNightTheme;
    final urlWithoutQuery = Uri.parse(url).resolve('').toString();

    return Column(
      children: [
        FutureBuilder(
          future: bodyFuture,
          builder: (content, snapshot) {
            return Text(
              "viewName: ${snapshot.data?.viewName ?? 'Unknown'}, contentType: $contentType",
            );
          },
        ),
        Expanded(
          child: FutureBuilder(
            future: bodyFuture,

            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error fetching body: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              } else if (!snapshot.hasData ||
                  (snapshot.data?.text.isEmpty ?? false)) {
                return const Center(child: Text('No content to Preview 2'));
              } else {
                final mitmBody = snapshot.data!;
                if (mitmBody.viewName == "Query") {
                  return const Center(child: Text("No content to Preview 3"));
                }
                _log.info(
                  "mitmBody.viewName: ${mitmBody.viewName}, ${mitmBody.syntaxHighlight}, ${mitmBody.viewName}",
                );
                if (contentType.contains("image") &&
                    contentType.contains("svg")) {
                  return SvgPicture.string(mitmBody.text);
                } else if (mitmBody.viewName == "Image" ||
                    contentType.contains('image') ||
                    urlWithoutQuery.endsWith(".webp")) {
                  // Get the URL directly from the server for the image
                  final String imageUrl =
                      '${MitmproxyClient.baseUrl}/flows/$flowId/response/content.data';
                  return Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    headers: {
                      'Cookie': MitmproxyClient.cookies,
                      'Referer': MitmproxyClient.baseUrl,
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      _log.error("Error loading image: $error");
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load image: ${error.toString()}',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else if (mitmBody.viewName == "Text") {
                  return SelectableText(
                    mitmBody.text,
                    style: const TextStyle(fontFamily: 'monospace'),
                  );
                } else if (mitmBody.viewName == "JSON" ||
                    contentType.contains('json') ||
                    contentType.contains('x-sentry-envelope')) {
                  return CodeTheme(
                    data: CodeThemeData(styles: theme),
                    child: SingleChildScrollView(
                      child: CodeField(
                        controller: CodeController(
                          readOnly: true,
                          text: mitmBody.text,
                          language: json,
                        ),
                      ),
                    ),
                  );
                } else if (mitmBody.viewName == 'HTML' ||
                    contentType.contains('html') ||
                    mitmBody.viewName == 'XML' ||
                    contentType.contains('xml') ||
                    mitmBody.viewName == 'XHTML' ||
                    contentType.contains('xhtml')) {
                  return CodeTheme(
                    data: CodeThemeData(styles: theme),
                    child: SingleChildScrollView(
                      child: CodeField(
                        controller: CodeController(
                          readOnly: true,
                          text: mitmBody.text.trim(),
                          language: xml,
                        ),
                      ),
                    ),
                  );
                } else if (mitmBody.viewName == 'JavaScript' ||
                    contentType.contains('javascript')) {
                  return CodeTheme(
                    data: CodeThemeData(styles: theme),
                    child: SingleChildScrollView(
                      child: CodeField(
                        controller: CodeController(
                          readOnly: true,
                          text: mitmBody.text,
                          language: javascript,
                        ),
                      ),
                    ),
                  );
                } else if (mitmBody.viewName == 'Css' ||
                    contentType.contains('css')) {
                  return CodeTheme(
                    data: CodeThemeData(styles: theme),
                    child: SingleChildScrollView(
                      child: CodeField(
                        onChanged: (text) {
                          _log.debug('Code changed: $text');
                        },
                        background: Colors.transparent,
                        controller: CodeController(
                          readOnly: true,
                          text: mitmBody.text,
                          language: css,
                        ),
                      ),
                    ),
                  );
                } else {
                  return SelectableText(
                    mitmBody.text,
                    style: const TextStyle(fontFamily: 'monospace'),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }
}
