import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String username;

  const RegisterSubmitted({required this.email, required this.password, required this.username});

  @override
  List<Object?> get props => [email, password, username];
}

class GoogleSignInTriggered extends AuthEvent {}

class LoggedOut extends AuthEvent {}

class DeleteAccountRequested extends AuthEvent {}

