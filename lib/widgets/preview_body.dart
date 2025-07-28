import 'dart:convert';
import 'package:flutter_svg/svg.dart';
import 'package:mitmui/models/flow.dart' as models;

import 'package:flutter/material.dart';
import 'package:mitmui/models/response_body.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/widgets/re_editor.dart';
import 'package:mitmui/utils/logger.dart';

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
    final urlWithoutQuery = Uri.parse(url).resolve('').toString();

    return FutureBuilder(
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
          if (contentType.contains("image") && contentType.contains("svg")) {
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
          } else if (mitmBody.viewName == "JSON" ||
              contentType.contains('json') ||
              contentType.contains('x-sentry-envelope')) {
            final formattedJson = JsonEncoder.withIndent(
              '  ',
            ).convert(jsonDecode(mitmBody.text));
            return ReEditor(text: formattedJson, lang: 'json');
          } else if (mitmBody.viewName == 'HTML' ||
              contentType.contains('html') ||
              mitmBody.viewName == 'XML' ||
              contentType.contains('xml') ||
              mitmBody.viewName == 'XHTML' ||
              contentType.contains('xhtml')) {
            return ReEditor(text: mitmBody.text, lang: 'xml');
          } else if (mitmBody.viewName == 'JavaScript' ||
              contentType.contains('javascript')) {
            return ReEditor(text: mitmBody.text, lang: 'javascript');
          } else if (mitmBody.viewName == 'Css' ||
              contentType.contains('css')) {
            return ReEditor(text: mitmBody.text, lang: 'css');
          } else {
            return ReEditor(text: mitmBody.text, lang: 'text');
          }
        }
      },
    );
  }
}
