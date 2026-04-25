import 'package:flutter/material.dart';
import 'cell_data.dart';

class GridState extends ChangeNotifier {
  List<List<CellData>> cells = [
    [CellData()]
  ];

  int get rows => cells.length;
  int get cols => cells.isNotEmpty ? cells[0].length : 0;

  void updateCell(int row, int col, String value) {
    if (cells[row][col].text == value) return;
    cells[row][col].text = value;
    
    bool changedStructure = false;
    
    // Expansion logic
    if (value.isNotEmpty) {
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
        for (var r in cells) {
          r.insert(0, CellData());
        }
        col++;
        changedStructure = true;
      }
      if (col == cols - 1) {
        for (var r in cells) {
          r.add(CellData());
        }
        changedStructure = true;
      }
    }
    
    // Shrinking logic
    while (rows > 1 && _isRowEmpty(0) && _isRowEmpty(1)) {
      cells.removeAt(0);
      row--; 
      changedStructure = true;
    }
    while (rows > 1 && _isRowEmpty(rows - 1) && _isRowEmpty(rows - 2)) {
      cells.removeLast();
      changedStructure = true;
    }
    while (cols > 1 && _isColEmpty(0) && _isColEmpty(1)) {
      for (var r in cells) {
        r.removeAt(0);
      }
      col--;
      changedStructure = true;
    }
    while (cols > 1 && _isColEmpty(cols - 1) && _isColEmpty(cols - 2)) {
      for (var r in cells) {
        r.removeLast();
      }
      changedStructure = true;
    }
    
    // Notify listeners only if the grid size changed, avoiding lag during typing
    if (changedStructure) {
      notifyListeners();
    }
  }

  bool _isRowEmpty(int r) {
    return cells[r].every((cell) => cell.text.isEmpty);
  }

  bool _isColEmpty(int c) {
    return cells.every((row) => row[c].text.isEmpty);
  }

  void toggleCrossOut(int row, int col) {
    cells[row][col].isCrossedOut = !cells[row][col].isCrossedOut;
    notifyListeners();
  }

  void toggleCarryCrossOut(int row, int col) {
    cells[row][col].isCarryCrossedOut = !cells[row][col].isCarryCrossedOut;
    notifyListeners();
  }

  void reset() {
    cells = [
      [CellData()]
    ];
    notifyListeners();
  }
}
