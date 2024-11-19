import 'dart:typed_data';

class Emulator8086 {
  // Registros de propósito general de 16 bits
  late int ax, bx, cx, dx, si, di, bp, sp;
  
  // Flags
  late bool zeroFlag;      // Zero flag
  late bool carryFlag;     // Carry flag
  late bool signFlag;      // Sign flag
  late bool overflowFlag;  // Overflow flag
  
  // Registro de instrucción y memoria
  late int ip;             // Instruction pointer
  late Uint8List memory;   // Memoria de 64KB
  late List<String> consoleOutput; // Salida de la consola
  bool running = false;    // Estado del emulador
  
  // Buffer para entrada
  String? pendingInput;
  
  Emulator8086() {
    reset();
  }

  void reset() {
    // Inicializar registros
    ax = bx = cx = dx = si = di = bp = 0;
    sp = 0xFFFE;  // Stack pointer inicial
    ip = 0x100;   // Punto de inicio para programas .COM
    
    // Inicializar flags
    zeroFlag = carryFlag = signFlag = overflowFlag = false;
    
    // Inicializar memoria
    memory = Uint8List(65536);  // 64KB de memoria
    
    // Limpiar salida y estado
    consoleOutput = [];
    running = false;
    pendingInput = null;
  }

  // Métodos de ayuda para acceder a los bytes alto y bajo de los registros
  int get ah => (ax >> 8) & 0xFF;
  int get al => ax & 0xFF;
  int get bh => (bx >> 8) & 0xFF;
  int get bl => bx & 0xFF;
  int get ch => (cx >> 8) & 0xFF;
  int get cl => cx & 0xFF;
  int get dh => (dx >> 8) & 0xFF;
  int get dl => dx & 0xFF;

  set ah(int value) => ax = (ax & 0x00FF) | ((value & 0xFF) << 8);
  set al(int value) => ax = (ax & 0xFF00) | (value & 0xFF);
  set bh(int value) => bx = (bx & 0x00FF) | ((value & 0xFF) << 8);
  set bl(int value) => bx = (bx & 0xFF00) | (value & 0xFF);
  set ch(int value) => cx = (cx & 0x00FF) | ((value & 0xFF) << 8);
  set cl(int value) => cx = (cx & 0xFF00) | (value & 0xFF);
  set dh(int value) => dx = (dx & 0x00FF) | ((value & 0xFF) << 8);
  set dl(int value) => dx = (dx & 0xFF00) | (value & 0xFF);

  // Cargar programa en memoria
  Future<void> loadProgram(List<int> program) async {
    reset();
    // Cargar programa desde offset 0x100 (formato .COM)
    for (int i = 0; i < program.length; i++) {
      memory[0x100 + i] = program[i];
    }
    running = true;
  }

  // Leer siguiente byte del programa
  int fetchByte() => memory[ip++];
  
  // Leer siguiente palabra (16 bits)
  int fetchWord() {
    int low = fetchByte();
    int high = fetchByte();
    return (high << 8) | low;
  }

  // Ejecutar una interrupción
  void interrupt(int intNumber) {
    switch (intNumber) {
      case 0x21:  // DOS API
        switch (ah) {
          case 0x01:  // Leer carácter con eco
            if (pendingInput != null) {
              al = pendingInput!.codeUnitAt(0);
              pendingInput = null;
              consoleOutput.add(String.fromCharCode(al));
            } else {
              running = false;  // Pausar hasta recibir entrada
            }
            break;
            
          case 0x02:  // Escribir carácter
            consoleOutput.add(String.fromCharCode(dl));
            break;
            
          case 0x09:  // Escribir string terminado en $
            var address = dx;
            var output = StringBuffer();
            while (memory[address] != 0x24) {  // '$'
              if (memory[address] == 13) {  // CR
                output.write('\n');
                address += 2;  // Saltar CR+LF
              } else {
                output.write(String.fromCharCode(memory[address]));
                address++;
              }
            }
            consoleOutput.add(output.toString());
            break;
            
          case 0x4C:  // Terminar programa
            running = false;
            break;
        }
        break;
    }
  }

  // Comparar valores y establecer flags
  void setFlags(int result, {int size = 8}) {
    int mask = size == 8 ? 0xFF : 0xFFFF;
    result &= mask;
    
    zeroFlag = result == 0;
    signFlag = (result & (size == 8 ? 0x80 : 0x8000)) != 0;
    // Otros flags según sea necesario
  }

  // Ejecutar una instrucción
  void step() {
    if (!running) return;
    
    // Fetch
    int opcode = fetchByte();
    
    // Decode & Execute
    switch (opcode) {
      case 0x2E:  // CS: prefix
      case 0x3E:  // DS: prefix
        opcode = fetchByte();  // Ignorar prefijos de segmento por ahora
        break;

      // MOV immediate to register
      case 0xB0:  // MOV AL, imm8
      case 0xB1:  // MOV CL, imm8
      case 0xB2:  // MOV DL, imm8
      case 0xB3:  // MOV BL, imm8
      case 0xB4:  // MOV AH, imm8
      case 0xB5:  // MOV CH, imm8
      case 0xB6:  // MOV DH, imm8
      case 0xB7:  // MOV BH, imm8
        {
          int reg = opcode & 0x07;
          int value = fetchByte();
          switch (reg) {
            case 0: al = value; break;
            case 1: cl = value; break;
            case 2: dl = value; break;
            case 3: bl = value; break;
            case 4: ah = value; break;
            case 5: ch = value; break;
            case 6: dh = value; break;
            case 7: bh = value; break;
          }
        }
        break;

      // MOV immediate to register (word)
      case 0xB8:  // MOV AX, imm16
      case 0xB9:  // MOV CX, imm16
      case 0xBA:  // MOV DX, imm16
      case 0xBB:  // MOV BX, imm16
      case 0xBC:  // MOV SP, imm16
      case 0xBD:  // MOV BP, imm16
      case 0xBE:  // MOV SI, imm16
      case 0xBF:  // MOV DI, imm16
        {
          int reg = opcode & 0x07;
          int value = fetchWord();
          switch (reg) {
            case 0: ax = value; break;
            case 1: cx = value; break;
            case 2: dx = value; break;
            case 3: bx = value; break;
            case 4: sp = value; break;
            case 5: bp = value; break;
            case 6: si = value; break;
            case 7: di = value; break;
          }
        }
        break;

      // CMP instrucciones
      case 0x3C:  // CMP AL, imm8
        {
          int value = fetchByte();
          setFlags(al - value);
        }
        break;

      // JMP instrucciones
      case 0xEB:  // JMP short
        {
          int offset = fetchByte();
          if (offset & 0x80 != 0) {
            offset = -(256 - offset);
          }
          ip += offset;
        }
        break;

      // Saltos condicionales
      case 0x74:  // JE/JZ short
        {
          int offset = fetchByte();
          if (zeroFlag) {
            if (offset & 0x80 != 0) {
              offset = -(256 - offset);
            }
            ip += offset;
          }
        }
        break;

      case 0x75:  // JNE/JNZ short
        {
          int offset = fetchByte();
          if (!zeroFlag) {
            if (offset & 0x80 != 0) {
              offset = -(256 - offset);
            }
            ip += offset;
          }
        }
        break;

      case 0xCD:  // INT
        interrupt(fetchByte());
        break;

      case 0xC3:  // RET
        running = false;
        break;

      default:
        consoleOutput.add('Opcode no implementado: 0x${opcode.toRadixString(16)}');
        running = false;
    }
  }

  // Proveer entrada al emulador
  void provideInput(String input) {
    pendingInput = input;
    if (!running) {
      running = true;
      while (running && pendingInput != null) {
        step();
      }
    }
  }

  // Obtener la salida acumulada
  List<String> getOutput() => List.from(consoleOutput);
}