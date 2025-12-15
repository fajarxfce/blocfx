# Changelog

All notable changes to blocfx will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-12-15

### Added

- **State Persistence** - Automatic state persistence with hydrated pattern
- `PersistedBlocFx<Event, State, Effect>` - BlocFx with built-in state persistence
- `PersistedCubitfx<State, Effect>` - Cubitfx with built-in state persistence
- `BlocFxPersistence` - Global persistence manager for initialization
- `BlocStorage` - Abstract interface for custom storage implementations
- `SharedPreferencesStorage` - Default storage implementation using SharedPreferences
- `PersistenceConfig` - Configuration class for customizing persistence behavior
- Auto-save with debouncing to prevent excessive I/O operations
- Auto-restore state on bloc/cubit initialization (hydrated pattern)
- Synchronous state restoration for instant hydration
- `init()` method in BlocStorage interface for storage initialization
- `readSync()` method for synchronous state reading
- Support for selective persistence with `shouldPersist()` override
- Skip duplicate saves with configurable `skipDuplicates` option
- Optional clear on logout with `clearOnLogout` configuration

### Changed

- Package description updated to include state persistence features
- Storage backends now implement `init()` for proper initialization
- Type-safe persistence without runtime casting

### Features

- **Zero Boilerplate** - State automatically restored on bloc creation
- **Storage Agnostic** - Easy to implement custom storage (Hive, Isar, SQLite, etc.)
- **Type-Safe** - Full type safety with JSON serialization/deserialization
- **Flexible** - Configure debounce time, skip duplicates, and persistence conditions
- **Error Resilient** - Graceful error handling, persistence failures won't crash the app
- **Clean API** - Simple `toJson()` and `fromJson()` methods for state serialization

### Dependencies

- Added `shared_preferences: ^2.3.4` for default storage implementation

## [0.1.1] - 2024-11-20

### Added

- `CubitFx<State, Effect>` - Core class extending `Cubit` with effect support
- `CubitfxListener<C, S, E>` - Widget for listening to Cubit effects without rebuilding
- Full Cubit support alongside existing Bloc functionality
- Cubit effects can be handled separately from state changes

### Changed

- Fixed generic type constraints in `CubitfxListener` to properly support Cubit classes

## [0.1.0] - 2024-11-03

### Added

- Initial release of bloc_with_effect package
- `BlocWithEffect<Event, State, Effect>` - Core class extending `Bloc` with effect support
- `BlocEffectConsumer<B, Event, S, E>` - Widget that handles both state changes and effects
- `BlocEffectListener<B, Event, S, E>` - Widget that only listens to effects without rebuilding
- Stream-based effect system for handling single-shot events
- `emitEffect()` method for emitting side-effects
- `effects` stream for subscribing to effects
- Full type safety with generic parameters for Event, State, and Effect types
- Support for conditional effect listening with `listenWhen`
- Support for conditional state rebuilding with `buildWhen`
- Compatible with existing flutter_bloc patterns and widgets
- Comprehensive documentation and examples
- Unit tests for core functionality

### Features

- Separates UI state from single-shot events (navigation, dialogs, snackbars)
- Works seamlessly with BlocProvider, BlocBuilder, and BlocSelector
- No breaking changes to flutter_bloc API
- Automatic effect stream disposal on bloc close
- Support for testing with bloc_test package

### Documentation

- Complete README with usage examples
- API documentation for all public classes
- Migration guide from flutter_bloc
- Best practices for state vs effect usage
- Testing examples

[0.1.0]: https://github.com/yourusername/bloc_with_effect/releases/tag/v0.1.0
