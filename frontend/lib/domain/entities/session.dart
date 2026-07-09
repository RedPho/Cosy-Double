import 'package:equatable/equatable.dart';

class Session extends Equatable {
  final int id;
  final int roomId;
  final int userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final int? leavesEarned;

  const Session({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.leavesEarned,
  });

  @override
  List<Object?> get props => [id, roomId, userId, startedAt, endedAt, durationSeconds, leavesEarned];
}
