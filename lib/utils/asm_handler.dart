import 'package:flutter/services.dart' show rootBundle;

class AsmHandler {
  static String? _asmCode;
  static const String asmPath = 'assets/juego.asm';

  static Future<String> getAsmCode() async {
    if (_asmCode != null) return _asmCode!;

    try {
      _asmCode = await rootBundle.loadString(asmPath);
      return _asmCode!;
    } catch (e) {
      throw Exception('Error al cargar el archivo ASM: $e\n'
          'Asegúrate de que el archivo existe en $asmPath y '
          'está correctamente configurado en pubspec.yaml');
    }
  }

  static List<int> parseAsmToBytes(String asmCode) {
    List<int> bytes = [];
    Map<String, int> labels = {};
    List<String> lines = asmCode.split('\n');

    // Primera pasada: recolectar etiquetas y sus direcciones
    int currentAddress = 0x100; // Comenzamos en 0x100 como el org 100h
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith(';')) continue;

      // Procesar etiquetas
      if (line.endsWith(':')) {
        String label = line.substring(0, line.length - 1).trim();
        labels[label] = currentAddress;
        continue;
      }

      // Calcular tamaño de instrucción
      if (line.startsWith('DB ')) {
        currentAddress += 1;
      } else if (line.startsWith('MOV ')) {
        currentAddress += 2; // Simplificado, realmente depende de los operandos
      } else if (line.startsWith('INT ')) {
        currentAddress += 2;
      } else if (line.startsWith('JMP ') ||
          line.startsWith('JE ') ||
          line.startsWith('JNE ') ||
          line.startsWith('JA ')) {
        currentAddress += 2;
      } else {
        currentAddress += 1; // Para otras instrucciones
      }
    }

    // Segunda pasada: generar código máquina
    currentAddress = 0x100;
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith(';') || line.endsWith(':')) continue;

      // Procesar directivas e instrucciones
      if (line.startsWith('DB ')) {
        // Procesar definición de bytes
        String data = line.substring(3).trim();
        if (data.startsWith("'") && data.endsWith("'")) {
          // String literal
          String str = data.substring(1, data.length - 1);
          bytes.addAll(str.codeUnits);
          bytes.add(0x24); // Agregar el carácter '$' al final
        } else {
          // Número
          bytes.add(int.parse(data));
        }
      } else if (line.startsWith('MOV ')) {
        // MOV registro, valor
        bytes.addAll([0xB8, 0x00]); // Simplificado
      } else if (line.startsWith('INT ')) {
        // Interrupción
        String value = line.substring(4).trim();
        bytes.addAll([0xCD, int.parse(value, radix: 16)]);
      } else if (line.startsWith('JMP ')) {
        // Salto incondicional
        bytes.addAll([0xEB, 0x00]); // Salto corto simplificado
      } else if (line.contains('CMP ')) {
        // Comparación
        bytes.addAll([0x3C, 0x00]); // Simplificado
      } else if (line.startsWith('JE ')) {
        // Salto si igual
        bytes.addAll([0x74, 0x00]);
      } else if (line.startsWith('JNE ')) {
        // Salto si no igual
        bytes.addAll([0x75, 0x00]);
      } else if (line.startsWith('JA ')) {
        // Salto si mayor
        bytes.addAll([0x77, 0x00]);
      } else if (line.startsWith('RET')) {
        // Retorno
        bytes.add(0xC3);
      } else if (line.startsWith('XOR ')) {
        // XOR simplificado
        bytes.addAll([0x33, 0xC0]);
      } else if (line.startsWith('INC ')) {
        // Incremento
        bytes.add(0x40);
      }
    }

    return bytes;
  }

  static int _parseRegister(String reg) {
    switch (reg.toUpperCase()) {
      case 'AX':
        return 0;
      case 'BX':
        return 3;
      case 'CX':
        return 1;
      case 'DX':
        return 2;
      case 'SI':
        return 6;
      case 'DI':
        return 7;
      default:
        return 0;
    }
  }
}
