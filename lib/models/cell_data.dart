class CellData {
  String text;
  String topLeftCarry;
  String topRightCarry;

  CellData({
    this.text = '',
    this.topLeftCarry = '',
    this.topRightCarry = '',
  });

  bool get isLine =>
      text.isNotEmpty && text.split('').every((c) => c == '_');

  // '/57' → '5' est barré, '7' est le nouveau chiffre non barré
  bool get isCrossedOut => text.startsWith('/');

  String get crossedDigit {
    if (!isCrossedOut || text.length < 2) return '';
    return text[1];
  }

  // Le chiffre de remplacement (après le chiffre barré)
  String get newDigit {
    if (!isCrossedOut || text.length < 3) return '';
    return text.substring(2);
  }

  // Affichage du chiffre non barré (pour l'UI)
  String get displayText {
    if (isCrossedOut) return newDigit;
    return text;
  }

  // Valeur utilisée par le vérificateur : le chiffre barré (valeur originale du nombre)
  // Le nouveau chiffre écrit à côté est une aide visuelle, pas la valeur du calcul
  String get valueForVerification {
    if (!isCrossedOut) return text;
    return crossedDigit;
  }
}
