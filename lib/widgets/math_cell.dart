import 'package:flutter/material.dart';
import '../models/cell_data.dart';

const double kCellWidth = 72; // Un peu plus large pour être plus "smooth"
const double kCarryHeight = 24;
const double kMainHeight = 56;
const double kCellHeight = kCarryHeight + 1 + kMainHeight;
const double kLineRowHeight = 18;

class MathCell extends StatefulWidget {
  final CellData cell;
  final bool isLineRow;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onLeftCarryChanged;
  final ValueChanged<String> onRightCarryChanged;

  const MathCell({
    Key? key,
    required this.cell,
    required this.onChanged,
    required this.onLeftCarryChanged,
    required this.onRightCarryChanged,
    this.isLineRow = false,
  }) : super(key: key);

  @override
  State<MathCell> createState() => _MathCellState();
}

class _MathCellState extends State<MathCell> {
  late TextEditingController _controller;
  late TextEditingController _leftCarryController;
  late TextEditingController _rightCarryController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.cell.text);
    _leftCarryController = TextEditingController(text: widget.cell.topLeftCarry);
    _rightCarryController = TextEditingController(text: widget.cell.topRightCarry);
  }

  @override
  void didUpdateWidget(MathCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cell.text != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.cell.text,
        selection: TextSelection.collapsed(offset: widget.cell.text.length),
      );
    }
    if (widget.cell.topLeftCarry != _leftCarryController.text) {
      _leftCarryController.value = _leftCarryController.value.copyWith(text: widget.cell.topLeftCarry);
    }
    if (widget.cell.topRightCarry != _rightCarryController.text) {
      _rightCarryController.value = _rightCarryController.value.copyWith(text: widget.cell.topRightCarry);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _leftCarryController.dispose();
    _rightCarryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLineRow) {
      return SizedBox(
        width: kCellWidth,
        height: kLineRowHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.cell.isLine)
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A), // Navy de l'icône
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            Positioned.fill(
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                cursorColor: Colors.transparent,
                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                onChanged: (val) {
                  setState(() { widget.cell.text = val; });
                  widget.onChanged(val);
                },
              ),
            ),
          ],
        ),
      );
    }

    final bool isCrossedOut = widget.cell.isCrossedOut;
    final String crossedDigit = widget.cell.crossedDigit;
    final String newDigit = widget.cell.newDigit;
    final String plainText = widget.cell.text;

    return Container(
      width: kCellWidth,
      height: kCellHeight,
      margin: const EdgeInsets.all(1), // Petit espacement entre les cases
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Zone de retenues
          SizedBox(
            height: kCarryHeight,
            child: Row(
              children: [
                Expanded(child: _buildCarryBox(_leftCarryController, widget.onLeftCarryChanged, true)),
                Container(width: 1, color: const Color(0xFFE2E8F0)),
                Expanded(child: _buildCarryBox(_rightCarryController, widget.onRightCarryChanged, false)),
              ],
            ),
          ),
          Container(height: 1.5, color: const Color(0xFFE2E8F0)),
          // Zone chiffre principal
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, color: Colors.transparent),
                  cursorColor: const Color(0xFF1E3A8A),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  onChanged: (val) {
                    setState(() { widget.cell.text = val; });
                    widget.onChanged(val);
                  },
                ),
                IgnorePointer(
                  child: isCrossedOut
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              crossedDigit,
                              style: TextStyle(
                                fontSize: newDigit.isNotEmpty ? 22 : 32,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.redAccent,
                                decorationThickness: 3,
                                color: Colors.redAccent.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (newDigit.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                newDigit,
                                style: const TextStyle(fontSize: 28, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        )
                      : Text(
                          plainText,
                          style: const TextStyle(fontSize: 32, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarryBox(TextEditingController controller, ValueChanged<String> onChanged, bool isLeft) {
    final String text = controller.text;
    final bool isCrossed = text.startsWith('/') && text.length >= 2;
    final String displayCrossed = isCrossed ? text[1] : '';
    final String displayNew = isCrossed ? (text.length > 2 ? text.substring(2) : '') : text;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Stack(
        alignment: Alignment.center,
        children: [
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.transparent),
            decoration: const InputDecoration(
                border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(top: 4)),
            onChanged: (val) {
              setState(() {});
              onChanged(val);
            },
          ),
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: isCrossed
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayCrossed,
                          style: const TextStyle(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.redAccent,
                            decorationThickness: 2,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (displayNew.isNotEmpty) ...[
                          const SizedBox(width: 2),
                          Text(
                            displayNew,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    )
                  : Text(
                      text,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
