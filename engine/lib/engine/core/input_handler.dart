import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lepiengine/engine/core/input_manager.dart';
import 'scene_manager.dart';
import 'game_object.dart';

/// Handler central para capturar inputs do usuário.
/// Usa SceneManager.instance.current para despachar para objetos ativos.class InputHandler extends StatefulWidget {
class InputHandler extends StatefulWidget {
  final Widget child;

  const InputHandler({super.key, required this.child});

  @override
  State<InputHandler> createState() => _InputHandlerState();
}

class _InputHandlerState extends State<InputHandler> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _dispatchKeyDown(String key) {
    final scene = SceneManager.instance.current;
    if (scene == null) return;

    for (final obj in scene.query<GameObject>()) {
      if (obj is KeyboardControllable) {
        obj.onKeyDown(key);
      }
    }
  }

  void _dispatchKeyUp(String key) {
    final scene = SceneManager.instance.current;
    if (scene == null) return;

    for (final obj in scene.query<GameObject>()) {
      if (obj is KeyboardControllable) {
        obj.onKeyUp(key);
      }
    }
  }

  void _dispatchTapDown(Offset pos) {
    final scene = SceneManager.instance.current;
    if (scene == null) return;

    for (final obj in scene.query<GameObject>()) {
      if (obj is Touchable) {
        if (obj.hitTest(pos)) {
          final localPos = obj.worldToLocal(pos);
          obj.onTapDown(localPos, pos);
        }
      }
    }
  }

  void _dispatchTapUp(Offset pos) {
    final scene = SceneManager.instance.current;
    if (scene == null) return;

    for (final obj in scene.query<GameObject>()) {
      if (obj is Touchable) {
        if (obj.hitTest(pos)) {
          final localPos = obj.worldToLocal(pos);
          obj.onTapUp(localPos, pos);
        }
      }
    }
  }

  void _dispatchDragStart(Offset pos) {
    final scene = SceneManager.instance.current;
    if (scene == null) return;

    for (final obj in scene.query<GameObject>()) {
      if (obj is Touchable) {
        if (obj.hitTest(pos)) {
          final localPos = obj.worldToLocal(pos);
          obj.onDragStart(localPos, pos);
        }
      }
    }
  }

  void _dispatchDragUpdate(Offset pos) {
    final scene = SceneManager.instance.current;
    if (scene == null) return;

    for (final obj in scene.query<GameObject>()) {
      if (obj is Touchable) {
        if (obj.hitTest(pos)) {
          final localPos = obj.worldToLocal(pos);
          obj.onDragUpdate(localPos, pos);
        }
      }
    }
  }

  void _dispatchDragEnd(Offset pos, Offset velocity) {
    final scene = SceneManager.instance.current;
    if (scene == null) return;

    for (final obj in scene.query<GameObject>()) {
      if (obj is Touchable) {
        if (obj.hitTest(pos)) {
          final localPos = obj.worldToLocal(pos);
          obj.onDragEnd(localPos, pos, velocity);
        }
      }
    }
  }

  void _dispatchTapCancel() {
    final scene = SceneManager.instance.current;
    if (scene == null) return;

    for (final obj in scene.query<GameObject>()) {
      if (obj is Touchable) {
        obj.onTapCancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // captura toques na tela toda
      onTapDown: (details) {
        InputManager.instance.touchStart(
          details.hashCode,
          details.localPosition,
        );
        _dispatchTapDown(details.localPosition);
      },
      onTapUp: (details) {
        InputManager.instance.touchEnd(details.hashCode);
        _dispatchTapUp(details.localPosition);
      },
      onTapCancel: () {
        _dispatchTapCancel();
      },
      onPanStart: (details) {
        InputManager.instance.touchStart(
          details.hashCode,
          details.localPosition,
        );
        _dispatchDragStart(details.localPosition);
      },
      onPanUpdate: (details) {
        InputManager.instance.touchMove(
          details.hashCode,
          details.localPosition,
        );
        _dispatchDragUpdate(details.localPosition);
      },
      onPanEnd: (details) {
        InputManager.instance.touchEnd(details.hashCode);
        _dispatchDragEnd(
          details.localPosition,
          details.velocity.pixelsPerSecond,
        );
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          final key = event.logicalKey.keyLabel.isNotEmpty
              ? event.logicalKey.keyLabel
              : event.logicalKey.debugName ?? "";

          if (event is KeyDownEvent) {
            if (!InputManager.instance.isPressed(key)) {
              InputManager.instance.keyDown(key);
              _dispatchKeyDown(key);
            }
          } else if (event is KeyUpEvent) {
            InputManager.instance.keyUp(key);
            _dispatchKeyUp(key);
          } else if (event is KeyRepeatEvent) {
            _dispatchKeyDown(key);
          }
        },
        child: widget.child,
      ),
    );
  }
}
