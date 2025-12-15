/// Configuration for state persistence behavior.
class PersistenceConfig {
  /// Duration to wait before saving state after an emit.
  /// This prevents excessive I/O operations.
  final Duration debounceTime;

  /// Whether to clear persisted state on logout or app termination.
  final bool clearOnLogout;

  /// Whether to skip saving when state is unchanged.
  final bool skipDuplicates;

  const PersistenceConfig({
    this.debounceTime = const Duration(milliseconds: 300),
    this.clearOnLogout = false,
    this.skipDuplicates = true,
  });
}
