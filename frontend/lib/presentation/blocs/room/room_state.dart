import 'package:equatable/equatable.dart';
import '../../../domain/entities/room.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/task.dart';

enum RoomStatus { initial, loading, loaded, inSession, sessionSummary, error }

class RoomState extends Equatable {
  final RoomStatus status;
  final List<Room> rooms;
  final Session? activeSession;
  final List<Task> activeTasks;
  final List<dynamic> activePresenceUsers;
  final List<dynamic> activeInteractions; // List of active emoji animations to render
  final Map<String, dynamic>? sessionSummary; // Leaf count, duration info
  final String? errorMessage;

  const RoomState({
    this.status = RoomStatus.initial,
    this.rooms = const [],
    this.activeSession,
    this.activeTasks = const [],
    this.activePresenceUsers = const [],
    this.activeInteractions = const [],
    this.sessionSummary,
    this.errorMessage,
  });

  RoomState copyWith({
    RoomStatus? status,
    List<Room>? rooms,
    Session? activeSession,
    List<Task>? activeTasks,
    List<dynamic>? activePresenceUsers,
    List<dynamic>? activeInteractions,
    Map<String, dynamic>? sessionSummary,
    String? errorMessage,
  }) {
    return RoomState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      activeSession: activeSession ?? this.activeSession,
      activeTasks: activeTasks ?? this.activeTasks,
      activePresenceUsers: activePresenceUsers ?? this.activePresenceUsers,
      activeInteractions: activeInteractions ?? this.activeInteractions,
      sessionSummary: sessionSummary ?? this.sessionSummary,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        rooms,
        activeSession,
        activeTasks,
        activePresenceUsers,
        activeInteractions,
        sessionSummary,
        errorMessage,
      ];
}
