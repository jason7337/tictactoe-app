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
    Map<String, List<int>> data = {};
    int currentAddress = 0x100;

    // Primera pasada: recolectar etiquetas y datos
    List<String> lines = asmCode.split('\n');
    for (var line in lines) {
      line = line.trim();

      if (line.isEmpty || line.startsWith(';')) continue;

      try {
        if (line.endsWith(':')) {
          String label = line.substring(0, line.length - 1).trim();
          labels[label] = currentAddress;
        } else if (line.contains(' DB ')) {
          var parts = line.split(' DB ');
          String label = parts[0].trim();
          String content = parts[1].trim();

          List<int> bytes = [];

          // Manejar múltiples líneas de datos
          if (content.startsWith("'")) {
            String str = content.substring(1, content.indexOf("'", 1));
            bytes.addAll(str.codeUnits);

            // Agregar CR/LF si está especificado
            if (content.contains('13,10')) {
              bytes.addAll([13, 10]);
            }

            // Agregar terminador $ si está presente
            if (content.contains(r"'\$'") || content.endsWith(r"'$'")) {
              bytes.add(36); // ASCII de $
            }
          } else {
            var numbers = content.split(',');
            for (var num in numbers) {
              num = num.trim();
              if (num.isNotEmpty) {
                bytes.add(int.parse(num));
              }
            }
          }

          data[label] = bytes;
          labels[label] = currentAddress;
          currentAddress += bytes.length;
        } else if (line.startsWith('MOV ')) {
          currentAddress += 3;
        } else if (line.startsWith('INT ') || line.startsWith('JMP ')) {
          currentAddress += 2;
        } else if (line.startsWith('CALL ')) {
          currentAddress += 3;
        } else if (line == 'RET') {
          currentAddress += 1;
        }
      } catch (e) {
        print('Error en primera pasada, línea: $line');
        print('Error: $e');
      }
    }

    // Segunda pasada: generar código
    currentAddress = 0x100;
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith(';') || line.endsWith(':')) continue;

      try {
        if (line.startsWith('MOV ')) {
          var parts = line.split(',');
          var dest = parts[0].substring(4).trim();
          var source = parts[1].trim();

          if (dest == 'AH') {
            bytes.add(0xB4);
            if (source == '09h') {
              bytes.add(0x09);
            } else if (source == '01h') {
              bytes.add(0x01);
            } else if (source == '02h') {
              bytes.add(0x02);
            } else {
              bytes.add(int.parse(source.replaceAll('h', ''), radix: 16));
            }
          } else if (dest == 'DX' && source.startsWith('OFFSET ')) {
            bytes.add(0xBA);
            String label = source.replaceAll('OFFSET ', '').trim();
            int address = labels[label] ?? 0;
            bytes.add(address & 0xFF);
            bytes.add((address >> 8) & 0xFF);
          }
        } else if (line.startsWith('INT ')) {
          bytes.add(0xCD);
          bytes.add(0x21);
        } else if (line.startsWith('JMP ')) {
          bytes.add(0xEB);
          String label = line.substring(4).trim();
          int target = labels[label] ?? currentAddress;
          int offset = target - (currentAddress + 2);
          bytes.add(offset & 0xFF);
        } else if (line.startsWith('CALL ')) {
          bytes.add(0xE8);
          String label = line.substring(5).trim();
          int target = labels[label] ?? currentAddress;
          int offset = target - (currentAddress + 3);
          bytes.add(offset & 0xFF);
          bytes.add((offset >> 8) & 0xFF);
        } else if (line == 'RET') {
          bytes.add(0xC3);
        }

        currentAddress += bytes.length;
      } catch (e) {
        print('Error en segunda pasada, línea: $line');
        print('Error: $e');
      }
    }

    return bytes;
  }
}
