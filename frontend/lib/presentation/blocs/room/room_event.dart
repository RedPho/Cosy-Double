import 'package:equatable/equatable.dart';
import '../../../domain/entities/task.dart';

abstract class RoomEvent extends Equatable {
  const RoomEvent();

  @override
  List<Object?> get props => [];
}

class FetchRooms extends RoomEvent {}

class StartFocusSession extends RoomEvent {
  final int roomId;

  const StartFocusSession({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class AddSessionTask extends RoomEvent {
  final String title;

  const AddSessionTask({required this.title});

  @override
  List<Object?> get props => [title];
}

class CompleteSessionTask extends RoomEvent {
  final int taskId;

  const CompleteSessionTask({required this.taskId});

  @override
  List<Object?> get props => [taskId];
}

class SetTaskActive extends RoomEvent {
  final int taskId;

  const SetTaskActive({required this.taskId});

  @override
  List<Object?> get props => [taskId];
}

class TerminateFocusSession extends RoomEvent {}

// WebSocket specific events
class ConnectWebSocket extends RoomEvent {
  final int roomId;

  const ConnectWebSocket({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class WebSocketReceived extends RoomEvent {
  final String data;

  const WebSocketReceived({required this.data});

  @override
  List<Object?> get props => [data];
}

class SendSilentInteraction extends RoomEvent {
  final String emoji;

  const SendSilentInteraction({required this.emoji});

  @override
  List<Object?> get props => [emoji];
}

class DisconnectWebSocket extends RoomEvent {}

class RemoveInteraction extends RoomEvent {
  final Map<String, dynamic> interaction;

  const RemoveInteraction({required this.interaction});

  @override
  List<Object?> get props => [interaction];
}
