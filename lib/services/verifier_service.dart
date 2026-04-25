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

    // 2. Trouver l'opérateur (doit être sur la ligne juste au-dessus de la barre)
    String op = '';
    int opRow = lineRow - 1;
    for (int j = 0; j < state.cols; j++) {
      final t = state.cells[opRow][j].valueForVerification.trim();
      if (t == '+' || t == '-' || t == 'x' || t == '*') op = t;
    }

    if (op.isEmpty) {
      _showError(context,
          "Le signe de l'opération (+, -, x) doit être placé sur la deuxième ligne, à gauche du nombre.");
      return;
    }

    // 2b. Vérifier que le signe '=' est présent
    bool hasEqual = false;
    for (int i = 0; i < state.rows; i++) {
      for (int j = 0; j < state.cols; j++) {
        if (state.cells[i][j].valueForVerification.trim() == '=') {
          hasEqual = true;
          break;
        }
      }
    }
    if (!hasEqual) {
      _showError(context, "Il manque le signe '=' dans ton calcul.");
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
    final List<int> rowsToCheck = [];
    for (int i = 0; i < state.rows; i++) {
      if (i == lineRow) continue;
      if (_rowHasDigits(state, i)) rowsToCheck.add(i);
    }

    if (rowsToCheck.isEmpty) return true;

    // 1. Trouver la position de la virgule de référence (si elle existe)
    int globalCommaCol = -1;
    for (int r in rowsToCheck) {
      for (int c = 0; c < state.cols; c++) {
        if (state.cells[r][c].valueForVerification.trim() == ',') {
          if (globalCommaCol == -1) {
            globalCommaCol = c;
          } else if (globalCommaCol != c) {
            _showError(context,
                "Les virgules ne sont pas alignées !\nEn calcul posé, toutes les virgules doivent être dans la même colonne.");
            return false;
          }
        }
      }
    }

    // 2. Vérifier l'alignement des unités
    int expectedRightmostIfNoComma = -1;
    int refRowIndex = -1;

    for (int r in rowsToCheck) {
      int rightmostDigitCol = -1;
      bool hasCommaInRow = false;
      for (int c = 0; c < state.cols; c++) {
        final t = state.cells[r][c].valueForVerification.trim();
        if (t == ',') {
          hasCommaInRow = true;
          // Pour un nombre à virgule, l'unité est juste avant la virgule
          rightmostDigitCol = c - 1;
          break;
        }
        if (t.isNotEmpty && RegExp(r'[0-9]').hasMatch(t)) {
          rightmostDigitCol = c;
        }
      }

      if (rightmostDigitCol != -1) {
        if (globalCommaCol != -1) {
          // Si une virgule existe globalement, tous les nombres doivent aligner leur unité à globalCommaCol - 1
          if (rightmostDigitCol != globalCommaCol - 1 && !hasCommaInRow) {
             _showError(context,
                "Mauvais alignement !\nLe nombre entier à la ligne ${r + 1} doit avoir son chiffre des unités sous la colonne juste avant la virgule.");
            return false;
          }
        } else {
          // Si aucune virgule, on utilise l'alignement à droite classique
          if (expectedRightmostIfNoComma == -1) {
            expectedRightmostIfNoComma = rightmostDigitCol;
            refRowIndex = r;
          } else if (rightmostDigitCol != expectedRightmostIfNoComma) {
            _showError(context,
                "Les nombres ne sont pas bien alignés !\nLe nombre à la ligne ${r + 1} ne finit pas dans la même colonne que celui de la ligne ${refRowIndex + 1}.\nVérifie que les unités sont bien les unes sous les autres.");
            return false;
          }
        }
      }
    }

    // 3. Vérifier les trous à l'intérieur des nombres
    for (int r in rowsToCheck) {
      int leftmost = -1, rightmost = -1;
      for (int c = 0; c < state.cols; c++) {
        final t = state.cells[r][c].valueForVerification.trim();
        if (t.isNotEmpty && t != '+' && t != '-' && t != 'x' && t != '*' && t != '=') {
          if (leftmost == -1) leftmost = c;
          rightmost = c;
        }
      }
      if (leftmost == -1) continue;
      for (int c = leftmost; c <= rightmost; c++) {
        final t = state.cells[r][c].valueForVerification.trim();
        if (t.isEmpty) {
          _showError(context,
              "Les chiffres à la ligne ${r + 1} ne sont pas alignés !\nIl y a un trou entre les chiffres.");
          return false;
        }
      }
    }
    return true;
  }

  static bool _rowHasDigits(GridState state, int row) {
    for (int c = 0; c < state.cols; c++) {
      final t = state.cells[row][c].valueForVerification.trim();
      if (t.isNotEmpty && t != '+' && t != '-' && t != 'x' && t != '*' && t != '=') return true;
    }
    return false;
  }

  // ─── Addition ─────────────────────────────────────────────────────────────

  static void _verifyAddition(
      BuildContext context, GridState state, int lineRow) {
    // Identifier toutes les lignes d'opérandes au-dessus de la barre
    final List<int> operandRows = [];
    for (int r = 0; r < lineRow; r++) {
      if (_rowHasDigits(state, r)) operandRows.add(r);
    }

    int carry = 0;
    for (int col = state.cols - 1; col >= 0; col--) {
      if (!_colHasData(state, col)) continue;

      // Si c'est une virgule, on vérifie juste sa présence
      bool isCommaCol = false;
      for (int r in operandRows) {
        if (state.cells[r][col].valueForVerification.trim() == ',') isCommaCol = true;
      }
      if (isCommaCol) {
        if (state.cells[lineRow + 1][col].valueForVerification.trim() != ',') {
          _showError(context, "Tu as oublié la virgule dans le résultat !");
          return;
        }
        continue;
      }

      int sum = carry;
      final List<int> values = [];
      for (int r in operandRows) {
        final val = _parseCell(state.cells[r][col]);
        sum += val;
        if (val != 0 || state.cells[r][col].text.isNotEmpty) values.add(val);
      }

      final int expected = sum % 10;
      final int nextCarry = sum ~/ 10;
      final int userResult = _parseCellOrMinus1(state.cells[lineRow + 1][col]);

      if (values.isEmpty && carry == 0 && userResult == -1) continue;

      if (userResult == -1 && (sum > 0)) {
        _showError(context, "Il manque le résultat dans cette colonne.");
        return;
      }

      if (userResult != expected && userResult != -1) {
        String detail = values.join(' + ');
        if (carry > 0) detail += " + retenue $carry";
        _showError(context,
            "Erreur ! $detail = $sum.\nOn écrit $expected en bas et on retient $nextCarry.");
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
    // Identifier toutes les lignes d'opérandes au-dessus de la barre
    final List<int> operandRows = [];
    for (int r = 0; r < lineRow; r++) {
      if (_rowHasDigits(state, r)) operandRows.add(r);
    }

    if (operandRows.isEmpty) return;

    int borrow = 0;
    for (int col = state.cols - 1; col >= 0; col--) {
      if (!_colHasData(state, col)) continue;

      // Gestion virgule
      bool isCommaCol = false;
      for (int r in operandRows) {
        if (state.cells[r][col].valueForVerification.trim() == ',') isCommaCol = true;
      }
      if (isCommaCol) {
        if (state.cells[lineRow + 1][col].valueForVerification.trim() != ',') {
          _showError(context, "Tu as oublié la virgule dans le résultat !");
          return;
        }
        continue;
      }

      int currentVal = _parseCell(state.cells[operandRows[0]][col]) - borrow;
      int subtrahendSum = 0;
      for (int i = 1; i < operandRows.length; i++) {
        subtrahendSum += _parseCell(state.cells[operandRows[i]][col]);
      }

      int nextBorrow = 0;
      while (currentVal < subtrahendSum) {
        currentVal += 10;
        nextBorrow++;
      }

      final int expected = currentVal - subtrahendSum;
      final int userResult = _parseCellOrMinus1(state.cells[lineRow + 1][col]);

      if (userResult == -1 && (currentVal > 0 || subtrahendSum > 0 || borrow > 0)) {
        bool allEmpty = true;
        for (int r in operandRows) {
          if (state.cells[r][col].text.isNotEmpty) allEmpty = false;
        }
        if (!allEmpty) {
          _showError(context, "Il manque le résultat dans cette colonne.");
          return;
        }
      }

      if (userResult != expected && userResult != -1) {
        _showError(context, "Erreur de calcul dans cette colonne !");
        return;
      }
      borrow = nextBorrow;
    }
    _showSuccess(context);
  }

  // ─── Multiplication ───────────────────────────────────────────────────────

  static void _verifyMultiplication(BuildContext context, GridState state,
      int lineRow1, List<int> lineRows) {
    
    // Pour la multiplication, on ignore les virgules pendant le calcul
    final int op1 = _readRowAsNumber(state, lineRow1 - 2);
    final int op2 = _readRowAsNumber(state, lineRow1 - 1, excludeOperator: true);

    if (op1 == 0 || op2 == 0) {
      _showError(context, "Je ne trouve pas les deux nombres à multiplier.");
      return;
    }

    // Calculer le nombre de décimales attendues
    int dec1 = _countDecimals(state, lineRow1 - 2);
    int dec2 = _countDecimals(state, lineRow1 - 1);
    int expectedDecimals = dec1 + dec2;

    double expectedFinal = (op1 * op2) / _pow10(expectedDecimals);

    // Vérifier le résultat final (on le lit avec sa virgule)
    int lastRow = lineRows.last + 1;
    if (lastRow >= state.rows) {
       _showError(context, "Il manque le résultat final.");
       return;
    }
    
    double userFinal = _readRowAsDouble(state, lastRow);
    
    if ((userFinal - expectedFinal).abs() > 0.000001) {
        String msg = "Le résultat n'est pas correct !\n";
        msg += "Sans les virgules : $op1 × $op2 = ${op1 * op2}.\n";
        if (expectedDecimals > 0) {
          msg += "Avec les virgules ($dec1 + $dec2 = $expectedDecimals chiffres après la virgule), on devrait avoir $expectedFinal.";
        }
        _showError(context, msg);
        return;
    }

    _showSuccess(context);
  }

  // ─── Utilitaires ──────────────────────────────────────────────────────────

  static int _countDecimals(GridState state, int row) {
    int commaIdx = -1;
    int lastDigitIdx = -1;
    for (int c = 0; c < state.cols; c++) {
      final t = state.cells[row][c].valueForVerification.trim();
      if (t == ',') commaIdx = c;
      if (t.isNotEmpty && RegExp(r'[0-9]').hasMatch(t)) lastDigitIdx = c;
    }
    if (commaIdx == -1) return 0;
    return lastDigitIdx - commaIdx;
  }

  static double _readRowAsDouble(GridState state, int row) {
    String s = "";
    for (int c = 0; c < state.cols; c++) {
      final t = state.cells[row][c].valueForVerification.trim();
      if (t.isNotEmpty) {
        if (t == ',') s += ".";
        else if (RegExp(r'[0-9]').hasMatch(t)) s += t;
      }
    }
    return double.tryParse(s) ?? 0.0;
  }

  static bool _colHasData(GridState state, int col) {
    return state.cells.any((row) => row[col].text.trim().isNotEmpty);
  }

  static bool _rowHasData(GridState state, int row) {
    return state.cells[row].any((c) => c.text.trim().isNotEmpty);
  }

  static int _parseCell(CellData cell) {
    final t = cell.valueForVerification.trim();
    if (t.isEmpty || t == ',') return 0;
    return int.tryParse(t.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  static int _parseCellOrMinus1(CellData cell) {
    final t = cell.valueForVerification.trim();
    if (t.isEmpty) return -1;
    if (t == ',') return -2; // Code spécial pour virgule
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
      if (excludeOperator && (t == 'x' || t == '*' || t == '+' || t == '-')) continue;
      if (t.isNotEmpty && RegExp(r'[0-9]').hasMatch(t)) sb.write(t);
    }
    return int.tryParse(sb.toString()) ?? 0;
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
