import 'package:flutter/material.dart';
import '../models/grid_state.dart';

class VerifierService {
  static void verify(BuildContext context, GridState state) {
    int lineRow = -1;
    for (int i = 0; i < state.rows; i++) {
      if (state.cells[i].any((c) => c.isLine)) {
        lineRow = i;
        break;
      }
    }

    if (lineRow == -1) {
      _showError(context, "Je ne trouve pas la ligne de séparation (____).", null, null);
      return;
    }

    // Chercher l'opérateur
    String operator = '';
    int opRow = -1;
    for (int i = 0; i < lineRow; i++) {
      for (int j = 0; j < state.cols; j++) {
        String text = state.cells[i][j].displayText.trim();
        if (text == '+' || text == '-' || text == 'x' || text == '*') {
          operator = text;
          opRow = i;
        }
      }
    }

    if (operator.isEmpty) {
      _showError(context, "Je ne trouve pas le signe de l'opération (+, -, x).", null, null);
      return;
    }

    if (operator == '+') {
      _verifyAddition(context, state, lineRow, opRow);
    } else if (operator == '-') {
      _verifySubtraction(context, state, lineRow, opRow);
    } else if (operator == 'x' || operator == '*') {
      _showError(context, "La vérification des multiplications arrive bientôt !", null, null);
    }
  }

  static void _verifyAddition(BuildContext context, GridState state, int lineRow, int opRow) {
    int carry = 0;
    
    // On commence par la colonne la plus à droite
    for (int col = state.cols - 1; col >= 0; col--) {
      bool hasDataInCol = false;
      for (int r = 0; r < state.rows; r++) {
        if (state.cells[r][col].text.trim().isNotEmpty) {
          hasDataInCol = true;
          break;
        }
      }
      if (!hasDataInCol) continue;

      int op1 = _parseInt(state.cells[lineRow - 2][col].displayText);
      int op2 = _parseInt(state.cells[lineRow - 1][col].displayText);
      
      // On cherche une retenue déclarée par l'utilisateur (le chiffre entre parenthèses)
      int userCarry = 0;
      for (int r = 0; r < lineRow; r++) {
        String cText = state.cells[r][col].carryText;
        if (cText.isNotEmpty) {
          userCarry = _parseInt(cText);
          break;
        }
      }

      // Vérifier si la retenue de l'utilisateur correspond à la retenue attendue
      if (userCarry != carry && (userCarry > 0 || carry > 0)) {
        _showError(context, "Attention à la retenue ici ! On attendait $carry mais tu as mis ${userCarry == 0 ? 'rien' : userCarry}.", null, null);
        return;
      }

      int sum = op1 + op2 + carry;
      int expectedResult = sum % 10;
      int nextCarry = sum ~/ 10;

      // Vérifier le résultat de l'utilisateur
      String userResultText = state.cells[lineRow + 1][col].displayText;
      int userResult = userResultText.isEmpty ? -1 : _parseInt(userResultText);

      // Si les opérandes sont 0 et qu'on a dépassé les chiffres significatifs, on s'arrête
      if (op1 == 0 && op2 == 0 && carry == 0 && userResult == -1) {
         continue; 
      }

      if (userResult == -1 && (op1 > 0 || op2 > 0 || carry > 0)) {
        _showError(context, "Il manque le résultat dans cette colonne.", null, null);
        return;
      }

      if (userResult != expectedResult && userResult != -1) {
        _showError(context, "Erreur de calcul ! $op1 + $op2${carry > 0 ? ' + retenue $carry' : ''} = $sum. Donc on écrit $expectedResult en bas.", null, null);
        return;
      }

      carry = nextCarry;
    }

    if (carry > 0) {
      _showError(context, "Tu as oublié la dernière retenue ! Il faut la descendre.", null, null); 
      return;
    }

    _showSuccess(context);
  }

  static void _verifySubtraction(BuildContext context, GridState state, int lineRow, int opRow) {
     int borrow = 0;
    
    for (int col = state.cols - 1; col >= 0; col--) {
      bool hasDataInCol = false;
      for (int r = 0; r < state.rows; r++) {
        if (state.cells[r][col].text.trim().isNotEmpty) {
          hasDataInCol = true;
          break;
        }
      }
      if (!hasDataInCol) continue;

      int op1 = _parseInt(state.cells[lineRow - 2][col].displayText);
      int op2 = _parseInt(state.cells[lineRow - 1][col].displayText);
      
      int currentVal1 = op1 - borrow;
      int expectedResult = 0;
      int nextBorrow = 0;
      
      if (currentVal1 < op2) {
        currentVal1 += 10;
        nextBorrow = 1;
      }
      expectedResult = currentVal1 - op2;

      String userResultText = state.cells[lineRow + 1][col].displayText;
      int userResult = userResultText.isEmpty ? -1 : _parseInt(userResultText);

      if (op1 == 0 && op2 == 0 && borrow == 0 && userResult == -1) {
         continue; 
      }

      if (userResult == -1 && (op1 > 0 || op2 > 0 || borrow > 0)) {
        _showError(context, "Il manque le résultat dans cette colonne.", null, null);
        return;
      }

      if (userResult != expectedResult && userResult != -1) {
        _showError(context, "Erreur de calcul ! $op1 - $op2${borrow > 0 ? ' (avec la retenue précédente)' : ''} = $expectedResult.", null, null);
        return;
      }

      borrow = nextBorrow;
    }

    _showSuccess(context);
  }

  static int _parseInt(String text) {
    if (text.isEmpty) return 0;
    String clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return 0;
    return int.parse(clean);
  }

  static void _showError(BuildContext context, String message, int? row, int? col) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erreur', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Corriger'),
          )
        ],
      ),
    );
  }

  static void _showSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bravo !', style: TextStyle(color: Colors.green)),
        content: const Text('Le calcul est parfaitement exact !'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Super !'),
          )
        ],
      ),
    );
  }
}
