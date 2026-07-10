import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginAsGuestRequested>(_onLoginAsGuestRequested);
    on<UpdateNicknameRequested>(_onUpdateNicknameRequested);
    on<LoggedOut>(_onLoggedOut);
  }

  Future<void> _onLoginAsGuestRequested(LoginAsGuestRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.loginAsGuest(event.username);
      final user = await authRepository.getMe();
      emit(Authenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final isAuth = await authRepository.checkAuthStatus();
      if (isAuth) {
        final user = await authRepository.getMe();
        emit(Authenticated(user: user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onUpdateNicknameRequested(UpdateNicknameRequested event, Emitter<AuthState> emit) async {
    final currentState = state;
    if (currentState is Authenticated) {
      emit(AuthLoading());
      try {
        final updatedUser = await authRepository.updateNickname(event.username);
        emit(Authenticated(user: updatedUser));
      } catch (e) {
        emit(AuthError(message: e.toString()));
        emit(currentState); // Fallback to current authenticated state
      }
    }
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(Unauthenticated());
    }
  }
}
