import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocfx.dart';
import 'blocfx_persistence.dart';
import 'persistence_config.dart';

/// Base class for BlocFx with built-in state persistence.
///
/// This is a convenience class that combines BlocFx with automatic
/// state persistence. Use this when you want persistence without
/// having to use mixins.
///
/// Example usage:
/// ```dart
/// class LoginBloc extends PersistedBlocFx<LoginEvent, LoginState, LoginEffect> {
///
///   LoginBloc() : super(LoginState.initial());
///
///   @override
///   String get storageKey => 'login_bloc';
///
///   @override
///   LoginState fromJson(Map<String, dynamic> json) => LoginState.fromJson(json);
///
///   @override
///   Map<String, dynamic> toJson(LoginState state) => state.toJson();
/// }
/// ```
abstract class PersistedBlocFx<Event, State, Effect>
    extends BlocFx<Event, State, Effect> {
  PersistedBlocFx(State initialState) : super(initialState) {
    // Try to hydrate state synchronously first
    final hydratedState = _hydrate();
    if (hydratedState != null) {
      emit(hydratedState);
    }
  }

  Timer? _debounceTimer;
  State? _lastPersistedState;

  String get storageKey;

  Map<String, dynamic> toJson(State state);

  State fromJson(Map<String, dynamic> json);

  PersistenceConfig get config => const PersistenceConfig();

  bool shouldPersist(State state) => true;

  /// Try to load state synchronously (hydrated pattern)
  State? _hydrate() {
    if (!BlocFxPersistence.isInitialized) return null;

    try {
      final storage = BlocFxPersistence.storage;
      final data = storage.readSync(storageKey);

      if (data == null) return null;

      return fromJson(data);
    } catch (e) {
      debugPrint('Error hydrating state for $storageKey: $e');
      return null;
    }
  }

  /// Persist current state to storage.
  Future<void> persistState(State state) async {
    if (!BlocFxPersistence.isInitialized) return;
    if (!shouldPersist(state)) return;

    if (config.skipDuplicates && _lastPersistedState == state) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(config.debounceTime, () async {
      try {
        final storage = BlocFxPersistence.storage;
        final data = toJson(state);
        await storage.write(storageKey, data);
        _lastPersistedState = state;
      } catch (e) {
        debugPrint('Error persisting state for $storageKey: $e');
        // Silently fail to prevent app crashes
      }
    });
  }

  /// Clear persisted state from storage.
  Future<void> clearPersistedState() async {
    if (!BlocFxPersistence.isInitialized) return;

    try {
      final storage = BlocFxPersistence.storage;
      await storage.delete(storageKey);
      _lastPersistedState = null;
    } catch (e) {
      debugPrint('Error clearing persisted state for $storageKey: $e');
      // Silently fail
    }
  }

  @override
  void onChange(Change<State> change) {
    super.onChange(change);
    persistState(change.nextState);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    if (config.clearOnLogout) {
      clearPersistedState();
    }
    return super.close();
  }
}
