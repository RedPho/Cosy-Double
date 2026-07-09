import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final int id;
  final int? sessionId;
  final int userId;
  final String title;
  final bool isCompleted;
  final bool isActive;

  const Task({
    required this.id,
    this.sessionId,
    required this.userId,
    required this.title,
    required this.isCompleted,
    this.isActive = false,
  });

  @override
  List<Object?> get props => [id, sessionId, userId, title, isCompleted, isActive];
}
