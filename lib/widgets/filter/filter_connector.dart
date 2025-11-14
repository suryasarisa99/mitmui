import 'package:flutter/material.dart';
import 'package:mitmui/models/filter_models.dart';

// class FilterConnector extends StatelessWidget {
//   static const double x = 8;
//   static const gap = 0;
//   static const borderClr = .fromARGB(255, 138, 138, 138);
//   static const lineWidth = 1.2;

//   const FilterConnector({
//     required this.operator,
//     required this.onToggle,
//     super.key,
//   });
//   final LogicalOperator operator;
//   final VoidCallback? onToggle;

//   @override
//   Widget build(BuildContext context) {
//     final isAnd = operator == LogicalOperator.and;
//     final color = isAnd ? Colors.red : Colors.blue;
//     final bgColor = .withValues(alpha: 0.1);
//     return GestureDetector(
//       // behavior: HitTestBehavior.translucent,
//       onTap: onToggle,
//       child: SizedBox(
//         width: 40,
//         height: 20,
//         child: Container(
//           color: const .fromARGB(255, 56, 56, 56),
//           child: Stack(
//             clipBehavior: Clip.none,
//             children: [
//               // Bottom Horizontal line with curve
//               Positioned(
//                 left: 20,
//                 top: x - gap,
//                 child: Container(
//                   width: 20,
//                   height: x,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.only(
//                       bottomLeft: Radius.circular(4),
//                     ),
//                     border: Border(
//                       bottom: .new(color: borderClr, width: lineWidth),
//                       left: .new(color: borderClr, width: lineWidth),
//                     ),
//                   ),
//                 ),
//               ),

//               // Top horizontal line with curve
//               Positioned(
//                 left: 20,
//                 top: -(2 * x) - gap,
//                 child: Container(
//                   width: 20,
//                   height: x,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(4),
//                     ),
//                     border: Border(
//                       top: .new(color: borderClr, width: lineWidth),
//                       left: .new(color: borderClr, width: lineWidth),
//                     ),
//                   ),
//                 ),
//               ),

//               Positioned(
//                 left: 4,
//                 top: -x - gap,
//                 child: Container(
//                   width: 35,
//                   padding: const .symmetric(
//                     horizontal: 6,
//                     vertical: 2,
//                   ),
//                   decoration: BoxDecoration(
//                     color: bgColor,
//                     borderRadius: BorderRadius.circular(6),
//                     border: Border.all(color: borderClr, width: 1),
//                   ),
//                   child: InkWell(
//                     onTap: () {
//                       debugPrint('Connector tapped to toggle operator');
//                       onToggle?.call();
//                     },
//                     child: Text(
//                       isAnd ? 'AND' : 'OR',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: color,
//                         fontSize: 9,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class FilterConnector extends StatelessWidget {
  static const double x = 8;
  static const gap = 4.0;
  static const borderClr = Color.fromARGB(255, 138, 138, 138);
  static const lineWidth = 1.2;

  const FilterConnector({
    required this.operator,
    required this.onToggle,
    super.key,
  });
  final LogicalOperator operator;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final isAnd = operator == LogicalOperator.and;
    final color = isAnd ? Colors.red : Colors.blue;
    final bgColor = color.withValues(alpha: 0.1);
    return Transform.translate(
      offset: const Offset(0, -10),
      child: SizedBox(
        width: 40,
        height: 33,
        child: Column(
          children: [
            Container(
              margin: const .only(left: 20),
              width: 20,
              height: x,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
                border: Border(
                  top: .new(color: borderClr, width: lineWidth),
                  left: .new(color: borderClr, width: lineWidth),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                debugPrint('Connector tapped to toggle operator');
                onToggle?.call();
              },
              child: Container(
                width: 35,
                padding: const .symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderClr, width: 1),
                ),
                child: Text(
                  isAnd ? 'AND' : 'OR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Top horizontal line with curve

            // Bottom Horizontal line with curve
            Container(
              width: 20,
              height: x,
              margin: const .only(left: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4)),
                border: Border(
                  bottom: .new(color: borderClr, width: lineWidth),
                  left: .new(color: borderClr, width: lineWidth),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
