import '../../domain/entities/session.dart';

class SessionModel extends Session {
  const SessionModel({
    required super.id,
    required super.roomId,
    required super.userId,
    required super.startedAt,
    super.endedAt,
    super.durationSeconds,
    super.leavesEarned,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] ?? 0,
      roomId: json['room_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : DateTime.now(),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      durationSeconds: json['duration_seconds'],
      leavesEarned: json['leaves_earned'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'user_id': userId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'leaves_earned': leavesEarned,
    };
  }
}
