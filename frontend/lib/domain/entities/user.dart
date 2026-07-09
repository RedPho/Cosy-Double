import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String email;
  final String username;
  final int leavesBalance;

  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.leavesBalance,
  });

  @override
  List<Object?> get props => [id, email, username, leavesBalance];
}
