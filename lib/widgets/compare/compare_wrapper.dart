import 'package:flutter/material.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/widgets/compare/compare.dart';

class Comparewrapper extends StatefulWidget {
  const Comparewrapper({super.key, required this.id1, required this.id2});
  final String id1;
  final String id2;
  @override
  State<Comparewrapper> createState() => _ComparewrapperState();
}

class _ComparewrapperState extends State<Comparewrapper> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        MitmproxyClient.getExportReq(widget.id1, RequestExport.rawRequest),
        MitmproxyClient.getExportReq(widget.id2, RequestExport.rawRequest),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final texts = snapshot.data as List<String>;
          return Compare(text1: texts[0], text2: texts[1], lazyLoad: false);
          // final texts = (
          //   "a\nb\n",
          //   "a\nb\nc\nd\ne\nf\ng\nh\ni\nj\nk\nl\nm\nn\no\np\nq\nr\ns\nt\nu\nv\nw\nx\ny\nz\n",
          // );
          // return Compare7(text1: texts.$1, text2: texts.$2, lazyLoad: false);
        }
      },
    );
  }
}
