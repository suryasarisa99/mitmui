import 'package:flutter/material.dart';

class Test1 extends StatelessWidget {
  const Test1({super.key});

  @override
  Widget build(BuildContext context) {
    return type2();
  }

  // advantages: lazy load, text selection
  // disadvantages: can't support rich text.
  Widget type1() {
    return SelectionArea(
      child: ListView.builder(
        itemBuilder: (context, index) {
          return Text(
            'Line $index: This is a test line for selection.\n',
            style: TextStyle(color: Colors.black, fontSize: 16),
          );
        },
      ),
    );
  }

  // advantages: support rich text, text selection
  // disadvantages: can't lazy load
  Widget type2() {
    return SingleChildScrollView(
      child: SelectableText.rich(
        TextSpan(
          children: List.generate(
            1000,
            (index) => TextSpan(
              text: 'Line $index: This is a test line for selection.\n',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  // advantages: support rich text, lazy load
  // disadvantages: it selects as individual line,can't select across lines
  Widget type3() {
    return ListView.builder(
      itemBuilder: (context, index) {
        return SelectableText(
          'Line $index: This is a test line for selection.\n',
          style: TextStyle(color: Colors.black, fontSize: 16),
        );
      },
    );
  }
}
