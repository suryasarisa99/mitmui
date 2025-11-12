import 'package:flutter/material.dart';
import 'package:mitmui/services/code_controller_service.dart';
import 'package:mitmui/widgets/resize.dart';

class PanelHeader extends StatelessWidget {
  const PanelHeader({
    required this.codeControllerService,
    required this.resizeController,
    required this.tabController,
    required this.id,
    required this.title,
    required this.panelTabs,
    super.key,
  });

  final CodeControllerService codeControllerService;
  final ResizableController resizeController;
  final TabController tabController;
  final String title;
  final String id;
  final Widget panelTabs;

  bool get isRequest => title == "request";
  bool get isSinglePanel =>
      resizeController.isChild1Hidden || resizeController.isChild2Hidden;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xff161819),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // SizedBox(width: 10),

          // Panel title or toggle buttons
          PanelHeaderBtns(resizeController: resizeController, isReq: isRequest),
          const SizedBox(width: 16),

          // Tab bar for different views
          Expanded(child: SizedBox(height: 30, child: panelTabs)),

          // save/cancel buttons
          ValueListenableBuilder<bool>(
            valueListenable: codeControllerService.isModified,
            builder: (context, value, _) {
              return value
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            codeControllerService.handleSave();
                          },
                          child: const Text('Save'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            codeControllerService.handleCancel();
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    )
                  : const SizedBox.shrink();
            },
          ),
          IconButton(
            iconSize: 22,
            splashRadius: 16,
            padding: const EdgeInsets.all(0.0),
            constraints: BoxConstraints(minHeight: 24, minWidth: 24),
            onPressed: () {
              if (isRequest) {
                if (resizeController.isChild2Hidden) {
                  resizeController.showSecondChild();
                } else {
                  resizeController.hideSecondChild();
                }
              } else {
                if (resizeController.isChild1Hidden) {
                  resizeController.showFirstChild();
                } else {
                  resizeController.hideFirstChild();
                }
              }
            },
            icon: Icon(
              isRequest
                  ? (resizeController.isChild1Hidden
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen)
                  : (resizeController.isChild2Hidden
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen),
              color: Colors.grey,
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }
}

class PanelHeaderBtns extends StatefulWidget {
  const PanelHeaderBtns({
    super.key,
    required this.resizeController,
    required this.isReq,
  });
  final ResizableController resizeController;
  final bool isReq;

  @override
  State<PanelHeaderBtns> createState() => _PanelHeaderBtnsState();
}

class _PanelHeaderBtnsState extends State<PanelHeaderBtns> {
  bool get isSinglePanel =>
      widget.resizeController.isChild1Hidden ||
      widget.resizeController.isChild2Hidden;

  @override
  void initState() {
    super.initState();
    widget.resizeController.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.resizeController.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isSinglePanel) {
      return Padding(
        padding: const EdgeInsets.only(left: 10),
        child: _buildToggleButtons(),
      );
    } else {
      // return Text(
      //   widget.isReq ? "Req" : "Res",
      //   style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      // );
      return const SizedBox.shrink();
    }
  }

  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Make the row wrap its content
          children: <Widget>[
            _buildToggleButton(
              text: 'Req',
              isSelected: !widget.resizeController.isChild1Hidden,
              onPressed: () {
                widget.resizeController.showFirstChild();
                widget.resizeController.hideSecondChild();
              },
            ),
            _buildToggleButton(
              text: 'Res',
              isSelected: !widget.resizeController.isChild2Hidden,
              onPressed: () {
                widget.resizeController.showSecondChild();
                widget.resizeController.hideFirstChild();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(0),
      child: Container(
        color: isSelected
            ? const Color.fromARGB(205, 238, 76, 26)
            : const Color.fromARGB(197, 66, 66, 66),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 3.5),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
