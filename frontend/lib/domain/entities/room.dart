import 'package:equatable/equatable.dart';

class Room extends Equatable {
  final int id;
  final String name;
  final String category;
  final bool isActive;
  final List<String> activeUsers;

  const Room({
    required this.id,
    required this.name,
    required this.category,
    required this.isActive,
    required this.activeUsers,
  });

  @override
  List<Object?> get props => [id, name, category, isActive, activeUsers];
}
