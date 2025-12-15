import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubitfx.dart';
import 'blocfx_persistence.dart';
import 'persistence_config.dart';

/// Base class for Cubitfx with built-in state persistence.
///
/// This is a convenience class that combines Cubitfx with automatic
/// state persistence. Use this when you want persistence without
/// having to use mixins.
///
/// Example usage:
/// ```dart
/// class ProfileCubit extends PersistedCubitfx<ProfileState, ProfileEffect> {
///
///   ProfileCubit() : super(ProfileState.initial());
///
///   @override
///   String get storageKey => 'profile_cubit';
///
///   @override
///   ProfileState fromJson(Map<String, dynamic> json) => ProfileState.fromJson(json);
///
///   @override
///   Map<String, dynamic> toJson(ProfileState state) => state.toJson();
/// }
/// ```
abstract class PersistedCubitfx<State, Effect> extends Cubitfx<State, Effect> {
  PersistedCubitfx(super.initialState);

  Timer? _debounceTimer;
  State? _lastPersistedState;

  /// Unique key for storing this cubit's state.
  /// Must be unique across your app.
  String get storageKey;

  /// Convert state to JSON for storage.
  Map<String, dynamic> toJson(State state);

  /// Convert JSON back to state.
  State fromJson(Map<String, dynamic> json);

  /// Persistence configuration.
  /// Override to customize behavior.
  PersistenceConfig get config => const PersistenceConfig();

  /// Determine if a state should be persisted.
  /// Override to add custom logic.
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
      return null;
    }
  }

  /// Persist current state to storage.
  Future<void> persistState(State state) async {
    if (!BlocFxPersistence.isInitialized) return;
    if (!shouldPersist(state)) return;

    // Skip if state unchanged
    if (config.skipDuplicates && _lastPersistedState == state) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(config.debounceTime, () async {
      try {
        final storage = BlocFxPersistence.storage;
        final data = toJson(state);
        await storage.write(storageKey, data);
        _lastPersistedState = state;
      } catch (e) {
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
