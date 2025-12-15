import '../storage/bloc_storage.dart';
import '../storage/shared_preferences_storage.dart';

/// Global persistence manager for BlocFx.
///
/// Initialize this at app startup to enable state persistence
/// across all BlocFx and Cubitfx instances.
class BlocFxPersistence {
  static BlocStorage? _storage;

  /// Initialize the global storage backend.
  ///
  /// Call this in your main() function before runApp().
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await BlocFxPersistence.initialize();
  ///   runApp(MyApp());
  /// }
  /// ```
  ///
  /// You can provide a custom storage implementation:
  /// ```dart
  /// await BlocFxPersistence.initialize(
  ///   storage: HiveStorage(), // Custom implementation
  /// );
  /// ```
  static Future<void> initialize({BlocStorage? storage}) async {
    _storage = storage ?? SharedPreferencesStorage();
    // Call init() to ensure storage is ready for sync operations
    await _storage!.init();
  }

  static BlocStorage get storage {
    if (_storage == null) {
      throw StateError(
        'BlocFxPersistence not initialized. '
        'Call BlocFxPersistence.initialize() in main() before using persistence.',
      );
    }
    return _storage!;
  }

  static Future<void> clearAll() async {
    await storage.clear();
  }

  static bool get isInitialized => _storage != null;
}
