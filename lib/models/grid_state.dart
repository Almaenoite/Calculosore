import 'package:flutter/material.dart';
import 'cell_data.dart';

class GridState extends ChangeNotifier {
  List<List<CellData>> cells = [
    [CellData()]
  ];

  int get rows => cells.length;
  int get cols => cells.isNotEmpty ? cells[0].length : 0;

  void updateCell(int row, int col, String value) {
    cells[row][col].text = value;
    bool changedStructure = false;

    if (value.isNotEmpty) {
      // ── Expansion uniquement quand on écrit ──
      if (row == 0) {
        cells.insert(0, List.generate(cols, (_) => CellData()));
        row++;
        changedStructure = true;
      }
      if (row == rows - 1) {
        cells.add(List.generate(cols, (_) => CellData()));
        changedStructure = true;
      }
      if (col == 0) {
        for (var r in cells) r.insert(0, CellData());
        col++;
        changedStructure = true;
      }
      if (col == cols - 1) {
        for (var r in cells) r.add(CellData());
        changedStructure = true;
      }
    } else {
      // ── Rétractation uniquement quand on efface ──
      while (rows > 1 && _isRowEmpty(0) && _isRowEmpty(1)) {
        cells.removeAt(0);
        changedStructure = true;
      }
      while (rows > 1 && _isRowEmpty(rows - 1) && _isRowEmpty(rows - 2)) {
        cells.removeLast();
        changedStructure = true;
      }
      while (cols > 1 && _isColEmpty(0) && _isColEmpty(1)) {
        for (var r in cells) r.removeAt(0);
        changedStructure = true;
      }
      while (cols > 1 && _isColEmpty(cols - 1) && _isColEmpty(cols - 2)) {
        for (var r in cells) r.removeLast();
        changedStructure = true;
      }
    }

    if (changedStructure) notifyListeners();
  }

  void updateCarry(int row, int col, bool isLeft, String value) {
    if (isLeft) {
      cells[row][col].topLeftCarry = value;
    } else {
      cells[row][col].topRightCarry = value;
    }
    // Les retenues ne changent pas la structure, pas besoin de notifier
  }

  // Arrêt dès le premier non-vide pour être plus rapide
  bool _isRowEmpty(int r) {
    for (final cell in cells[r]) {
      if (cell.text.isNotEmpty) return false;
    }
    return true;
  }

  bool _isColEmpty(int c) {
    for (final row in cells) {
      if (row[c].text.isNotEmpty) return false;
    }
    return true;
  }

  void reset() {
    cells = [[CellData()]];
    notifyListeners();
  }
}
