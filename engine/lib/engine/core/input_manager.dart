import 'package:flutter/material.dart';

class InputManager {
  static final InputManager instance = InputManager._internal();
  InputManager._internal();

  // --- Teclado ---
  final Set<String> _keysPressed = {};

  Set<String> get keysPressed => _keysPressed;

  void keyDown(String key) => _keysPressed.add(key);
  void keyUp(String key) => _keysPressed.remove(key);
  bool isPressed(String key) => _keysPressed.contains(key);

  // --- Touch ---
  final Map<int, Offset> _touches = {}; // <pointerId, posição>

  void touchStart(int pointer, Offset position) {
    _touches[pointer] = position;
  }

  void touchMove(int pointer, Offset position) {
    _touches[pointer] = position;
  }

  void touchEnd(int pointer) {
    _touches.remove(pointer);
  }

  Map<int, Offset> get activeTouches => Map.unmodifiable(_touches);
  bool get hasTouches => _touches.isNotEmpty;
  Offset? get firstTouch => _touches.isNotEmpty ? _touches.values.first : null;
}
