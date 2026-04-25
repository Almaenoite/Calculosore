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
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        title: const Text('Calculosore'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Tout effacer',
            onPressed: () => _gridState.reset(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(200),
              minScale: 0.5,
              maxScale: 3.0,
              // Permet de centrer la grille au milieu de l'écran (si elle est plus petite)
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Container(
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_gridState.rows, (rowIndex) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_gridState.cols, (colIndex) {
                          return MathCell(
                            cell: _gridState.cells[rowIndex][colIndex],
                            onChanged: (value) {
                              _gridState.updateCell(rowIndex, colIndex, value);
                            },
                            onDoubleTap: () {
                              _gridState.toggleCrossOut(rowIndex, colIndex);
                            },
                            onCarryDoubleTap: () {
                              _gridState.toggleCarryCrossOut(rowIndex, colIndex);
                            },
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 28),
                  label: const Text('Vérifier mon calcul', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _verify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
