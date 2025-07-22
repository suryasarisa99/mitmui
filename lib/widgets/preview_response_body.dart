import 'dart:convert';
import 'dart:typed_data';
import 'package:mitmui/models/flow.dart' as models;

import 'package:flutter/material.dart';
import 'package:mitmui/models/response_body.dart';
import 'package:mitmui/api/mitmproxy_client.dart';

class PreviewResponseBody extends StatelessWidget {
  const PreviewResponseBody({
    super.key,
    required this.response,
    required this.responseBodyFuture,
    this.responseDataFuture,
    this.flowId,
  });

  final models.HttpResponse response;
  final Future<MitmBody>? responseBodyFuture;
  final Future<dynamic>? responseDataFuture;
  final String? flowId; // Flow ID for API calls

  @override
  Widget build(BuildContext context) {
    final hasContent =
        response.contentLength != null && response.contentLength! > 0;

    if (!hasContent) {
      return const Center(child: Text('No content to preview'));
    }

    // Determine content type from headers
    final contentType = response.contentType ?? '';

    return FutureBuilder(
      future: Future.wait([responseBodyFuture!, responseDataFuture!]),

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
            (snapshot.data![0] as MitmBody).text.isEmpty) {
          return const Center(child: Text('No content to display'));
        } else {
          final result = snapshot.data!;
          final mitmBody = result[0] as MitmBody;
          final contentData = result[1];
          print(
            "mitmBody.viewName: ${mitmBody.viewName}, ${mitmBody.syntaxHighlight}, ${mitmBody.viewName}",
          );
          print("content:${contentData}");
          if (mitmBody.viewName == "Image" || contentType.contains('image')) {
            // Get the URL directly from the server for the image
            final String imageUrl =
                '$baseUrl/flows/$flowId/response/content.data';
            print("Loading image from URL: $imageUrl");

            return Image.network(
              imageUrl,
              fit: BoxFit.contain,
              headers: {'Cookie': cookieHeader, 'Referer': baseUrl},
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
                print("Error loading image: $error");
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
          } else if (mitmBody.viewName == "JSON") {
            final jsonObj = json.decode(mitmBody.text);
            final prettyJson = const JsonEncoder.withIndent(
              '  ',
            ).convert(jsonObj);
            return SelectableText(
              prettyJson,
              style: const TextStyle(fontFamily: 'monospace'),
            );
          } else {
            return SelectableText(
              mitmBody.text,
              style: const TextStyle(fontFamily: 'monospace'),
            );
          }
        }
      },
    );

    //   try {
    //     if (contentType.contains('json')) {
    //       // Pretty print JSON (in a real app, this would be the actual JSON content)
    //       final jsonObj = json.decode(
    //         '{"message": "This is a placeholder for JSON content"}',
    //       );
    //       final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonObj);

    //       contentWidget = SelectableText(
    //         prettyJson,
    //         style: const TextStyle(fontFamily: 'monospace'),
    //       );
    //     } else if (contentType.contains('html')) {
    //       // Display HTML content with some formatting
    //       contentWidget = Column(
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [
    //           const Text(
    //             'HTML content would be displayed here with formatting.',
    //             style: TextStyle(fontStyle: FontStyle.italic),
    //           ),
    //           const SizedBox(height: 8),
    //           SelectableText(content),
    //         ],
    //       );
    //     } else if (contentType.contains('xml')) {
    //       // Display XML as is for now
    //       contentWidget = SelectableText(
    //         content,
    //         style: const TextStyle(fontFamily: 'monospace'),
    //       );
    //     } else if (contentType.contains('image')) {
    //       // Show image placeholder
    //       contentWidget = Column(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: [
    //           const Icon(Icons.image, size: 48, color: Colors.grey),
    //           const SizedBox(height: 16),
    //           Text(
    //             'Image content (${contentType.split(';')[0]})',
    //             style: const TextStyle(color: Colors.grey),
    //           ),
    //         ],
    //       );
    //     } else {
    //       // Default fallback
    //       contentWidget = SelectableText(content);
    //     }
    //   } catch (e) {
    //     // If any formatting fails, show the raw content
    //     contentWidget = Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Text(
    //           'Error formatting content: $e',
    //           style: const TextStyle(color: Colors.red),
    //         ),
    //         const SizedBox(height: 8),
    //         Expanded(child: SelectableText(content)),
    //       ],
    //     );
    //   }

    //   return Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Text(
    //         'Content Preview (${contentType.split(';')[0]}):',
    //         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    //       ),
    //       const SizedBox(height: 8),
    //       Expanded(
    //         child: Container(
    //           decoration: BoxDecoration(
    //             color: const Color.fromARGB(255, 35, 36, 42),
    //             borderRadius: BorderRadius.circular(4),
    //           ),
    //           padding: const EdgeInsets.all(8.0),
    //           child: contentWidget,
    //         ),
    //       ),
    //     ],
    //   );
  }
}
