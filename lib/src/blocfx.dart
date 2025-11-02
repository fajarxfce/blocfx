import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class BlocFx<Event, State, Effect> extends Bloc<Event, State> {
  BlocFx(super.initialState);

  final _effectController = StreamController<Effect>.broadcast();

  Stream<Effect> get effects => _effectController.stream;

  void emitEffect(Effect effect) {
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
