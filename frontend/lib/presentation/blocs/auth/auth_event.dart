import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class UpdateNicknameRequested extends AuthEvent {
  final String username;

  const UpdateNicknameRequested({required this.username});

  @override
  List<Object?> get props => [username];
}

class LoggedOut extends AuthEvent {}

class LoginAsGuestRequested extends AuthEvent {
  final String? username;

  const LoginAsGuestRequested({this.username});

  @override
  List<Object?> get props => [username];
}

