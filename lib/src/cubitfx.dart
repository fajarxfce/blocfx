import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

abstract class Cubitfx<T, E> extends Cubit<T> {
  Cubitfx(super.initialState);
  final _effectController = StreamController<E>.broadcast();
  Stream<E> get effects => _effectController.stream;

  void emitEffect(E effect) {
    if (!_effectController.isClosed) {
      _effectController.add(effect);
    }
  }

  @override
  Future<void> close() {
    _effectController.close();
    return super.close();
  }
}
