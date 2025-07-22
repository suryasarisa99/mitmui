// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// import '../models/flow.dart' as models;
// import 'flow_data_source.dart';

// class RequestPanel extends StatefulWidget {
//   final models.Flow? flow;
//   final FlowDataSource dataSource;

//   const RequestPanel({super.key, required this.flow, required this.dataSource});

//   @override
//   State<RequestPanel> createState() => _RequestPanelState();
// }

// class _RequestPanelState extends State<RequestPanel>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 5, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   // Headers tab content
//   Widget _buildHeadersView(models.HttpRequest request) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               'Headers:',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//             IconButton(
//               icon: const Icon(Icons.copy, size: 16),
//               tooltip: 'Copy all headers',
//               onPressed: () {
//                 // Convert headers to a copyable format
//                 final headerText = request.headers
//                     .map((h) => '${h[0]}: ${h[1]}')
//                     .join('\n');
//                 Clipboard.setData(ClipboardData(text: headerText));
//               },
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),

//         // Headers list with selectable text
//         Expanded(
//           child: ListView.builder(
//             itemCount: request.headers.length,
//             itemBuilder: (context, index) {
//               final header = request.headers[index];
//               return Card(
//                 margin: const EdgeInsets.symmetric(vertical: 2),
//                 color: const Color.fromARGB(255, 35, 36, 42),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     vertical: 4.0,
//                     horizontal: 8.0,
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: SelectableText.rich(
//                           TextSpan(
//                             style: const TextStyle(fontSize: 14),
//                             children: [
//                               TextSpan(
//                                 text: '${header[0]}: ',
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                   color: Color.fromARGB(255, 174, 185, 252),
//                                 ),
//                               ),
//                               TextSpan(
//                                 text: header[1],
//                                 style: const TextStyle(color: Colors.white),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.content_copy, size: 14),
//                         tooltip: 'Copy header',
//                         onPressed: () {
//                           Clipboard.setData(
//                             ClipboardData(text: '${header[0]}: ${header[1]}'),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   // Body tab content
//   Widget _buildBodyView(models.HttpRequest request) {
//     final hasContent =
//         request.contentLength != null && request.contentLength! > 0;

//     if (!hasContent) {
//       return const Center(child: Text('No request body'));
//     }

//     // For now, we'll use a placeholder since the actual content isn't available
//     // In a real implementation, you would fetch the content from mitmproxy
//     final String content =
//         "[Request body content not available in the model. You would need to fetch this from mitmproxy API]";

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               'Request Body:',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//             IconButton(
//               icon: const Icon(Icons.copy, size: 16),
//               tooltip: 'Copy body',
//               onPressed: () {
//                 Clipboard.setData(ClipboardData(text: content));
               
//               },
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),

//         // Body content in a scrollable, selectable container
//         Expanded(
//           child: Container(
//             decoration: BoxDecoration(
//               color: const Color.fromARGB(255, 35, 36, 42),
//               borderRadius: BorderRadius.circular(4),
//             ),
//             padding: const EdgeInsets.all(8.0),
//             child: SelectableText(
//               content,
//               style: const TextStyle(fontFamily: 'monospace'),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Query Parameters tab content
//   Widget _buildQueryParamsView(models.HttpRequest request) {
//     // Extract query parameters from URL
//     final uri = Uri.parse(request.url);
//     final queryParams = uri.queryParameters;

//     if (queryParams.isEmpty) {
//       return const Center(child: Text('No query parameters'));
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               'Query Parameters:',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//             IconButton(
//               icon: const Icon(Icons.copy, size: 16),
//               tooltip: 'Copy all parameters',
//               onPressed: () {
//                 // Convert parameters to a copyable format
//                 final paramText = queryParams.entries
//                     .map((e) => '${e.key}: ${e.value}')
//                     .join('\n');
//                 Clipboard.setData(ClipboardData(text: paramText));
//               },
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),

//         // Parameters list with selectable text
//         Expanded(
//           child: ListView.builder(
//             itemCount: queryParams.length,
//             itemBuilder: (context, index) {
//               final entry = queryParams.entries.elementAt(index);
//               return Card(
//                 margin: const EdgeInsets.symmetric(vertical: 2),
//                 color: const Color.fromARGB(255, 35, 36, 42),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     vertical: 4.0,
//                     horizontal: 8.0,
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: SelectableText.rich(
//                           TextSpan(
//                             style: const TextStyle(fontSize: 14),
//                             children: [
//                               TextSpan(
//                                 text: '${entry.key}: ',
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                   color: Color.fromARGB(255, 174, 185, 252),
//                                 ),
//                               ),
//                               TextSpan(
//                                 text: entry.value,
//                                 style: const TextStyle(color: Colors.white),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.content_copy, size: 14),
//                         tooltip: 'Copy parameter',
//                         onPressed: () {
//                           Clipboard.setData(
//                             ClipboardData(text: '${entry.key}: ${entry.value}'),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   // Cookies tab content
//   Widget _buildCookiesView(models.HttpRequest request) {
//     // Find Cookie header
//     final cookieHeader = request.headers.firstWhere(
//       (header) => header[0].toLowerCase() == 'cookie',
//       orElse: () => ['cookie', ''],
//     )[1];

//     if (cookieHeader.isEmpty) {
//       return const Center(child: Text('No cookies in request'));
//     }

//     // Parse cookies
//     final cookies = <Map<String, String>>[];
//     for (final cookie in cookieHeader.split(';')) {
//       if (cookie.trim().isNotEmpty) {
//         final parts = cookie.split('=');
//         final name = parts[0].trim();
//         final value = parts.length > 1 ? parts.sublist(1).join('=').trim() : '';
//         cookies.add({'name': name, 'value': value});
//       }
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               'Cookies:',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//             IconButton(
//               icon: const Icon(Icons.copy, size: 16),
//               tooltip: 'Copy all cookies',
//               onPressed: () {
//                 // Convert cookies to a copyable format
//                 final cookieText = cookies
//                     .map((c) => '${c['name']}: ${c['value']}')
//                     .join('\n');
//                 Clipboard.setData(ClipboardData(text: cookieText));
//               },
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),

//         // Cookies list with selectable text
//         Expanded(
//           child: ListView.builder(
//             itemCount: cookies.length,
//             itemBuilder: (context, index) {
//               final cookie = cookies[index];
//               return Card(
//                 margin: const EdgeInsets.symmetric(vertical: 2),
//                 color: const Color.fromARGB(255, 35, 36, 42),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     vertical: 4.0,
//                     horizontal: 8.0,
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: SelectableText.rich(
//                           TextSpan(
//                             style: const TextStyle(fontSize: 14),
//                             children: [
//                               TextSpan(
//                                 text: '${cookie['name']}: ',
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                   color: Color.fromARGB(255, 174, 185, 252),
//                                 ),
//                               ),
//                               TextSpan(
//                                 text: cookie['value'] ?? '',
//                                 style: const TextStyle(color: Colors.white),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.content_copy, size: 14),
//                         tooltip: 'Copy cookie',
//                         onPressed: () {
//                           Clipboard.setData(
//                             ClipboardData(
//                               text: '${cookie['name']}: ${cookie['value']}',
//                             ),
//                           );
                        
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   // Pretty/Preview tab content
//   Widget _buildPreviewView(models.HttpRequest request) {
//     final hasContent =
//         request.contentLength != null && request.contentLength! > 0;

//     if (!hasContent) {
//       return const Center(child: Text('No content to preview'));
//     }

//     // For now, we'll use a placeholder since the actual content isn't available
//     // In a real implementation, you would fetch the content from mitmproxy
//     final String content =
//         "[Request body content not available in the model. You would need to fetch this from mitmproxy API]";

//     final contentType = request.getHeader('content-type') ?? '';

//     // Try to format the content based on content type
//     Widget contentWidget;

//     try {
//       if (contentType.contains('json')) {
//         // Pretty print JSON
//         final jsonObj = json.decode(
//           '{"message": "This is a placeholder for JSON content"}',
//         );
//         final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonObj);

//         contentWidget = SelectableText(
//           prettyJson,
//           style: const TextStyle(fontFamily: 'monospace'),
//         );
//       } else if (contentType.contains('xml') ||
//           content.trim().startsWith('<')) {
//         // Display XML as is for now (could add XML formatting later)
//         contentWidget = SelectableText(
//           content,
//           style: const TextStyle(fontFamily: 'monospace'),
//         );
//       } else if (contentType.contains('form')) {
//         // Format form data for better readability
//         final formItems = content.split('&');
//         contentWidget = ListView.builder(
//           itemCount: formItems.length,
//           itemBuilder: (context, index) {
//             final item = formItems[index];
//             final parts = item.split('=');
//             final key = parts[0];
//             final value = parts.length > 1 ? Uri.decodeComponent(parts[1]) : '';

//             return Card(
//               margin: const EdgeInsets.symmetric(vertical: 4),
//               color: const Color.fromARGB(255, 45, 46, 52),
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     SelectableText(
//                       key,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Color.fromARGB(255, 174, 185, 252),
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     SelectableText(value),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       } else {
//         // Default fallback
//         contentWidget = SelectableText(content);
//       }
//     } catch (e) {
//       // If any formatting fails, show the raw content
//       contentWidget = Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Error formatting content: $e',
//             style: const TextStyle(color: Colors.red),
//           ),
//           const SizedBox(height: 8),
//           Expanded(child: SelectableText(content)),
//         ],
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Content Preview (${contentType}):',
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 8),
//         Expanded(
//           child: Container(
//             decoration: BoxDecoration(
//               color: const Color.fromARGB(255, 35, 36, 42),
//               borderRadius: BorderRadius.circular(4),
//             ),
//             padding: const EdgeInsets.all(8.0),
//             child: contentWidget,
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.flow == null) {
//       return const Center(child: Text('Select a flow to view details'));
//     }

//     final request = widget.flow!.request;

//     return Container(
//       color: const Color.fromARGB(255, 25, 26, 32),
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Request summary row with title and tabs
//           Row(
//             children: [
//               // Request title
//               Text(
//                 'Request',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: widget.dataSource.getMethodColor(request.method),
//                 ),
//               ),
//               const SizedBox(width: 16),

//               // Tab bar for different views
//               Expanded(
//                 child: TabBar(
//                   controller: _tabController,
//                   isScrollable: true,
//                   tabAlignment: TabAlignment.start,
//                   labelColor: Colors.white,
//                   unselectedLabelColor: Colors.grey,
//                   indicatorColor: widget.dataSource.getMethodColor(
//                     request.method,
//                   ),
//                   tabs: const [
//                     Tab(text: 'Headers'),
//                     Tab(text: 'Query Params'),
//                     Tab(text: 'Cookies'),
//                     Tab(text: 'Body'),
//                     Tab(text: 'Preview'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),

//           // Summary info (always visible)
//           SelectableText(
//             'URL: ${request.url}',
//             style: const TextStyle(fontWeight: FontWeight.w500),
//           ),
//           const SizedBox(height: 8),

//           SelectableText(
//             'Method: ${request.method} (HTTP/${request.httpVersion})',
//             style: const TextStyle(fontWeight: FontWeight.w500),
//           ),
//           const SizedBox(height: 8),

//           // Content length if available
//           if (request.contentLength != null)
//             SelectableText(
//               'Content Length: ${widget.dataSource.formatBytes(request.contentLength!)}',
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//           const SizedBox(height: 16),

//           // Tab content
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 // Headers Tab
//                 _buildHeadersView(request),

//                 // Query Parameters Tab
//                 _buildQueryParamsView(request),

//                 // Cookies Tab
//                 _buildCookiesView(request),

//                 // Body Tab
//                 _buildBodyView(request),

//                 // Preview Tab
//                 _buildPreviewView(request),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class ResponsePanel extends StatefulWidget {
//   final models.Flow? flow;
//   final FlowDataSource dataSource;

//   const ResponsePanel({
//     super.key,
//     required this.flow,
//     required this.dataSource,
//   });

//   @override
//   State<ResponsePanel> createState() => _ResponsePanelState();
// }

// class _ResponsePanelState extends State<ResponsePanel>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.flow == null) {
//       return const Center(child: Text('Select a flow to view details'));
//     }

//     final response = widget.flow!.response;

//     if (response == null) {
//       return const Center(
//         child: Text(
//           'No response available',
//           style: TextStyle(color: Colors.orange),
//         ),
//       );
//     }

//     final statusColor = widget.dataSource.getStatusColor(response.statusCode);

//     return Container(
//       color: const Color.fromARGB(255, 25, 26, 32),
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Response summary row with title and tabs
//           Row(
//             children: [
//               // Response title
//               const Text(
//                 'Response',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(width: 12),

//               // Status code badge
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(
//                   '${response.statusCode} ${response.reason}',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: statusColor,
//                   ),
//                 ),
//               ),

//               const SizedBox(width: 16),

//               // Tab bar for different views
//               Expanded(
//                 child: TabBar(
//                   controller: _tabController,
//                   isScrollable: true,
//                   tabAlignment: TabAlignment.start,
//                   labelColor: Colors.white,
//                   unselectedLabelColor: Colors.grey,
//                   indicatorColor: statusColor,
//                   tabs: const [
//                     Tab(text: 'Headers'),
//                     Tab(text: 'Body'),
//                     Tab(text: 'Preview'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),

//           // HTTP version
//           SelectableText(
//             'HTTP Version: ${response.httpVersion}',
//             style: const TextStyle(fontWeight: FontWeight.w500),
//           ),
//           const SizedBox(height: 8),

//           // Content type if available
//           if (response.contentType != null)
//             SelectableText(
//               'Content Type: ${response.contentType}',
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//           const SizedBox(height: 8),

//           // Content length if available
//           if (response.contentLength != null)
//             SelectableText(
//               'Content Length: ${widget.dataSource.formatBytes(response.contentLength!)}',
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//           const SizedBox(height: 16),

//           // Tab content
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 // Headers Tab
//                 _buildHeadersView(response),

//                 // Body Tab
//                 _buildBodyView(response),

//                 // Preview Tab
//                 _buildPreviewView(response),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Headers tab content
//   Widget _buildHeadersView(models.HttpResponse response) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               'Headers:',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//             IconButton(
//               icon: const Icon(Icons.copy, size: 16),
//               tooltip: 'Copy all headers',
//               onPressed: () {
//                 // Convert headers to a copyable format
//                 final headerText = response.headers
//                     .map((h) => '${h[0]}: ${h[1]}')
//                     .join('\n');
//                 Clipboard.setData(ClipboardData(text: headerText));
                
//               },
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),

//         // Headers list with selectable text
//         Expanded(
//           child: ListView.builder(
//             itemCount: response.headers.length,
//             itemBuilder: (context, index) {
//               final header = response.headers[index];
//               return Card(
//                 margin: const EdgeInsets.symmetric(vertical: 2),
//                 color: const Color.fromARGB(255, 35, 36, 42),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     vertical: 4.0,
//                     horizontal: 8.0,
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: SelectableText.rich(
//                           TextSpan(
//                             style: const TextStyle(fontSize: 14),
//                             children: [
//                               TextSpan(
//                                 text: '${header[0]}: ',
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                   color: Color.fromARGB(255, 174, 185, 252),
//                                 ),
//                               ),
//                               TextSpan(
//                                 text: header[1],
//                                 style: const TextStyle(color: Colors.white),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.content_copy, size: 14),
//                         tooltip: 'Copy header',
//                         onPressed: () {
//                           Clipboard.setData(
//                             ClipboardData(text: '${header[0]}: ${header[1]}'),
//                           );
                          
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   // Body tab content
//   Widget _buildBodyView(models.HttpResponse response) {
//     final hasContent =
//         response.contentLength != null && response.contentLength! > 0;

//     if (!hasContent) {
//       return const Center(child: Text('No response body'));
//     }

//     // For now, we'll use a placeholder since the actual content isn't available
//     // In a real implementation, you would fetch the content from mitmproxy
//     final String content =
//         "[Response body content not available in the model. You would need to fetch this from mitmproxy API]";

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               'Response Body:',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//             IconButton(
//               icon: const Icon(Icons.copy, size: 16),
//               tooltip: 'Copy body',
//               onPressed: () {
//                 Clipboard.setData(ClipboardData(text: content));
                
//               },
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),

//         // Body content in a scrollable, selectable container
//         Expanded(
//           child: Container(
//             decoration: BoxDecoration(
//               color: const Color.fromARGB(255, 35, 36, 42),
//               borderRadius: BorderRadius.circular(4),
//             ),
//             padding: const EdgeInsets.all(8.0),
//             child: SelectableText(
//               content,
//               style: const TextStyle(fontFamily: 'monospace'),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Pretty/Preview tab content
//   Widget _buildPreviewView(models.HttpResponse response) {
//     final hasContent =
//         response.contentLength != null && response.contentLength! > 0;

//     if (!hasContent) {
//       return const Center(child: Text('No content to preview'));
//     }

//     // For now, we'll use a placeholder since the actual content isn't available
//     // In a real implementation, you would fetch the content from mitmproxy
//     final String content =
//         "[Response body content not available in the model. You would need to fetch this from mitmproxy API]";

//     // Determine content type from headers
//     final contentType = response.contentType ?? '';

//     // Try to format the content based on content type
//     Widget contentWidget;

//     try {
//       if (contentType.contains('json')) {
//         // Pretty print JSON (in a real app, this would be the actual JSON content)
//         final jsonObj = json.decode(
//           '{"message": "This is a placeholder for JSON content"}',
//         );
//         final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonObj);

//         contentWidget = SelectableText(
//           prettyJson,
//           style: const TextStyle(fontFamily: 'monospace'),
//         );
//       } else if (contentType.contains('html')) {
//         // Display HTML content with some formatting
//         contentWidget = Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'HTML content would be displayed here with formatting.',
//               style: TextStyle(fontStyle: FontStyle.italic),
//             ),
//             const SizedBox(height: 8),
//             SelectableText(content),
//           ],
//         );
//       } else if (contentType.contains('xml')) {
//         // Display XML as is for now
//         contentWidget = SelectableText(
//           content,
//           style: const TextStyle(fontFamily: 'monospace'),
//         );
//       } else if (contentType.contains('image')) {
//         // Show image placeholder
//         contentWidget = Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.image, size: 48, color: Colors.grey),
//             const SizedBox(height: 16),
//             Text(
//               'Image content (${contentType.split(';')[0]})',
//               style: const TextStyle(color: Colors.grey),
//             ),
//           ],
//         );
//       } else {
//         // Default fallback
//         contentWidget = SelectableText(content);
//       }
//     } catch (e) {
//       // If any formatting fails, show the raw content
//       contentWidget = Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Error formatting content: $e',
//             style: const TextStyle(color: Colors.red),
//           ),
//           const SizedBox(height: 8),
//           Expanded(child: SelectableText(content)),
//         ],
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Content Preview (${contentType.split(';')[0]}):',
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 8),
//         Expanded(
//           child: Container(
//             decoration: BoxDecoration(
//               color: const Color.fromARGB(255, 35, 36, 42),
//               borderRadius: BorderRadius.circular(4),
//             ),
//             padding: const EdgeInsets.all(8.0),
//             child: contentWidget,
//           ),
//         ),
//       ],
//     );
//   }
// }
