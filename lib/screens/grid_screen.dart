import 'package:flutter/material.dart';
import '../models/grid_state.dart';
import '../widgets/math_cell.dart';
import '../services/verifier_service.dart';

class GridScreen extends StatefulWidget {
  const GridScreen({Key? key}) : super(key: key);

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  final GridState _gridState = GridState();

  @override
  void initState() {
    super.initState();
    _gridState.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _gridState.dispose();
    super.dispose();
  }

  void _verify() {
    VerifierService.verify(context, _gridState);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 80,
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        title: const Text('Calculosore'),
        actions: [
          // Bouton Vérifier plus discret et élégant dans l'AppBar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton.icon(
              onPressed: _verify,
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text('Vérifier', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bouton Effacer
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded, color: Color(0xFF1E3A8A)),
            onPressed: () => _gridState.reset(),
            tooltip: 'Tout effacer',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF1F5F9),
              const Color(0xFFE2E8F0),
              const Color(0xFFF1F5F9).withOpacity(0.8),
            ],
          ),
        ),
        child: InteractiveViewer(
          constrained: false,
          boundaryMargin: const EdgeInsets.all(500),
          minScale: 0.4,
          maxScale: 2.5,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: screenSize.width,
              minHeight: screenSize.height,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(100.0), // Plus d'espace pour le confort
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_gridState.rows, (rowIndex) {
                      final bool isLineRow = _gridState.cells[rowIndex].any((c) => c.isLine);
                      
                      // Calculer les colonnes qui contiennent des chiffres (pour la ligne auto)
                      int minCol = _gridState.cols;
                      int maxCol = -1;
                      if (isLineRow) {
                        for (int r = 0; r < _gridState.rows; r++) {
                          if (r == rowIndex) continue;
                          for (int c = 0; c < _gridState.cols; c++) {
                            final val = _gridState.cells[r][c].text.trim();
                            if (val.isNotEmpty && val != '+' && val != '-' && val != 'x' && val != '*' && val != '=') {
                              if (c < minCol) minCol = c;
                              if (c > maxCol) maxCol = c;
                            }
                          }
                        }
                        // On ajoute une marge de 1 colonne à gauche pour le signe si besoin
                        if (minCol > 0) minCol--;
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_gridState.cols, (colIndex) {
                          final bool showAutoLine = isLineRow && colIndex >= minCol && colIndex <= maxCol;
                          return RepaintBoundary(
                            child: MathCell(
                              key: ValueKey(_gridState.cells[rowIndex][colIndex]),
                              cell: _gridState.cells[rowIndex][colIndex],
                              isLineRow: isLineRow,
                              showAutoLine: showAutoLine,
                              onChanged: (value) => _gridState.updateCell(rowIndex, colIndex, value),
                              onLeftCarryChanged: (value) => _gridState.updateCarry(rowIndex, colIndex, true, value),
                              onRightCarryChanged: (value) => _gridState.updateCarry(rowIndex, colIndex, false, value),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
