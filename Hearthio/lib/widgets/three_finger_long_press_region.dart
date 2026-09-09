import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class ThreeFingerLongPressRegion extends StatelessWidget {
  const ThreeFingerLongPressRegion({
    super.key,
    required this.onLongPress,
    required this.child,
    this.duration = const Duration(seconds: 5),
  });

  final VoidCallback onLongPress;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.translucent,
    gestures: {
      _ThreeFingerLongPressGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<
            _ThreeFingerLongPressGestureRecognizer
          >(
            _ThreeFingerLongPressGestureRecognizer.new,
            (recognizer) => recognizer
              ..duration = duration
              ..onLongPress = onLongPress,
          ),
    },
    child: child,
  );
}

class _ThreeFingerLongPressGestureRecognizer
    extends OneSequenceGestureRecognizer {
  static const _requiredPointers = 3;

  final Map<int, Offset> _initialPositions = {};
  Timer? _timer;
  bool _accepted = false;
  bool _sequenceInvalid = false;
  bool _triggered = false;

  Duration duration = const Duration(seconds: 5);
  VoidCallback? onLongPress;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_initialPositions.isEmpty) {
      _accepted = false;
      _sequenceInvalid = false;
      _triggered = false;
    }
    super.addAllowedPointer(event);
    _initialPositions[event.pointer] = event.position;

    if (_initialPositions.length > _requiredPointers) {
      _cancelSequence();
      return;
    }
    if (_initialPositions.length == _requiredPointers && !_sequenceInvalid) {
      _accepted = true;
      resolve(GestureDisposition.accepted);
      _timer?.cancel();
      _timer = Timer(duration, _triggerLongPress);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      final initialPosition = _initialPositions[event.pointer];
      if (initialPosition != null &&
          (event.position - initialPosition).distance > kTouchSlop) {
        _cancelSequence();
      }
    }

    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _initialPositions.remove(event.pointer);
      _cancelSequence();
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void rejectGesture(int pointer) {
    if (!_accepted) _cancelSequence();
  }

  void _cancelSequence() {
    _sequenceInvalid = true;
    _timer?.cancel();
    _timer = null;
    resolve(GestureDisposition.rejected);
  }

  void _triggerLongPress() {
    _timer = null;
    if (_sequenceInvalid ||
        _triggered ||
        _initialPositions.length != _requiredPointers) {
      return;
    }
    _triggered = true;
    invokeCallback<void>('onLongPress', () => onLongPress?.call());
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _timer?.cancel();
    _timer = null;
    _initialPositions.clear();
    _accepted = false;
    _sequenceInvalid = false;
    _triggered = false;
  }

  @override
  String get debugDescription => 'three finger long press';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
