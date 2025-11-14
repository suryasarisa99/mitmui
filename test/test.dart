// import 'package:flutter_test/flutter_test.dart';
import 'package:mitmui/utils/diff.dart';

final str1 = "hello world\nthis is a test\nof the diff line class";
final str2 = "hello world\nthis is a modified test\nof the diff line class";

final inputs = [
  (
    "hello world\nthis is a test\nof the diff line class",
    "hello world\nthis is a modified test\nof the diff line class",
  ),
  ("line one\nline three", "line one\nline 2 modified\nline three"),
  // (
  //   "line one\nline four\nline five",
  //   "line one\nline 2 modified\nline four\nline five",
  // ),
  // (
  //   "x-netflix.request.client.languages: en-IN\ncookie: a=b\ncontent-length: 6679",
  //   "x-netflix.request.client.languages: en-IN\naccept-encoding: gzip, br, deflate\ncookie: a=b;c=d\ncontent-length: 6679",
  // ),
  // (
  //   "first line\ncookie: a=b\nlast line",
  //   "first line\ncookie: a=rbd\nlast line",
  // ),
  // (
  //   "first line\ncookie: a=b\nlast line",
  //   "first line\ncookie: a=abcdefghi\nlast line",
  // ),
  (
    "first line\ncookie: a=b\nlast line",
    "first line\ncookie: a=abcdefghijkl\nlast line",
  ),
  (
    "first line\ncookie: a=b\nlast line",
    "first line\ntesting\ncookie: a=abcdefghijkl\nlast line",
  ),
  (
    "first line\ncookie: a=b\nlast line",
    "first line\ntesting something\ncookie: a=abcdefghijkl\nlast line",
  ),
  (
    "a\nb\n",
    "a\nb\nc\nd\ne\nf\ng\nh\ni\nj\nk\nl\nm\nn\no\np\nq\nr\ns\nt\nu\nv\nw\nx\ny\nz\n",
  ),
];
void main() {
  run();
}

void run() {
  for (var (input1, input2) in inputs) {
    final diffs = DiffUtils.get(input1, input2);

    print('Input 1:\n$input1\n');
    print('Input 2:\n$input2\n');

    print('Left Lines:');
    for (var line in diffs.left) {
      print(line);
    }

    print('\nRight Lines:');
    for (var line in diffs.right) {
      print(line);
    }

    print('\n${'=' * 40}\n');
  }
}

// void runTests() {
//   test('DiffUtils.get produces correct line diffs', () {
//     final diffs = DiffUtils.get(str1, str2);

//     expect(diffs.left.length, 3);
//     expect(diffs.right.length, 3);

//     expect(diffs.left[1].isDeleted, true);
//     expect(diffs.right[1].isInserted, true);

//     expect(diffs.left[0].text, 'hello world');
//     expect(diffs.right[0].text, 'hello world');

//     expect(diffs.left[2].text, 'of the diff line class');
//     expect(diffs.right[2].text, 'of the diff line class');
//   });
// }
