import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocfx.dart';

class BlocFxConsumer<B extends BlocFx<Event, S, E>, Event, S, E>
    extends StatefulWidget {
  const BlocFxConsumer({
    super.key,
    required this.builder,
    required this.effectListener,
    this.bloc,
    this.buildWhen,
    this.listenWhen,
  });

  final B? bloc;

  final Widget Function(BuildContext context, S state) builder;

  final void Function(BuildContext context, E effect) effectListener;

  final bool Function(S previous, S current)? buildWhen;

  final bool Function(E effect)? listenWhen;

  @override
  State<BlocFxConsumer<B, Event, S, E>> createState() =>
      _BlocFxConsumerState<B, Event, S, E>();
}

class _BlocFxConsumerState<B extends BlocFx<Event, S, E>, Event, S, E>
    extends State<BlocFxConsumer<B, Event, S, E>> {
  late B _bloc;
  StreamSubscription<E>? _effectSubscription;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<B>();
    _subscribeToEffects();
  }

  @override
  void didUpdateWidget(BlocFxConsumer<B, Event, S, E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? _bloc;
    final currentBloc = widget.bloc ?? _bloc;
    if (oldBloc != currentBloc) {
      _effectSubscription?.cancel();
      _bloc = currentBloc;
      _subscribeToEffects();
    }
  }

  @override
  void dispose() {
    _effectSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToEffects() {
    _effectSubscription = _bloc.effects.listen((effect) {
      if (widget.listenWhen?.call(effect) ?? true) {
        widget.effectListener(context, effect);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      bloc: _bloc,
      buildWhen: widget.buildWhen,
      builder: widget.builder,
    );
  }
}
