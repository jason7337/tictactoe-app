# Emulador 8086 y TicTacToe Assembly

Un emulador del procesador Intel 8086 con un juego de TicTacToe implementado en Assembly, desarrollado como proyecto educativo para el curso de Arquitectura de Computadoras.

## 🎯 Descripción

Este proyecto implementa un emulador del procesador Intel 8086 y ejecuta un juego de TicTacToe escrito en lenguaje Assembly. La aplicación está diseñada para ayudar a los estudiantes a comprender los conceptos fundamentales de arquitectura de computadoras y programación en lenguaje de bajo nivel.

## ✨ Características

- Emulador 8086 con conjunto básico de instrucciones
- Juego de TicTacToe completamente funcional en Assembly
- Interfaz gráfica intuitiva desarrollada en Flutter
- Consola integrada para visualizar la salida del programa
- Visualizador de código fuente Assembly
- Sistema de entrada/salida mediante interrupciones DOS

## 🚀 Inicio Rápido

### Prerrequisitos

- Flutter (última versión estable)
- Dart SDK
- Un IDE (VS Code, Android Studio, etc.)

### Instalación

1. Clonar el repositorio:
```bash
git clone https://github.com/jason7337/tictactoe-app.git
```

2. Navegar al directorio del proyecto:
```bash
cd tictactoe-app
```

3. Instalar dependencias:
```bash
flutter pub get
```

4. Ejecutar la aplicación:
```bash
flutter run
```

## 🎮 Cómo Jugar

1. Inicia la aplicación
2. Presiona "Nuevo Juego" para comenzar
3. Usa los botones numéricos (1-9) para hacer tu movimiento
4. Sigue las instrucciones en la consola
5. ¡Intenta ganar haciendo tres en línea!

## 🛠️ Arquitectura del Proyecto

```
lib/
├── emulator/
│   └── emulator_8086.dart    # Implementación del emulador
├── screens/
│   ├── home_screen.dart      # Pantalla principal
│   ├── code_screen.dart      # Visualizador de código
│   └── tournament_screen.dart # Pantalla de torneo
├── utils/
│   └── asm_handler.dart      # Manejador de código Assembly
└── main.dart                 # Punto de entrada
```

## 📝 Detalles Técnicos

### Emulador 8086
- Implementación de registros principales
- Soporte para interrupciones DOS básicas
- Manejo de memoria de 64KB
- Implementación de flags de estado

### Código Assembly
- Formato COM (offset 100h)
- Uso de interrupciones DOS para E/S
- Implementación eficiente de la lógica del juego
- Manejo de datos en memoria

## 🤝 Contribuir

Las contribuciones son bienvenidas. Para contribuir:

1. Fork el proyecto
2. Crea una rama para tu característica (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## ✍️ Autor

- Nombre - [@jason7337](https://github.com/jason7337)

## 🙏 Reconocimientos

- Curso de Arquitectura de Computadoras
- Documentación del procesador Intel 8086
- Comunidad de Flutter y Dart
- Contribuidores del proyecto

## 📞 Contacto

Para preguntas y soporte, por favor contacta a: ulloajason10@gmail.com

---
⌨️ con ❤️ por [Jasson Gomez](https://github.com/jason7337)