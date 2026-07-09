import '../../domain/entities/room.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/room_repository.dart';
import '../datasources/remote_data_source.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RemoteDataSource remoteDataSource;

  RoomRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Room>> getRooms() async {
    return await remoteDataSource.getRooms();
  }

  @override
  Future<Session> startSession(int roomId) async {
    return await remoteDataSource.startSession(roomId);
  }

  @override
  Future<Task> addTask(int sessionId, String title) async {
    return await remoteDataSource.addTask(sessionId, title);
  }

  @override
  Future<Task> completeTask(int taskId) async {
    return await remoteDataSource.completeTask(taskId);
  }

  @override
  Future<Task> activateTask(int taskId) async {
    return await remoteDataSource.activateTask(taskId);
  }

  @override
  Future<Map<String, dynamic>> terminateSession(int sessionId) async {
    return await remoteDataSource.terminateSession(sessionId);
  }
}
