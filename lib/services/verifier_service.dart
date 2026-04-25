import 'package:flutter/material.dart';
import '../models/grid_state.dart';
import '../models/cell_data.dart';

class VerifierService {
  static void verify(BuildContext context, GridState state) {
    // 1. Trouver toutes les lignes de séparation
    final List<int> lineRows = [];
    for (int i = 0; i < state.rows; i++) {
      if (state.cells[i].any((c) => c.isLine)) lineRows.add(i);
    }

    if (lineRows.isEmpty) {
      _showError(context,
          "La ligne de séparation (____) est obligatoire.\nÉcris des tirets bas pour séparer le calcul du résultat.");
      return;
    }

    final int lineRow = lineRows[0];

    if (lineRow < 2) {
      _showError(context,
          "Il faut au moins deux lignes au-dessus de la ligne de séparation.");
      return;
    }
    if (lineRow >= state.rows - 1) {
      _showError(context, "Il manque le résultat en dessous de la ligne.");
      return;
    }

    // 2. Trouver l'opérateur
    String op = '';
    for (int i = 0; i < lineRow; i++) {
      for (int j = 0; j < state.cols; j++) {
        final t = state.cells[i][j].valueForVerification.trim();
        if (t == '+' || t == '-' || t == 'x' || t == '*') op = t;
      }
    }

    if (op.isEmpty) {
      _showError(context, "Je ne trouve pas le signe de l'opération (+, -, x).");
      return;
    }

    // 3. Vérification alignement
    if (!_checkAlignment(context, state, lineRow)) return;

    // 4. Vérifier selon l'opération
    if (op == '+') {
      _verifyAddition(context, state, lineRow);
    } else if (op == '-') {
      _verifySubtraction(context, state, lineRow);
    } else if (op == 'x' || op == '*') {
      _verifyMultiplication(context, state, lineRow, lineRows);
    }
  }

  // ─── Alignement ───────────────────────────────────────────────────────────

  static bool _checkAlignment(
      BuildContext context, GridState state, int lineRow) {
    final Map<int, String> rowLabels = {
      lineRow - 2: 'le premier nombre',
      lineRow - 1: 'le deuxième nombre',
      lineRow + 1: 'le résultat',
    };

    for (final entry in rowLabels.entries) {
      final int r = entry.key;
      if (r < 0 || r >= state.rows) continue;
      int leftmost = -1, rightmost = -1;
      for (int c = 0; c < state.cols; c++) {
        final t = state.cells[r][c].valueForVerification.trim();
        if (t.isNotEmpty && t != '+' && t != '-' && t != 'x' && t != '*') {
          if (leftmost == -1) leftmost = c;
          rightmost = c;
        }
      }
      if (leftmost == -1) continue;
      for (int c = leftmost; c <= rightmost; c++) {
        final t = state.cells[r][c].valueForVerification.trim();
        if (t.isEmpty) {
          _showError(context,
              "Les chiffres de ${entry.value} ne sont pas alignés !\nIl y a un trou entre les chiffres.");
          return false;
        }
      }
    }
    return true;
  }

  // ─── Addition ─────────────────────────────────────────────────────────────

  static void _verifyAddition(
      BuildContext context, GridState state, int lineRow) {
    int carry = 0;
    for (int col = state.cols - 1; col >= 0; col--) {
      if (!_colHasData(state, col)) continue;
      final int op1 = _parseCell(state.cells[lineRow - 2][col]);
      final int op2 = _parseCell(state.cells[lineRow - 1][col]);
      final int sum = op1 + op2 + carry;
      final int expected = sum % 10;
      final int nextCarry = sum ~/ 10;
      final int userResult = _parseCellOrMinus1(state.cells[lineRow + 1][col]);
      if (op1 == 0 && op2 == 0 && carry == 0 && userResult == -1) continue;
      if (userResult == -1 && (op1 > 0 || op2 > 0 || carry > 0)) {
        _showError(context, "Il manque le résultat dans cette colonne.");
        return;
      }
      if (userResult != expected && userResult != -1) {
        _showError(context,
            "Erreur ! $op1 + $op2${carry > 0 ? ' + retenue $carry' : ''} = $sum.\nOn écrit $expected en bas et on retient $nextCarry.");
        return;
      }
      carry = nextCarry;
    }
    if (carry > 0) {
      _showError(context,
          "Tu as oublié la dernière retenue ($carry) ! Il faut la descendre.");
      return;
    }
    _showSuccess(context);
  }

  // ─── Soustraction ─────────────────────────────────────────────────────────

  static void _verifySubtraction(
      BuildContext context, GridState state, int lineRow) {
    int borrow = 0;
    for (int col = state.cols - 1; col >= 0; col--) {
      if (!_colHasData(state, col)) continue;
      final int op1 = _parseCell(state.cells[lineRow - 2][col]);
      final int op2 = _parseCell(state.cells[lineRow - 1][col]);
      int currentVal = op1 - borrow;
      int nextBorrow = 0;
      if (currentVal < op2) {
        currentVal += 10;
        nextBorrow = 1;
      }
      final int expected = currentVal - op2;
      final int userResult = _parseCellOrMinus1(state.cells[lineRow + 1][col]);
      if (op1 == 0 && op2 == 0 && borrow == 0 && userResult == -1) continue;
      if (userResult == -1 && (op1 > 0 || op2 > 0 || borrow > 0)) {
        _showError(context, "Il manque le résultat dans cette colonne.");
        return;
      }
      if (userResult != expected && userResult != -1) {
        _showError(context,
            "Erreur ! $op1 - $op2${borrow > 0 ? " (avec l'emprunt)" : ''} = $expected.");
        return;
      }
      borrow = nextBorrow;
    }
    _showSuccess(context);
  }

  // ─── Multiplication ───────────────────────────────────────────────────────

  static void _verifyMultiplication(BuildContext context, GridState state,
      int lineRow1, List<int> lineRows) {
    // Lire op1 (ligne au-dessus de l'opérateur)
    final int op1 = _readRowAsNumber(state, lineRow1 - 2);
    // Lire op2 (chiffres seulement, sans le signe x)
    final int op2 = _readRowAsNumber(state, lineRow1 - 1, excludeOperator: true);

    if (op1 == 0 || op2 == 0) {
      _showError(context, "Je ne trouve pas les deux nombres à multiplier.");
      return;
    }

    final int expectedFinal = op1 * op2;

    // Cas simple : une seule ligne de séparation → résultat direct
    if (lineRows.length == 1) {
      final int userResult = _readRowAsNumber(state, lineRow1 + 1);
      if (userResult == 0) {
        _showError(context, "Il manque le résultat en dessous de la ligne.");
        return;
      }
      if (userResult != expectedFinal) {
        _showError(context,
            "Ce n'est pas le bon résultat !\n$op1 × $op2 = $expectedFinal, pas $userResult.");
        return;
      }
      _showSuccess(context);
      return;
    }

    // Cas avec produits partiels : deux lignes de séparation
    final int lineRow2 = lineRows[1];

    // Collecter les chiffres de op2 de droite à gauche
    final List<int> op2Digits = [];
    for (int c = state.cols - 1; c >= 0; c--) {
      final t = state.cells[lineRow1 - 1][c].valueForVerification.trim();
      if (t.isNotEmpty && t != 'x' && t != '*') {
        final d = int.tryParse(t);
        if (d != null) op2Digits.add(d);
      }
    }

    // Collecter les lignes de produits partiels entre line1 et line2
    final List<int> partialRows = [];
    for (int r = lineRow1 + 1; r < lineRow2; r++) {
      if (_rowHasData(state, r)) partialRows.add(r);
    }

    // Trouver la colonne la plus à droite avec des données sous lineRow1
    // (sert de référence pour calculer le décalage des produits partiels)
    int rightmostRef = 0;
    for (int r = lineRow1 + 1; r < state.rows; r++) {
      for (int c = state.cols - 1; c >= 0; c--) {
        if (state.cells[r][c].valueForVerification.trim().isNotEmpty) {
          if (c > rightmostRef) rightmostRef = c;
          break;
        }
      }
    }

    // Vérifier chaque produit partiel (avec décalage positionnel)
    for (int i = 0; i < op2Digits.length && i < partialRows.length; i++) {
      final int digit = op2Digits[i];
      final int expectedPartial = op1 * digit * _pow10(i);
      final int userPartial = _readRowWithShift(state, partialRows[i], rightmostRef);
      if (userPartial != expectedPartial) {
        _showError(context,
            "Erreur dans le produit partiel !\n$op1 × $digit = ${op1 * digit}${i > 0 ? ' (décalé de $i position${i > 1 ? 's' : ''})' : ''}.\nAttention aux zéros de décalage !");
        return;
      }
    }

    // Vérifier le résultat final
    if (lineRow2 + 1 >= state.rows) {
      _showError(context, "Il manque le résultat final.");
      return;
    }
    final int userFinal = _readRowAsNumber(state, lineRow2 + 1);
    if (userFinal != expectedFinal) {
      _showError(context,
          "Le résultat final n'est pas correct !\n$op1 × $op2 = $expectedFinal, pas $userFinal.");
      return;
    }
    _showSuccess(context);
  }

  // ─── Utilitaires ──────────────────────────────────────────────────────────

  static bool _colHasData(GridState state, int col) {
    return state.cells.any((row) => row[col].text.trim().isNotEmpty);
  }

  static bool _rowHasData(GridState state, int row) {
    return state.cells[row].any((c) => c.text.trim().isNotEmpty);
  }

  static int _parseCell(CellData cell) {
    final t = cell.valueForVerification.trim();
    if (t.isEmpty) return 0;
    return int.tryParse(t.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  static int _parseCellOrMinus1(CellData cell) {
    final t = cell.valueForVerification.trim();
    if (t.isEmpty) return -1;
    return int.tryParse(t.replaceAll(RegExp(r'[^0-9]'), '')) ?? -1;
  }

  // Lit une ligne en ajoutant les zéros de décalage implicites (à droite)
  // rightmostRef = colonne la plus à droite avec des données dans toute la zone
  static int _readRowWithShift(GridState state, int row, int rightmostRef) {
    int rightmostInRow = -1;
    for (int c = state.cols - 1; c >= 0; c--) {
      if (state.cells[row][c].valueForVerification.trim().isNotEmpty) {
        rightmostInRow = c;
        break;
      }
    }
    if (rightmostInRow == -1) return 0;
    final StringBuffer sb = StringBuffer();
    for (int c = 0; c < state.cols; c++) {
      final t = state.cells[row][c].valueForVerification.trim();
      if (t.isNotEmpty) sb.write(t);
    }
    final int base =
        int.tryParse(sb.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final int shift = rightmostRef - rightmostInRow;
    return base * _pow10(shift);
  }

  static int _pow10(int n) {
    int result = 1;
    for (int i = 0; i < n; i++) result *= 10;
    return result;
  }

  // Lit une ligne entière comme un nombre (ex: [1][5][3] → 153)
  static int _readRowAsNumber(GridState state, int row,
      {bool excludeOperator = false}) {
    final StringBuffer sb = StringBuffer();
    for (int c = 0; c < state.cols; c++) {
      final t = state.cells[row][c].valueForVerification.trim();
      if (excludeOperator && (t == 'x' || t == '*' || t == '+' || t == '-')) {
        continue;
      }
      if (t.isNotEmpty) sb.write(t);
    }
    return int.tryParse(sb.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  // ─── Dialogues ────────────────────────────────────────────────────────────

  static void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erreur', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Corriger'),
          ),
        ],
      ),
    );
  }

  static void _showSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Image.asset('assets/logo.png', height: 100),
            const SizedBox(height: 16),
            const Text('Bravo ! 🎉',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Le calcul est parfaitement exact ! Tu es un champion des chiffres.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('Super !'),
            ),
          ),
        ],
      ),
    );
  }
}
