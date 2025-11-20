import 'dart:async';
import 'package:blocfx/blocfx.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CubitFxConsumer<B extends Cubitfx<S, E>, S, E> extends StatefulWidget {
  const CubitFxConsumer({
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
  State<CubitFxConsumer<B, S, E>> createState() =>
      _CubitFxConsumerState<B, S, E>();
}

class _CubitFxConsumerState<B extends Cubitfx<S, E>, S, E>
    extends State<CubitFxConsumer<B, S, E>> {
  late B _bloc;
  StreamSubscription<E>? _effectSubscription;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<B>();
    _subscribeToEffects();
  }

  @override
  void didUpdateWidget(CubitFxConsumer<B, S, E> oldWidget) {
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
