class CellData {
  String text;
  bool isCrossedOut;
  bool isCarryCrossedOut;

  CellData({
    this.text = '', 
    this.isCrossedOut = false,
    this.isCarryCrossedOut = false,
  });

  bool get isLine => text.isNotEmpty && text.split('').every((char) => char == '_');
  
  String get carryText {
    final match = RegExp(r'\((.*?)\)').firstMatch(text);
    return match != null ? match.group(1) ?? '' : '';
  }

  String get mainText {
    return text.replaceAll(RegExp(r'\(.*?\)'), '');
  }

  String get displayText => mainText;
}
