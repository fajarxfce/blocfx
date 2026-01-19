import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocfx.dart';

class BlocFxListener<B extends BlocFx<Event, S, E>, Event, S, E>
    extends StatefulWidget {
  const BlocFxListener({
    super.key,
    required this.listener,
    this.stateListener,
    required this.child,
    this.bloc,
    this.listenWhen,
    this.stateListenWhen,
  });

  final B? bloc;

  final void Function(BuildContext context, E effect) listener;

  final void Function(BuildContext context, S)? stateListener;

  final Widget child;

  final bool Function(E effect)? listenWhen;

  final bool Function(S previous, S current)? stateListenWhen;

  @override
  State<BlocFxListener<B, Event, S, E>> createState() =>
      _BlocFxListenerState<B, Event, S, E>();
}

class _BlocFxListenerState<B extends BlocFx<Event, S, E>, Event, S, E>
    extends State<BlocFxListener<B, Event, S, E>> {
  late B _bloc;
  StreamSubscription<E>? _effectSubscription;
  StreamSubscription<S>? _stateSubscription;
  S? _previousState;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<B>();
    _previousState = _bloc.state;
    _subscribeToEffects();
    _subscribeToState();
  }

  @override
  void didUpdateWidget(BlocFxListener<B, Event, S, E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? _bloc;
    final currentBloc = widget.bloc ?? _bloc;
    if (oldBloc != currentBloc) {
      _effectSubscription?.cancel();
      _stateSubscription?.cancel();
      _bloc = currentBloc;
      _previousState = _bloc.state;
      _subscribeToEffects();
      _subscribeToState();
    }
  }

  @override
  void dispose() {
    _effectSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToEffects() {
    _effectSubscription = _bloc.effects.listen((effect) {
      if (widget.listenWhen?.call(effect) ?? true) {
        widget.listener(context, effect);
      }
    });
  }

  void _subscribeToState() {
    if (widget.stateListener == null) return;

    _stateSubscription = _bloc.stream.listen((state) {
      final previous = _previousState;
      if (previous != null) {
        if (widget.stateListenWhen?.call(previous, state) ?? true) {
          widget.stateListener!(context, state);
        }
      }
      _previousState = state;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
