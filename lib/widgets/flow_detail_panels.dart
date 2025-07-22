import 'package:flutter/material.dart';

import '../models/flow.dart' as models;
import 'flow_data_source.dart';

class RequestPanel extends StatelessWidget {
  final models.Flow? flow;
  final FlowDataSource dataSource;

  const RequestPanel({super.key, required this.flow, required this.dataSource});

  @override
  Widget build(BuildContext context) {
    if (flow == null) {
      return const Center(child: Text('Select a flow to view details'));
    }

    final request = flow!.request;

    return Container(
      color: const Color.fromARGB(255, 25, 26, 32),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Request summary title
          Text(
            'Request',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: dataSource.getMethodColor(request.method),
            ),
          ),
          const SizedBox(height: 12),

          // Request URL
          Text(
            'URL: ${request.url}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          // Request method and HTTP version
          Text(
            'Method: ${request.method} (HTTP/${request.httpVersion})',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          // Content length if available
          if (request.contentLength != null)
            Text(
              'Content Length: ${dataSource.formatBytes(request.contentLength!)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          const SizedBox(height: 16),

          // Headers section
          const Text(
            'Headers:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Headers list
          Expanded(
            child: ListView.builder(
              itemCount: request.headers.length,
              itemBuilder: (context, index) {
                final header = request.headers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14),
                      children: [
                        TextSpan(
                          text: '${header[0]}: ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 174, 185, 252),
                          ),
                        ),
                        TextSpan(
                          text: header[1],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ResponsePanel extends StatelessWidget {
  final models.Flow? flow;
  final FlowDataSource dataSource;

  const ResponsePanel({
    super.key,
    required this.flow,
    required this.dataSource,
  });

  @override
  Widget build(BuildContext context) {
    if (flow == null) {
      return const Center(child: Text('Select a flow to view details'));
    }

    final response = flow!.response;

    if (response == null) {
      return const Center(
        child: Text(
          'No response available',
          style: TextStyle(color: Colors.orange),
        ),
      );
    }

    final statusColor = dataSource.getStatusColor(response.statusCode);

    return Container(
      color: const Color.fromARGB(255, 25, 26, 32),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Response summary title with status code
          Row(
            children: [
              const Text(
                'Response',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${response.statusCode} ${response.reason}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // HTTP version
          Text(
            'HTTP Version: ${response.httpVersion}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          // Content type if available
          if (response.contentType != null)
            Text(
              'Content Type: ${response.contentType}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          const SizedBox(height: 8),

          // Content length if available
          if (response.contentLength != null)
            Text(
              'Content Length: ${dataSource.formatBytes(response.contentLength!)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          const SizedBox(height: 16),

          // Headers section
          const Text(
            'Headers:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Headers list
          Expanded(
            child: ListView.builder(
              itemCount: response.headers.length,
              itemBuilder: (context, index) {
                final header = response.headers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14),
                      children: [
                        TextSpan(
                          text: '${header[0]}: ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 174, 185, 252),
                          ),
                        ),
                        TextSpan(
                          text: header[1],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
