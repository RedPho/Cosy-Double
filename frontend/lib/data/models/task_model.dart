import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    super.sessionId,
    required super.userId,
    required super.title,
    required super.isCompleted,
    super.isActive = false,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? 0,
      sessionId: json['session_id'],
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'title': title,
      'is_completed': isCompleted,
      'is_active': isActive,
    };
  }
}
