import 'package:flutter/material.dart';
import '../utils/asm_handler.dart';

class CodeScreen extends StatelessWidget {
  const CodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Título y descripción
          const Text(
            'Código Fuente ASM',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Este es el código ensamblador que se ejecuta en el emulador',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),

          // Editor de código
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade800,
                  width: 1,
                ),
              ),
              child: FutureBuilder<String>(
                future: AsmHandler.getAsmCode(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar el código:\n${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay código disponible',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Numeración de líneas + código
                        ...snapshot.data!.split('\n').asMap().entries.map(
                          (entry) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Número de línea
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    '${entry.key + 1}'.padLeft(3, '0'),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontFamily: 'Courier',
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                // Código
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontFamily: 'Courier',
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
