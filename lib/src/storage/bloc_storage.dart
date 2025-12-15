/// Abstract interface for BlocFx state persistence storage.
///
/// Implement this interface to create custom storage backends
/// like Hive, Isar, SQLite, or any other storage solution.
abstract class BlocStorage {
  /// Initialize the storage backend.
  /// This is called automatically by BlocFxPersistence.initialize().
  Future<void> init() async {}

  /// Write data to storage with the given key.
  Future<void> write(String key, Map<String, dynamic> data);

  /// Read data from storage with the given key.
  Future<Map<String, dynamic>?> read(String key);

  /// Read data synchronously from storage (if supported).
  /// Returns null if sync read is not supported or no data exists.
  Map<String, dynamic>? readSync(String key) => null;

  /// Delete data associated with the given key.
  Future<void> delete(String key);

  /// Clear all stored data.
  Future<void> clear();
}
