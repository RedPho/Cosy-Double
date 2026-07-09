import '../entities/room.dart';
import '../entities/session.dart';
import '../entities/task.dart';

abstract class RoomRepository {
  Future<List<Room>> getRooms();
  Future<Session> startSession(int roomId);
  Future<Task> addTask(int sessionId, String title);
  Future<Task> completeTask(int taskId);
  Future<Task> activateTask(int taskId);
  Future<Map<String, dynamic>> terminateSession(int sessionId);
}
