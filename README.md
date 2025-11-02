# blocfx

A Flutter package that extends flutter_bloc with Effect streams for handling single-shot events separately from state. Inspired by MVI (Model-View-Intent) architecture pattern.

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

bloc_with_effect separates State (UI representation) from Effects (single-shot events):

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
  bloc_with_effect: ^0.1.0
```

## Usage

### 1. Create your Bloc with Effects

```dart
import 'package:bloc_with_effect/bloc_with_effect.dart';

// Define effects
abstract class LoginEffect {}
class NavigateToDashboard extends LoginEffect {}
class ShowErrorDialog extends LoginEffect {
  final String message;
  ShowErrorDialog(this.message);
}

// Define state
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
}

// Create Bloc with Effects
class LoginBloc extends BlocWithEffect<LoginEvent, LoginState, LoginEffect> {
  final AuthRepository _authRepository;

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

### 2. Consume Effects in UI

Use BlocEffectConsumer to handle both state changes and effects:

```dart
import 'package:bloc_with_effect/bloc_with_effect.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(authRepository),
      child: BlocEffectConsumer<LoginBloc, LoginEvent, LoginState, LoginEffect>(
        // Handle state changes (rebuilds UI)
        builder: (context, state) {
          return Column(
            children: [
              if (state.isLoading)
                CircularProgressIndicator(),
              TextField(
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

        // Handle effects (single-shot events)
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
      ),
    );
  }
}
```

### 3. Or use BlocEffectListener for effects only

When you only need to listen to effects without rebuilding:

```dart
BlocEffectListener<LoginBloc, LoginEvent, LoginState, LoginEffect>(
  listener: (context, effect) {
    if (effect is NavigateToDashboard) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  },
  child: YourWidget(),
)
```

## Advanced Usage

### Using BlocSelector for optimized rebuilds

```dart
BlocSelector<LoginBloc, LoginState, bool>(
  selector: (state) => state.isLoading,
  builder: (context, isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : () => context.read<LoginBloc>()
          .add(LoginSubmittedEvent()),
      child: Text('Login'),
    );
  },
)
```

### Conditional effect listening

```dart
BlocEffectListener<LoginBloc, LoginEvent, LoginState, LoginEffect>(
  listenWhen: (effect) => effect is ShowErrorDialog,
  listener: (context, effect) {
    // Only handles ShowErrorDialog effects
  },
  child: YourWidget(),
)
```

## Testing

Testing blocs with effects is straightforward:

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
```

## API Reference

### BlocWithEffect

```dart
abstract class BlocWithEffect<Event, State, Effect> extends Bloc<Event, State> {
  Stream<Effect> get effects;
  void emitEffect(Effect effect);
}
```

### BlocEffectConsumer

Widget that rebuilds on state changes AND listens to effects.

```dart
BlocEffectConsumer<B extends BlocWithEffect<Event, S, E>, Event, S, E>({
  required Widget Function(BuildContext context, S state) builder,
  required void Function(BuildContext context, E effect) effectListener,
  bool Function(S previous, S current)? buildWhen,
  bool Function(E effect)? listenWhen,
})
```

### BlocEffectListener

Widget that only listens to effects without rebuilding.

```dart
BlocEffectListener<B extends BlocWithEffect<Event, S, E>, Event, S, E>({
  required void Function(BuildContext context, E effect) listener,
  bool Function(E effect)? listenWhen,
  required Widget child,
})
```

## Migration from flutter_bloc

1. Change `extends Bloc` to `extends BlocWithEffect`
2. Add Effect type parameter to your Bloc class
3. Replace state-based navigation/dialogs with `emitEffect()`
4. Use `BlocEffectConsumer` or `BlocEffectListener` in your UI
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

// After
class LoginBloc extends BlocWithEffect<LoginEvent, LoginState, LoginEffect> {
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
```

## License

MIT License

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Credits

Created by the team.

Inspired by MVI pattern from Android development and side-effect handling patterns from other reactive frameworks.
