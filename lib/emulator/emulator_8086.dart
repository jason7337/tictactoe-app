import 'dart:typed_data';

class Emulator8086 {
  // Registros y flags
  late int ax, bx, cx, dx, si, di, bp, sp;
  late bool zeroFlag, carryFlag, signFlag, overflowFlag;
  late int ip;
  late Uint8List memory;
  late List<String> consoleOutput;
  bool running = false;
  String? pendingInput;
  final int boardOffset = 0x200;

  // Getters y setters para registros de 8 bits
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

  Emulator8086() {
    reset();
  }

  void reset() {
    ax = bx = cx = dx = si = di = bp = 0;
    sp = 0xFFFE;
    ip = 0x100;
    zeroFlag = carryFlag = signFlag = overflowFlag = false;
    memory = Uint8List(65536);
    consoleOutput = [];
    running = false;
    pendingInput = null;

    // Inicializar tablero
    for (int i = 0; i < 9; i++) {
      memory[boardOffset + i] = 32; // Espacio en ASCII
    }
  }

  void _debug(String message) {
    consoleOutput.add('DEBUG: $message');
  }

  Future<void> loadProgram(List<int> program) async {
    reset();
    _debug('Iniciando nuevo juego de TicTacToe');

    for (int i = 0; i < program.length; i++) {
      memory[0x100 + i] = program[i];
      _debug('0x${(0x100 + i).toHexString()}: 0x${program[i].toHexString()}');
    }

    running = true;
    showGameBoard();
  }

  void step() {
    if (!running) return;

    try {
      int opcode = memory[ip];
      _debug('IP=0x${ip.toHexString()}, Opcode=0x${opcode.toHexString()}');

      switch (opcode) {
        case 0x00: // ADD r/m8, r8
        case 0x01: // ADD r/m16, r16
          ip++;
          int modrm = memory[ip++];
          handleArithmetic(modrm, opcode == 0x01);
          break;

        case 0x28: // SUB r/m8, r8
        case 0x29: // SUB r/m16, r16
          ip++;
          int modrm = memory[ip++];
          handleArithmetic(modrm, opcode == 0x29, isAdd: false);
          break;

        case 0x88: // MOV r/m8, r8
        case 0x89: // MOV r/m16, r16
          ip++;
          int modrm = memory[ip++];
          handleMOV(modrm, opcode == 0x89);
          break;

        case 0xB0: // MOV AL, imm8
        case 0xB1: // MOV CL, imm8
        case 0xB2: // MOV DL, imm8
        case 0xB3: // MOV BL, imm8
        case 0xB4: // MOV AH, imm8
        case 0xB5: // MOV CH, imm8
        case 0xB6: // MOV DH, imm8
        case 0xB7: // MOV BH, imm8
          ip++;
          int reg = opcode & 0x07;
          int value = memory[ip++];
          setRegister8(reg, value);
          _debug('MOV r8, ${value.toHexString()}');
          break;

        case 0xBA: // MOV DX, imm16
          ip++;
          dx = memory[ip++] | (memory[ip++] << 8);
          _debug('MOV DX, ${dx.toHexString()}');
          break;

        case 0xCD: // INT
          ip++;
          int intNum = memory[ip++];
          _debug('INT ${intNum.toHexString()}');
          handleInterrupt(intNum);
          break;

        case 0x74: // JE/JZ
          ip++;
          int offset = memory[ip++];
          if (zeroFlag) {
            ip += (offset < 128 ? offset : offset - 256) - 2;
            _debug('JE taken to ${ip.toHexString()}');
          } else {
            _debug('JE not taken');
          }
          break;

        case 0x75: // JNE/JNZ
          ip++;
          int offset = memory[ip++];
          if (!zeroFlag) {
            ip += (offset < 128 ? offset : offset - 256) - 2;
            _debug('JNE taken to ${ip.toHexString()}');
          } else {
            _debug('JNE not taken');
          }
          break;

        case 0xEB: // JMP short
          ip++;
          int offset = memory[ip++];
          ip += (offset < 128 ? offset : offset - 256) - 2;
          _debug('JMP to ${ip.toHexString()}');
          break;

        case 0xE8: // CALL near
          ip++;
          int offset = fetchWord();
          push(ip);
          ip += (offset < 32768 ? offset : offset - 65536) - 2;
          _debug('CALL to ${ip.toHexString()}');
          break;

        case 0xC3: // RET
          ip = pop();
          _debug('RET to ${ip.toHexString()}');
          break;

        case 0x3C: // CMP AL, imm8
          ip++;
          int value = memory[ip++];
          setFlags(al - value);
          _debug('CMP AL, ${value.toHexString()}');
          break;

        default:
          _debug('Opcode no implementado: 0x${opcode.toHexString()}');
          running = false;
      }
    } catch (e) {
      _debug('Error en ejecución: $e');
      running = false;
    }
  }

  void handleArithmetic(int modrm, bool is16Bit, {bool isAdd = true}) {
    int reg = (modrm >> 3) & 0x07;
    int rm = modrm & 0x07;

    if (is16Bit) {
      int value1 = getRegister16(reg);
      int value2 = getRegister16(rm);
      int result = isAdd ? value1 + value2 : value1 - value2;
      setRegister16(rm, result & 0xFFFF);
      setFlags16(result);
    } else {
      int value1 = getRegister8(reg);
      int value2 = getRegister8(rm);
      int result = isAdd ? value1 + value2 : value1 - value2;
      setRegister8(rm, result & 0xFF);
      setFlags(result);
    }
  }

  void handleMOV(int modrm, bool is16Bit) {
    int reg = (modrm >> 3) & 0x07;
    int rm = modrm & 0x07;

    if (is16Bit) {
      setRegister16(rm, getRegister16(reg));
    } else {
      setRegister8(rm, getRegister8(reg));
    }
  }

  void setFlags(int result) {
    zeroFlag = (result & 0xFF) == 0;
    signFlag = (result & 0x80) != 0;
    carryFlag = result > 0xFF || result < 0;
    overflowFlag = (result > 127) || (result < -128);
  }

  void setFlags16(int result) {
    zeroFlag = (result & 0xFFFF) == 0;
    signFlag = (result & 0x8000) != 0;
    carryFlag = result > 0xFFFF || result < 0;
    overflowFlag = (result > 32767) || (result < -32768);
  }

  int getRegister8(int reg) {
    switch (reg) {
      case 0:
        return al;
      case 1:
        return cl;
      case 2:
        return dl;
      case 3:
        return bl;
      case 4:
        return ah;
      case 5:
        return ch;
      case 6:
        return dh;
      case 7:
        return bh;
      default:
        return 0;
    }
  }

  void setRegister8(int reg, int value) {
    switch (reg) {
      case 0:
        al = value;
        break;
      case 1:
        cl = value;
        break;
      case 2:
        dl = value;
        break;
      case 3:
        bl = value;
        break;
      case 4:
        ah = value;
        break;
      case 5:
        ch = value;
        break;
      case 6:
        dh = value;
        break;
      case 7:
        bh = value;
        break;
    }
  }

  int getRegister16(int reg) {
    switch (reg) {
      case 0:
        return ax;
      case 1:
        return cx;
      case 2:
        return dx;
      case 3:
        return bx;
      case 4:
        return sp;
      case 5:
        return bp;
      case 6:
        return si;
      case 7:
        return di;
      default:
        return 0;
    }
  }

  void setRegister16(int reg, int value) {
    switch (reg) {
      case 0:
        ax = value;
        break;
      case 1:
        cx = value;
        break;
      case 2:
        dx = value;
        break;
      case 3:
        bx = value;
        break;
      case 4:
        sp = value;
        break;
      case 5:
        bp = value;
        break;
      case 6:
        si = value;
        break;
      case 7:
        di = value;
        break;
    }
  }

  void handleInterrupt(int intNum) {
    if (intNum == 0x21) {
      switch (ah) {
        case 0x01: // Leer carácter
          _debug('Esperando entrada...');
          if (pendingInput != null && pendingInput!.isNotEmpty) {
            al = pendingInput!.codeUnitAt(0);
            pendingInput = pendingInput!.substring(1);
            processMove();
          } else {
            running = false;
          }
          break;

        case 0x02: // Escribir carácter
          consoleOutput.add(String.fromCharCode(dl));
          break;

        case 0x09: // Escribir string
          var str = StringBuffer();
          var addr = dx;
          while (memory[addr] != 0x24) {
            // '$'
            str.write(String.fromCharCode(memory[addr++]));
          }
          consoleOutput.add(str.toString());
          break;

        case 0x4C: // Terminar programa
          running = false;
          break;
      }
    }
  }

  void processMove() {
    if (al >= '1'.codeUnitAt(0) && al <= '9'.codeUnitAt(0)) {
      int pos = al - '1'.codeUnitAt(0);
      if (memory[boardOffset + pos] == 32) {
        memory[boardOffset + pos] =
            (ax & 1) == 0 ? 'X'.codeUnitAt(0) : 'O'.codeUnitAt(0);
        showGameBoard();
        checkGameEnd();
      } else {
        consoleOutput.add('¡Movimiento inválido! Casilla ocupada.');
      }
    }
  }

  void showGameBoard() {
    StringBuffer board = StringBuffer();
    board.writeln('\n=== TICTACTOE ===');
    for (int i = 0; i < 9; i += 3) {
      board.writeln(
          ' ${getBoardCell(i)} | ${getBoardCell(i + 1)} | ${getBoardCell(i + 2)} ');
      if (i < 6) board.writeln('---+---+---');
    }
    consoleOutput.add(board.toString());
  }

  String getBoardCell(int pos) {
    return String.fromCharCode(memory[boardOffset + pos]);
  }

  void checkGameEnd() {
    // Verificar filas
    for (int i = 0; i < 9; i += 3) {
      if (checkWinningLine(i, i + 1, i + 2)) return;
    }
    // Verificar columnas
    for (int i = 0; i < 3; i++) {
      if (checkWinningLine(i, i + 3, i + 6)) return;
    }
    // Verificar diagonales
    if (checkWinningLine(0, 4, 8)) return;
    if (checkWinningLine(2, 4, 6)) return;

    // Verificar empate
    bool isFull = true;
    for (int i = 0; i < 9; i++) {
      if (memory[boardOffset + i] == 32) {
        isFull = false;
        break;
      }
    }
    if (isFull) {
      consoleOutput.add('\n¡Empate!\n');
      running = false;
    }
  }

  bool checkWinningLine(int a, int b, int c) {
    if (memory[boardOffset + a] != 32 &&
        memory[boardOffset + a] == memory[boardOffset + b] &&
        memory[boardOffset + a] == memory[boardOffset + c]) {
      consoleOutput.add(
          '\n¡Jugador ${String.fromCharCode(memory[boardOffset + a])} ha ganado!\n');
      running = false;
      return true;
    }
    return false;
  }

  int fetchWord() {
    return memory[ip++] | (memory[ip++] << 8);
  }

  void push(int value) {
    sp -= 2;
    memory[sp] = value & 0xFF;
    memory[sp + 1] = (value >> 8) & 0xFF;
  }

  int pop() {
    int value = memory[sp] | (memory[sp + 1] << 8);
    sp += 2;
    return value;
  }

  void provideInput(String input) {
    pendingInput = input;
    _debug('Input recibido: $input');

    if (!running) {
      running = true;
      while (running && pendingInput != null) {
        step();
      }
    }
  }

  List<String> getOutput() => List.from(consoleOutput);
}

extension HexString on int {
  String toHexString() =>
      '0x${toRadixString(16).padLeft(2, '0').toUpperCase()}';
}
