import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:mitmui/utils/statusCode.dart';
import 'package:mitmui/widgets/small_icon_btn.dart';

class FlowDetailURL extends StatelessWidget {
  const FlowDetailURL({
    required this.host,
    required this.path,
    required this.statusCode,
    required this.method,
    required this.scheme,
    required this.onOpenInNewWindow,
    super.key,
  });
  final String scheme;
  final String host;
  final String path;
  final int statusCode;
  final String method;
  final Function() onOpenInNewWindow;

  @override
  Widget build(BuildContext context) {
    // separate pathparameters and query parameters from path
    final pathParts = path.split('?');
    final pathWithoutQuery = pathParts[0];
    final queryParameters = pathParts.length > 1 ? '?${pathParts[1]}' : '';
    return Container(
      padding: const EdgeInsets.only(bottom: 10.0, top: 8),
      decoration: BoxDecoration(
        color: Color(0xff161819),
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
          // top: BorderSide(color: Colors.grey[800]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              method,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 208, 208, 208),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          // status code
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 22.0,
              vertical: 2.0,
            ),
            decoration: BoxDecoration(
              color: getStatusCodeColor(statusCode).withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              "$statusCode ${getStatusCodeMessage(statusCode)}",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(width: 8.0),

          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.white),
                children: [
                  TextSpan(
                    text: '$scheme://',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  TextSpan(
                    text: host,
                    style: const TextStyle(color: Color(0xFF3FA9FF)),
                  ),
                  TextSpan(
                    text: pathWithoutQuery,
                    style: const TextStyle(color: Color(0xFF3ADA40)),
                  ),
                  if (queryParameters.isNotEmpty && queryParameters.length < 20)
                    TextSpan(
                      text: queryParameters,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  if (queryParameters.isNotEmpty &&
                      queryParameters.length >= 20)
                    TextSpan(
                      onEnter: (e) {},
                      text: '?...QueryParams',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
          SmIconButton(
            btnSize: 20,
            size: 22,
            icon: Icons.arrow_outward,
            onPressed: onOpenInNewWindow,
          ),
          SizedBox(width: 8.0),
        ],
      ),
    );
  }
}
