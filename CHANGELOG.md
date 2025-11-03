# Changelog

All notable changes to bloc_with_effect will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
