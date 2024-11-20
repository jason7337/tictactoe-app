import 'package:flutter/material.dart';
import '../emulator/emulator_8086.dart';
import '../utils/asm_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Emulator8086 _emulator = Emulator8086();
  bool _isWaitingForInput = false;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _addDebugInfo('Emulador inicializado');
  }

  void _addDebugInfo(String info) {
    setState(() {
      _debugInfo += '$info\n';
      _emulator.consoleOutput.add('DEBUG: $info');
    });
  }

  Future<void> _initEmulator() async {
    try {
      _addDebugInfo('Iniciando emulador...');

      // Cargar código ASM
      _addDebugInfo('Cargando código ASM...');
      final asmCode = await AsmHandler.getAsmCode();
      _addDebugInfo('Código ASM cargado: ${asmCode.length} bytes');

      // Parsear código a bytes
      _addDebugInfo('Parseando código a bytes...');
      final program = AsmHandler.parseAsmToBytes(asmCode);
      _addDebugInfo('Código parseado: ${program.length} bytes');

      // Mostrar primeros bytes para debug
      _addDebugInfo('Primeros bytes del programa:');
      for (int i = 0; i < min(20, program.length); i++) {
        _addDebugInfo(
            '${i.toRadixString(16).padLeft(2, '0')}: ${program[i].toRadixString(16).padLeft(2, '0')}');
      }

      // Cargar programa en emulador
      _addDebugInfo('Cargando programa en emulador...');
      await _emulator.loadProgram(program);

      // Ejecutar programa
      _addDebugInfo('Iniciando ejecución...');
      _continueExecution();
    } catch (e, stackTrace) {
      _addDebugInfo('ERROR: $e');
      _addDebugInfo('Stack trace: $stackTrace');
    }
  }

  void _continueExecution() {
    try {
      int steps = 0;
      while (_emulator.running && steps < 1000) {
        // Límite de seguridad
        steps++;
        _emulator.step();

        // Si necesitamos entrada del usuario
        if (_emulator.ah == 0x01) {
          setState(() {
            _isWaitingForInput = true;
          });
          _addDebugInfo('Esperando entrada del usuario...');
          break;
        }
      }

      if (steps >= 1000) {
        _addDebugInfo('ADVERTENCIA: Límite de pasos alcanzado');
      }

      _addDebugInfo('Estado después de ejecución:');
      _addDebugInfo('AX: ${_emulator.ax.toRadixString(16)}');
      _addDebugInfo('IP: ${_emulator.ip.toRadixString(16)}');
      _addDebugInfo('Running: ${_emulator.running}');

      setState(() {});
    } catch (e, stackTrace) {
      _addDebugInfo('ERROR en ejecución: $e');
      _addDebugInfo('Stack trace: $stackTrace');
    }
  }

  void _handleInput(String input) {
    if (!_isWaitingForInput) return;

    _addDebugInfo('Recibida entrada: $input');
    _emulator.provideInput(input);
    _isWaitingForInput = false;
    _continueExecution();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Botones de control
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: Icon(_emulator.running ? Icons.stop : Icons.play_arrow),
                label: Text(_emulator.running ? 'Detener' : 'Nuevo Juego'),
                onPressed: () {
                  if (_emulator.running) {
                    setState(() {
                      _emulator.running = false;
                      _addDebugInfo('Emulador detenido');
                    });
                  } else {
                    _initEmulator();
                  }
                },
              ),
              const SizedBox(width: 16),
              ...List.generate(9, (index) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: _isWaitingForInput
                        ? () => _handleInput((index + 1).toString())
                        : null,
                    child: Text('${index + 1}'),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Consola y debug
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Salida del emulador
                    ...(_emulator.consoleOutput.map((text) => Text(
                          text,
                          style: TextStyle(
                            color: text.startsWith('DEBUG:')
                                ? Colors.yellow
                                : Colors.green,
                            fontFamily: 'Courier',
                          ),
                        ))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Función helper
int min(int a, int b) => a < b ? a : b;
