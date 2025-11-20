import 'dart:async';

import 'package:blocfx/blocfx.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CubitfxListener<C extends Cubitfx<S, E>, S, E> extends StatefulWidget {
  final C? cubit;
  final void Function(BuildContext context, E effect) listener;
  final Widget child;
  final bool Function(E effect)? listenWhen;
  const CubitfxListener({
    super.key,
    required this.listener,
    required this.child,
    this.cubit,
    this.listenWhen,
  });
  @override
  State<CubitfxListener<C, S, E>> createState() =>
      _CubitfxListenerState<C, S, E>();
}

class _CubitfxListenerState<C extends Cubitfx<S, E>, S, E>
    extends State<CubitfxListener<C, S, E>> {
  late C _cubit;
  StreamSubscription<E>? _effectSubscription;

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ?? context.read<C>();
    _subscribeToEffects();
  }

  @override
  void didUpdateWidget(covariant CubitfxListener<C, S, E> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldCubit = oldWidget.cubit ?? _cubit;
    final currentCubit = widget.cubit ?? _cubit;

    if (oldCubit != currentCubit) {
      _effectSubscription?.cancel();
      _cubit = currentCubit;
      _subscribeToEffects();
    }
  }

  @override
  void dispose() {
    _effectSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToEffects() {
    _effectSubscription = _cubit.effects.listen((effect) {
      if (widget.listenWhen?.call(effect) ?? true) {
        widget.listener(context, effect);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
