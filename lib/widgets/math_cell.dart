import 'package:flutter/material.dart';
import '../models/cell_data.dart';

class MathCell extends StatefulWidget {
  final CellData cell;
  final ValueChanged<String> onChanged;
  final VoidCallback onDoubleTap;
  final VoidCallback onCarryDoubleTap;

  const MathCell({
    Key? key,
    required this.cell,
    required this.onChanged,
    required this.onDoubleTap,
    required this.onCarryDoubleTap,
  }) : super(key: key);

  @override
  State<MathCell> createState() => _MathCellState();
}

class _MathCellState extends State<MathCell> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.cell.text);
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
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLine = widget.cell.isLine;
    bool isCrossedOut = widget.cell.isCrossedOut;
    String carryText = widget.cell.carryText;
    bool isCarryCrossedOut = widget.cell.isCarryCrossedOut;

    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueGrey.shade100, width: 1.0),
          color: Colors.white,
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isLine)
              Container(
                height: 4,
                color: Colors.black,
                width: double.infinity,
              ),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                color: Colors.transparent, // On cache le texte brut pour superposer le texte formaté
              ),
              cursorColor: Colors.blue,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (val) {
                // Mise à jour locale pour éviter le lag global
                setState(() {
                  widget.cell.text = val;
                });
                widget.onChanged(val);
              },
            ),
            if (!isLine)
              IgnorePointer(
                child: Text(
                  widget.cell.mainText,
                  style: TextStyle(
                    fontSize: 36,
                    decoration: isCrossedOut ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationColor: Colors.red,
                    decorationThickness: 2.0,
                    color: isCrossedOut ? Colors.red.shade700 : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (carryText.isNotEmpty)
              Positioned(
                top: 2,
                right: 4,
                child: GestureDetector(
                  onDoubleTap: widget.onCarryDoubleTap,
                  child: Container(
                    color: Colors.transparent, // Pour étendre la zone de clic
                    padding: const EdgeInsets.all(2.0),
                    child: Text(
                      carryText,
                      style: TextStyle(
                        fontSize: 16,
                        color: isCarryCrossedOut ? Colors.red : Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        decoration: isCarryCrossedOut ? TextDecoration.lineThrough : TextDecoration.none,
                        decorationThickness: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
