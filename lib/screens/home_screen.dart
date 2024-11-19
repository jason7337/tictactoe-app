import 'package:flutter/material.dart';
import '../emulator/emulator_8086.dart';
import '../../utils/asm_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Emulator8086 _emulator = Emulator8086();
  bool _isWaitingForInput = false;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initEmulator();
  }

  Future<void> _initEmulator() async {
    final asmCode = await AsmHandler.getAsmCode();
    final program = AsmHandler.parseAsmToBytes(asmCode);
    await _emulator.loadProgram(program);
    setState(() {});
  }

  void _handleInput(String input) {
    if (!_isWaitingForInput) return;

    // Convertir entrada a número ASCII
    final inputByte = input.codeUnitAt(0);
    _emulator.ax = (_emulator.ax & 0xFF00) | inputByte;
    _isWaitingForInput = false;
    _inputController.clear();

    // Continuar ejecución
    _continueExecution();
  }

  void _continueExecution() {
    while (_emulator.running) {
      _emulator.step();
      if (_emulator.ah == 0x01) {
        // INT 21h, AH=01h (esperar entrada)
        setState(() {
          _isWaitingForInput = true;
        });
        break;
      }
    }
    setState(() {});
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
                    });
                  } else {
                    _initEmulator();
                  }
                },
              ),
              const SizedBox(width: 16),
              // Teclado numérico para entrada
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
          // Consola
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _emulator.consoleOutput.length,
                itemBuilder: (context, index) {
                  return Text(
                    _emulator.consoleOutput[index],
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'Courier',
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
