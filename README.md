# blocfx

A Flutter package that extends flutter_bloc with **Effect streams** for handling single-shot events and **automatic state persistence**. Inspired by MVI (Model-View-Intent) architecture pattern with hydrated state support.

## Features

✨ **Effect Streams** - Separate single-shot events from state
💾 **State Persistence** - Automatic save/restore with hydrated pattern  
🔌 **Storage Agnostic** - Easy custom storage implementation (Hive, Isar, etc.)
⚡ **Zero Boilerplate** - State automatically restored on initialization
🎯 **Type-Safe** - Full type safety without runtime casting
🛡️ **Error Resilient** - Graceful error handling, won't crash your app

## The Problem

In traditional BLoC pattern, developers often misuse State for single-shot events like navigation or showing dialogs:

```dart
// Bad practice: Using state for navigation
abstract class LoginState {}
class LoginSuccess extends LoginState {} // This gets emitted for navigation
class LoginError extends LoginState {
  final String message;
  LoginError(this.message);
}

// Problems:
// 1. State gets replaced - can't show error AND navigate
// 2. Navigation logic mixed with UI state
// 3. Difficult to handle multiple events simultaneously
```

## The Solution

blocfx separates State (UI representation) from Effects (single-shot events):

```dart
// State represents UI
class LoginState {
  final bool isLoading;
  final String email;
  final String password;
}

// Effects represent single-shot events
abstract class LoginEffect {}
class NavigateToDashboard extends LoginEffect {}
class ShowErrorDialog extends LoginEffect {
  final String message;
  ShowErrorDialog(this.message);
}
```

## Installation

Add to your pubspec.yaml:

```yaml
dependencies:
  blocfx: ^0.2.0
```

## Quick Start

### 1. Initialize Persistence (Optional)

If you want state persistence, initialize it in your `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize state persistence
  await BlocFxPersistence.initialize();

  runApp(MyApp());
}
```

### 2. Create Your Bloc with Effects (and optional persistence)

```dart
import 'package:blocfx/blocfx.dart';

// Define effects
abstract class LoginEffect {}
class NavigateToDashboard extends LoginEffect {}
class ShowErrorDialog extends LoginEffect {
  final String message;
  ShowErrorDialog(this.message);
}

// Define state with JSON serialization for persistence
class LoginState {
  final bool isLoading;
  final String email;
  final String password;

  LoginState({
    required this.isLoading,
    required this.email,
    required this.password,
  });

  LoginState copyWith({bool? isLoading, String? email, String? password}) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  // Serialization for persistence
  Map<String, dynamic> toJson() => {
    'isLoading': isLoading,
    'email': email,
    'password': password,
  };

  factory LoginState.fromJson(Map<String, dynamic> json) => LoginState(
    isLoading: json['isLoading'] ?? false,
    email: json['email'] ?? '',
    password: json['password'] ?? '',
  );
}

// Use PersistedBlocFx for automatic state persistence
class LoginBloc extends PersistedBlocFx<LoginEvent, LoginState, LoginEffect> {
  final AuthRepository _authRepository;

  LoginBloc(this._authRepository)
      : super(LoginState(isLoading: false, email: '', password: ''));

  @override
  String get storageKey => 'login_bloc'; // Unique key for storage

  @override
  LoginState fromJson(Map<String, dynamic> json) => LoginState.fromJson(json);

  @override
  Map<String, dynamic> toJson(LoginState state) => state.toJson();

  // Optional: Customize persistence behavior
  @override
  PersistenceConfig get config => const PersistenceConfig(
    debounceTime: Duration(milliseconds: 500),
    skipDuplicates: true,
  );

  // Optional: Control which states to persist
  @override
  bool shouldPersist(LoginState state) => !state.isLoading;
}
```

### 3. Handle Effects in UI

```dart
BlocFxConsumer<LoginBloc, LoginEvent, LoginState, LoginEffect>(
  builder: (context, state) {
    return Column(
      children: [
        if (state.isLoading) CircularProgressIndicator(),
        TextField(
          initialValue: state.email, // Auto-filled from persisted state!
          onChanged: (value) => context.read<LoginBloc>()
              .add(EmailChangedEvent(value)),
        ),
        ElevatedButton(
          onPressed: () => context.read<LoginBloc>()
              .add(LoginSubmittedEvent()),
          child: Text('Login'),
        ),
      ],
    );
  },
  effectListener: (context, effect) {
    if (effect is NavigateToDashboard) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (effect is ShowErrorDialog) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text(effect.message),
        ),
      );
    }
  },
)
```

## Installation

## Advanced Usage

### State Persistence

#### Custom Storage Implementation

You can implement custom storage backends (Hive, Isar, SQLite, etc.):

```dart
import 'package:blocfx/blocfx.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveStorage implements BlocStorage {
  Box? _box;

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('blocfx_storage');
  }

  @override
  Map<String, dynamic>? readSync(String key) {
    try {
      return _box?.get(key) as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> write(String key, Map<String, dynamic> data) async {
    await _box?.put(key, data);
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    return readSync(key);
  }

  @override
  Future<void> delete(String key) async {
    await _box?.delete(key);
  }

  @override
  Future<void> clear() async {
    await _box?.clear();
  }
}

// Initialize with custom storage
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BlocFxPersistence.initialize(storage: HiveStorage());
  runApp(MyApp());
}
```

#### Persistence Configuration

Customize persistence behavior per bloc:

```dart
class LoginBloc extends PersistedBlocFx<LoginEvent, LoginState, LoginEffect> {
  @override
  PersistenceConfig get config => const PersistenceConfig(
    debounceTime: Duration(milliseconds: 300), // Wait before saving
    skipDuplicates: true, // Skip saving unchanged states
    clearOnLogout: false, // Keep state after bloc closes
  );

  @override
  bool shouldPersist(LoginState state) {
    // Don't persist loading states
    return !state.isLoading;
  }
}
```

#### Clear Persisted State

```dart
// Clear specific bloc state
await loginBloc.clearPersistedState();

// Clear all persisted data
await BlocFxPersistence.clearAll();
```

### Using BlocFx Without Persistence

If you don't need persistence, use regular `BlocFx`:

```dart
class LoginBloc extends BlocFx<LoginEvent, LoginState, LoginEffect> {
  LoginBloc(this._authRepository)
      : super(LoginState(isLoading: false, email: '', password: '')) {
    on<LoginSubmittedEvent>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmittedEvent event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      await _authRepository.login(state.email, state.password);
      emit(state.copyWith(isLoading: false));
      emitEffect(NavigateToDashboard()); // Emit effect for navigation
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      emitEffect(ShowErrorDialog(e.toString())); // Emit effect for dialog
    }
  }
}
```

### Using with Cubit (Simpler state management)

#### With Persistence

```dart
import 'package:blocfx/blocfx.dart';

// Define effects
abstract class ProfileEffect {}
class ShowSuccessMessage extends ProfileEffect {
  final String message;
  ShowSuccessMessage(this.message);
}

// Define state with JSON serialization
class ProfileState {
  final bool isLoading;
  final String name;
  final String email;

  ProfileState({
    required this.isLoading,
    required this.name,
    required this.email,
  });

  ProfileState copyWith({bool? isLoading, String? name, String? email}) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() => {
    'isLoading': isLoading,
    'name': name,
    'email': email,
  };

  factory ProfileState.fromJson(Map<String, dynamic> json) => ProfileState(
    isLoading: json['isLoading'] ?? false,
    name: json['name'] ?? '',
    email: json['email'] ?? '',
  );
}

// Use PersistedCubitfx for automatic state persistence
class ProfileCubit extends PersistedCubitfx<ProfileState, ProfileEffect> {
  final ProfileRepository _repository;

  ProfileCubit(this._repository)
      : super(ProfileState(isLoading: false, name: '', email: ''));

  @override
  String get storageKey => 'profile_cubit';

  @override
  ProfileState fromJson(Map<String, dynamic> json) => ProfileState.fromJson(json);

  @override
  Map<String, dynamic> toJson(ProfileState state) => state.toJson();

  Future<void> updateProfile(String name, String email) async {
    emit(state.copyWith(isLoading: true));

    try {
      await _repository.update(name, email);
      emit(state.copyWith(isLoading: false, name: name, email: email));
      emitEffect(ShowSuccessMessage('Profile updated successfully'));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      emitEffect(ShowSuccessMessage('Failed to update profile'));
    }
  }
}
```

#### Consume Cubit Effects in UI

```dart
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(profileRepository),
      child: Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: CubitfxListener<ProfileCubit, ProfileState, ProfileEffect>(
          listener: (context, effect) {
            if (effect is ShowSuccessMessage) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(effect.message)),
              );
            }
          },
          child: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state.isLoading) {
                return Center(child: CircularProgressIndicator());
              }
              return Column(
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Name'),
                    controller: TextEditingController(text: state.name),
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Email'),
                    controller: TextEditingController(text: state.email),
                  ),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileCubit>()
                        .updateProfile('New Name', 'new@email.com'),
                    child: Text('Update'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
```

### Conditional Effect Listening

```dart
BlocFxListener<LoginBloc, LoginEvent, LoginState, LoginEffect>(
  listener: (context, effect) {
    if (effect is NavigateToDashboard) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  },
  child: YourWidget(),
)
```

### Using with Cubit (Simpler state management)

#### 1. Create your Cubit with Effects

```dart
import 'package:blocfx/blocfx.dart';

// Define effects
abstract class ProfileEffect {}
class ShowSuccessMessage extends ProfileEffect {
  final String message;
  ShowSuccessMessage(this.message);
}
class NavigateToSettings extends ProfileEffect {}

// Define state
class ProfileState {
  final bool isLoading;
  final String name;
  final String email;

  ProfileState({
    required this.isLoading,
    required this.name,
    required this.email,
  });

  ProfileState copyWith({bool? isLoading, String? name, String? email}) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}

// Create Cubit with Effects
class ProfileCubit extends Cubitfx<ProfileState, ProfileEffect> {
  final ProfileRepository _repository;

  ProfileCubit(this._repository)
      : super(ProfileState(isLoading: false, name: '', email: ''));

  Future<void> updateProfile(String name, String email) async {
    emit(state.copyWith(isLoading: true));

    try {
      await _repository.update(name, email);
      emit(state.copyWith(isLoading: false, name: name, email: email));
      emitEffect(ShowSuccessMessage('Profile updated successfully'));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      emitEffect(ShowSuccessMessage('Failed to update profile'));
    }
  }
}
```

#### 2. Consume Cubit Effects in UI

```dart
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(profileRepository),
      child: Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: CubitfxListener<ProfileCubit, ProfileState, ProfileEffect>(
          listener: (context, effect) {
            if (effect is ShowSuccessMessage) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(effect.message)),
              );
            } else if (effect is NavigateToSettings) {
              Navigator.pushNamed(context, '/settings');
            }
          },
          child: BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state.isLoading) {
                return Center(child: CircularProgressIndicator());
              }
              return Column(
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Name'),
                    controller: TextEditingController(text: state.name),
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Email'),
                    controller: TextEditingController(text: state.email),
                  ),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileCubit>()
                        .updateProfile('New Name', 'new@email.com'),
                    child: Text('Update'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
```

### Conditional Effect Listening

```dart
BlocFxListener<LoginBloc, LoginEvent, LoginState, LoginEffect>(
  listenWhen: (effect) => effect is ShowErrorDialog,
  listener: (context, effect) {
    // Only handles ShowErrorDialog effects
  },
  child: YourWidget(),
)
```

## Testing

Testing blocs with effects and persistence:

```dart
test('emits NavigateToDashboard effect on successful login', () async {
  final authRepository = MockAuthRepository();
  when(() => authRepository.login(any(), any()))
      .thenAnswer((_) async => User());

  final bloc = LoginBloc(authRepository);

  bloc.add(LoginSubmittedEvent());

  await expectLater(
    bloc.effects,
    emits(isA<NavigateToDashboard>()),
  );
});

test('emits ShowErrorDialog effect on login failure', () async {
  final authRepository = MockAuthRepository();
  when(() => authRepository.login(any(), any()))
      .thenThrow(Exception('Invalid credentials'));

  final bloc = LoginBloc(authRepository);

  bloc.add(LoginSubmittedEvent());

  await expectLater(
    bloc.effects,
    emits(isA<ShowErrorDialog>()),
  );
});

test('persists and restores state correctly', () async {
  // Initialize with in-memory storage for testing
  await BlocFxPersistence.initialize(storage: InMemoryStorage());

  final bloc1 = LoginBloc(authRepository);
  bloc1.add(EmailChangedEvent('test@example.com'));
  await Future.delayed(Duration(milliseconds: 500)); // Wait for debounce
  await bloc1.close();

  // Create new bloc - should restore state
  final bloc2 = LoginBloc(authRepository);
  expect(bloc2.state.email, equals('test@example.com'));
});
```

## API Reference

### BlocFx

```dart
abstract class BlocFx<Event, State, Effect> extends Bloc<Event, State> {
  Stream<Effect> get effects;
  void emitEffect(Effect effect);
}
```

### Cubitfx

```dart
abstract class Cubitfx<State, Effect> extends Cubit<State> {
  Stream<Effect> get effects;
  void emitEffect(Effect effect);
}
```

### PersistedBlocFx

```dart
abstract class PersistedBlocFx<Event, State, Effect> extends BlocFx<Event, State, Effect> {
  String get storageKey;
  Map<String, dynamic> toJson(State state);
  State fromJson(Map<String, dynamic> json);
  PersistenceConfig get config;
  bool shouldPersist(State state);
  Future<void> clearPersistedState();
}
```

### PersistedCubitfx

```dart
abstract class PersistedCubitfx<State, Effect> extends Cubitfx<State, Effect> {
  String get storageKey;
  Map<String, dynamic> toJson(State state);
  State fromJson(Map<String, dynamic> json);
  PersistenceConfig get config;
  bool shouldPersist(State state);
  Future<void> clearPersistedState();
}
```

### BlocFxPersistence

```dart
class BlocFxPersistence {
  static Future<void> initialize({BlocStorage? storage});
  static BlocStorage get storage;
  static Future<void> clearAll();
  static bool get isInitialized;
}
```

### BlocStorage

```dart
abstract class BlocStorage {
  Future<void> init();
  Future<void> write(String key, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> read(String key);
  Map<String, dynamic>? readSync(String key);
  Future<void> delete(String key);
  Future<void> clear();
}
```

### PersistenceConfig

```dart
class PersistenceConfig {
  final Duration debounceTime;
  final bool clearOnLogout;
  final bool skipDuplicates;

  const PersistenceConfig({
    this.debounceTime = const Duration(milliseconds: 300),
    this.clearOnLogout = false,
    this.skipDuplicates = true,
  });
}
```

### BlocFxConsumer

Widget that rebuilds on state changes AND listens to effects.

```dart
BlocFxConsumer<B extends BlocFx<Event, S, E>, Event, S, E>({
  required Widget Function(BuildContext context, S state) builder,
  required void Function(BuildContext context, E effect) effectListener,
  bool Function(S previous, S current)? buildWhen,
  bool Function(E effect)? listenWhen,
})
```

### BlocFxListener

Widget that only listens to effects without rebuilding.

```dart
BlocFxListener<B extends BlocFx<Event, S, E>, Event, S, E>({
  required void Function(BuildContext context, E effect) listener,
  bool Function(E effect)? listenWhen,
  required Widget child,
})
```

### CubitfxListener

Widget that only listens to Cubit effects without rebuilding.

```dart
CubitfxListener<C extends Cubitfx<S, E>, S, E>({
  required void Function(BuildContext context, E effect) listener,
  bool Function(E effect)? listenWhen,
  required Widget child,
})
```

## Migration Guide

### From flutter_bloc to blocfx

#### Adding Effects to Existing Bloc

1. Change `extends Bloc` to `extends BlocFx`
2. Add Effect type parameter to your Bloc class
3. Replace state-based navigation/dialogs with `emitEffect()`
4. Use `BlocFxConsumer` or `BlocFxListener` in your UI
5. Handle effects in `effectListener` callback

Example:

```dart
// Before
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginSubmitted>((event, emit) async {
      try {
        await login();
        emit(LoginSuccess()); // State used for navigation
      } catch (e) {
        emit(LoginError(e.toString()));
      }
    });
  }
}

// After - with effects only
class LoginBloc extends BlocFx<LoginEvent, LoginState, LoginEffect> {
  LoginBloc() : super(LoginState(isLoading: false)) {
    on<LoginSubmitted>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      try {
        await login();
        emit(state.copyWith(isLoading: false));
        emitEffect(NavigateToDashboard()); // Effect for navigation
      } catch (e) {
        emit(state.copyWith(isLoading: false));
        emitEffect(ShowErrorDialog(e.toString())); // Effect for error
      }
    });
  }
}

// After - with effects AND persistence
class LoginBloc extends PersistedBlocFx<LoginEvent, LoginState, LoginEffect> {
  LoginBloc() : super(LoginState(isLoading: false)) {
    on<LoginSubmitted>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      try {
        await login();
        emit(state.copyWith(isLoading: false));
        emitEffect(NavigateToDashboard());
      } catch (e) {
        emit(state.copyWith(isLoading: false));
        emitEffect(ShowErrorDialog(e.toString()));
      }
    });
  }

  @override
  String get storageKey => 'login_bloc';

  @override
  LoginState fromJson(Map<String, dynamic> json) => LoginState.fromJson(json);

  @override
  Map<String, dynamic> toJson(LoginState state) => state.toJson();
}
```

### From Cubit to Cubitfx

1. Change `extends Cubit` to `extends Cubitfx` or `extends PersistedCubitfx`
2. Add Effect type parameter to your Cubit class
3. Replace state-based navigation/dialogs with `emitEffect()`
4. Use `CubitfxListener` in your UI
5. Handle effects in `listener` callback
6. Add `toJson()` and `fromJson()` if using persistence

### Adding Persistence to Existing BlocFx

```dart
// Before - BlocFx without persistence
class LoginBloc extends BlocFx<LoginEvent, LoginState, LoginEffect> {
  LoginBloc() : super(LoginState.initial());
}

// After - Add persistence
class LoginBloc extends PersistedBlocFx<LoginEvent, LoginState, LoginEffect> {
  LoginBloc() : super(LoginState.initial());

  @override
  String get storageKey => 'login_bloc';

  @override
  LoginState fromJson(Map<String, dynamic> json) => LoginState.fromJson(json);

  @override
  Map<String, dynamic> toJson(LoginState state) => state.toJson();
}

// Add toJson/fromJson to your state class
class LoginState {
  // ... existing code

  Map<String, dynamic> toJson() => {
    'isLoading': isLoading,
    'email': email,
  };

  factory LoginState.fromJson(Map<String, dynamic> json) => LoginState(
    isLoading: json['isLoading'] ?? false,
    email: json['email'] ?? '',
  );
}
```

## License

MIT License

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Credits

Created by [fajarxfce](https://github.com/fajarxfce).

Inspired by:

- MVI pattern from Android development
- Side-effect handling patterns from reactive frameworks
- Hydrated Bloc pattern for state persistence

## Support

If you find this package helpful, please give it a ⭐ on [GitHub](https://github.com/fajarxfce/blocfx)!
