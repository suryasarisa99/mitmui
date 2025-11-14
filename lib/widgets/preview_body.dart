import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'package:flutter/material.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/services/mitm_body_service.dart';
import 'package:mitmui/store/derrived_flows_provider.dart';
import 'package:mitmui/services/code_controller_service.dart';
import 'package:mitmui/widgets/editor/re_editor.dart';
import 'package:mitmui/utils/logger.dart';

const _log = Logger("preview_body");

/*
- instead of ref.watch(), it uses ref.listenManual to control when to rebuild.
- so when the tab is not active, it still listens to changes but doesn't rebuild, sets a flag to indicate pending update.
- when the tab becomes active again, if there was a pending update, it rebuilds.
- so only rebuilds when active.
- and also this wrapped keepAliveWrapper widget in parent.
- all these are for response body  bcz its response depends on request details, but request body doesn't change rather we manually edit it.
*/
class PreviewBody extends ConsumerStatefulWidget {
  const PreviewBody({
    super.key,
    required this.id,
    required this.type,
    required this.codeControllerService,
    required this.mitmBodyService,
  });

  final String id;
  final String type;
  final CodeControllerService codeControllerService;
  final MitmBodyService mitmBodyService;

  @override
  ConsumerState<PreviewBody> createState() => PreviewBodyState();
}

class PreviewBodyState extends ConsumerState<PreviewBody> {
  // Manual subscription management
  ProviderSubscription<(double?,)>? _timestampSubscription;

  // Cache the last values
  (double?,)? _cachedTimestamp;
  String? _contentType;
  String? _url;
  bool? _isLoading = false;

  // Control rebuild behavior
  bool _isActive = true; // Whether tab is currently visible
  bool _hasPendingUpdate = false; // Whether data changed while inactive

  @override
  void initState() {
    super.initState();
    _startListening();
    widget.mitmBodyService.reloadBody();
  }

  void _startListening() {
    if (widget.type == "request") return;
    if (_timestampSubscription != null) return; // Already listening

    // Subscribe to timestamp changes
    _timestampSubscription = ref.listenManual(
      flowProvider(widget.id).select((f) => (f?.response?.timestampEnd,)),
      (previous, next) {
        _cachedTimestamp = next;
        if (next.$1 == null) {
          if (_isActive) {
            setState(() {
              _isLoading = true;
            });
          }
          _log.info("Content-Type is null for flow id: ${widget.id}");
        } else {
          _onDataChanged();
        }
      },
      fireImmediately: true,
    );
  }

  void _onDataChanged() {
    widget.mitmBodyService.reloadBody();
    debugPrint("data changed for flow id: ${widget.id}");
    if (_isActive && mounted) {
      setState(() {
        _isLoading = false;
        _url = ref
            .read(flowProvider(widget.id))
            ?.request
            ?.url; // update cached URL here
        _contentType = ref
            .read(responseHeadersProvider(widget.id))
            ?.firstWhereOrNull(
              (header) => header[0].toLowerCase() == 'content-type',
            )?[1]; // update cached content type here
      });
    } else {
      _hasPendingUpdate = true;
    }
  }

  void _stopListening() {
    _timestampSubscription?.close();
    _timestampSubscription = null;
  }

  // Public methods to control rebuild behavior from parent
  void pauseListening() {
    _isActive = false;
    // it listens, but doesn't rebuild
    // Don't stop subscriptions - keep listening for changes
  }

  void resumeListening() {
    _isActive = true;
    // If data changed while inactive, rebuild now
    if (_hasPendingUpdate && mounted) {
      _hasPendingUpdate = false;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void didUpdateWidget(PreviewBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the flow ID changed, restart subscriptions with new ID
    if (oldWidget.id != widget.id) {
      debugPrint(
        "PreviewBody: Flow ID changed from ${oldWidget.id} to ${widget.id}",
      );
      _stopListening();
      _cachedTimestamp = null;
      _contentType = null;
      _url = null;
      _hasPendingUpdate = false;
      _startListening();
    }
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentType = _contentType;
    final url = _url ?? '';

    final urlWithoutQuery = Uri.parse(url).resolve('').toString();
    debugPrint("Building PreviewBody for flow id: ${widget.id}");

    if (_isLoading == true) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder(
      future: widget.mitmBodyService.getMitmBody(),
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
        } else {
          final mitmBody = snapshot.data!;
          if (mitmBody.viewName == "Query") {
            return const Center(child: Text("No content to Preview"));
          }
          _log.info(
            "mitmBody.viewName: ${mitmBody.viewName}, ${mitmBody.syntaxHighlight}",
          );
          if (contentType == null) {
            return ReEditor(
              text: mitmBody.text,
              codeControllerService: widget.codeControllerService,
            );
          }
          if (contentType.contains("image") && contentType.contains("svg")) {
            return SvgPicture.string(mitmBody.text);
          } else if (mitmBody.viewName == "Image" ||
              contentType.contains('image') ||
              urlWithoutQuery.endsWith(".webp")) {
            // Get the URL directly from the server for the image
            final String imageUrl =
                '${MitmproxyClient.baseUrl}/flows/${widget.id}/response/content.data';
            return Image.network(
              imageUrl,
              headers: {
                'Cookie': MitmproxyClient.cookies,
                'Referer': MitmproxyClient.baseUrl,
              },
              fit: BoxFit.contain,
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
                    mainAxisAlignment: .center,
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
            try {
              final formattedJson = JsonEncoder.withIndent(
                '  ',
              ).convert(jsonDecode(mitmBody.text));
              return ReEditor(
                text: formattedJson,
                codeControllerService: widget.codeControllerService,
              );
            } catch (e) {
              return ReEditor(
                text: mitmBody.text,
                codeControllerService: widget.codeControllerService,
              );
            }
          } else {
            return ReEditor(
              text: mitmBody.text,
              codeControllerService: widget.codeControllerService,
            );
          }
        }
      },
    );
  }
}
