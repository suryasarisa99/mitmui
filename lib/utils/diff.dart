import 'package:diff_match_patch/diff_match_patch.dart';

// Model to store line content with word-level diffs
class DiffLine {
  final String text;
  final List<Diff>? wordDiffs; // Word-level diffs for this line
  final bool isEmpty;
  final bool isDeleted;
  final bool isInserted;
  final int? matchingLineIndex; // Index of corresponding line on other side

  DiffLine({
    required this.text,
    this.wordDiffs,
    this.isEmpty = false,
    this.isDeleted = false,
    this.isInserted = false,
    this.matchingLineIndex,
  });

  //string representation
  @override
  String toString() {
    return 'DiffLine(text: "$text", isEmpty: $isEmpty, isDeleted: $isDeleted, isInserted: $isInserted, matchingLineIndex: $matchingLineIndex, wordDiffs: $wordDiffs)';
  }
}

class DiffUtils {
  static ({List<DiffLine> left, List<DiffLine> right}) get(
    String text1,
    String text2,
  ) {
    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(text1, text2);
    // dmp.diffCleanupSemantic(diffs);
    dmp.diffCleanupEfficiency(diffs);
    return _processLineDiffs(text1, text2, diffs);
  }

  static ({List<DiffLine> left, List<DiffLine> right}) _processLineDiffs(
    String text1,
    String text2,
    List<Diff> diffs,
  ) {
    final leftResult = <DiffLine>[];
    final rightResult = <DiffLine>[];

    int leftIndex = 0;
    int rightIndex = 0;

    // Build current line content from diffs
    String currentLeftLine = '';
    String currentRightLine = '';
    List<Diff> currentLineDiffs = [];
    bool hasChangesInLine = false;

    void flushLine() {
      if (currentLeftLine.isEmpty &&
          currentRightLine.isEmpty &&
          currentLineDiffs.isEmpty) {
        return;
      }

      if (hasChangesInLine) {
        // Line has modifications - use word-level diffs
        leftResult.add(
          DiffLine(
            text: currentLeftLine,
            wordDiffs: currentLineDiffs,
            isDeleted: currentRightLine.isEmpty,
            isInserted: false,
            matchingLineIndex: rightIndex,
          ),
        );
        rightResult.add(
          DiffLine(
            text: currentRightLine,
            wordDiffs: currentLineDiffs,
            isDeleted: false,
            isInserted: currentLeftLine.isEmpty,
            matchingLineIndex: leftIndex,
          ),
        );
      } else {
        // Line is identical
        leftResult.add(
          DiffLine(text: currentLeftLine, matchingLineIndex: rightIndex),
        );
        rightResult.add(
          DiffLine(text: currentRightLine, matchingLineIndex: leftIndex),
        );
      }

      leftIndex++;
      rightIndex++;
      currentLeftLine = '';
      currentRightLine = '';
      currentLineDiffs = [];
      hasChangesInLine = false;
    }

    for (final diff in diffs) {
      final text = diff.text;

      // Check if this diff contains newlines
      if (text.contains('\n')) {
        final lines = text.split('\n');

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];

          if (i > 0) {
            // New line started, flush previous line
            flushLine();
          }

          // Add content to current line
          switch (diff.operation) {
            case DIFF_EQUAL:
              currentLeftLine += line;
              currentRightLine += line;
              currentLineDiffs.add(Diff(DIFF_EQUAL, line));
              break;
            case DIFF_DELETE:
              currentLeftLine += line;
              currentLineDiffs.add(Diff(DIFF_DELETE, line));
              hasChangesInLine = true;
              break;
            case DIFF_INSERT:
              currentRightLine += line;
              currentLineDiffs.add(Diff(DIFF_INSERT, line));
              hasChangesInLine = true;
              break;
          }
        }
      } else {
        // No newlines, add to current line
        switch (diff.operation) {
          case DIFF_EQUAL:
            currentLeftLine += text;
            currentRightLine += text;
            currentLineDiffs.add(Diff(DIFF_EQUAL, text));
            break;
          case DIFF_DELETE:
            currentLeftLine += text;
            currentLineDiffs.add(Diff(DIFF_DELETE, text));
            hasChangesInLine = true;
            break;
          case DIFF_INSERT:
            currentRightLine += text;
            currentLineDiffs.add(Diff(DIFF_INSERT, text));
            hasChangesInLine = true;
            break;
        }
      }
    }

    // Flush any remaining line
    flushLine();

    return (left: leftResult, right: rightResult);
  }
}
