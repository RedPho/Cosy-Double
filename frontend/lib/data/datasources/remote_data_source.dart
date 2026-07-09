import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../models/session_model.dart';
import '../models/task_model.dart';
import '../models/item_model.dart';
import '../models/inventory_item_model.dart';

class RemoteDataSource {
  final ApiClient apiClient;

  RemoteDataSource({required this.apiClient});

  // Auth Operations
  Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await apiClient.post('/auth/register', {
      'email': email,
      'password': password,
    });
    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Registration failed');
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await apiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Login failed');
    }
    return jsonDecode(response.body);
  }

  Future<UserModel> getMe() async {
    final response = await apiClient.get('/auth/me');
    if (response.statusCode != 200) {
      throw Exception('Failed to get current user');
    }
    return UserModel.fromJson(jsonDecode(response.body));
  }

  // Room & Session Operations
  Future<List<RoomModel>> getRooms() async {
    final response = await apiClient.get('/rooms');
    if (response.statusCode != 200) {
      throw Exception('Failed to load focus rooms');
    }
    final List list = jsonDecode(response.body);
    return list.map((item) => RoomModel.fromJson(item)).toList();
  }

  Future<SessionModel> startSession(int roomId) async {
    final response = await apiClient.post('/rooms/session/start', {
      'room_id': roomId,
    });
    if (response.statusCode != 200) {
      throw Exception('Failed to start focus session');
    }
    return SessionModel.fromJson(jsonDecode(response.body));
  }

  Future<TaskModel> addTask(int sessionId, String title) async {
    final response = await apiClient.post('/rooms/session/tasks', {
      'session_id': sessionId,
      'title': title,
    });
    if (response.statusCode != 200) {
      throw Exception('Failed to add task');
    }
    return TaskModel.fromJson(jsonDecode(response.body));
  }

  Future<TaskModel> completeTask(int taskId) async {
    final response = await apiClient.put('/rooms/session/tasks/$taskId/complete', {});
    if (response.statusCode != 200) {
      throw Exception('Failed to complete task');
    }
    return TaskModel.fromJson(jsonDecode(response.body));
  }

  Future<TaskModel> activateTask(int taskId) async {
    final response = await apiClient.put('/rooms/session/tasks/$taskId/activate', {});
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Failed to activate task');
    }
    return TaskModel.fromJson(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> terminateSession(int sessionId) async {
    final response = await apiClient.post('/rooms/session/terminate', {
      'session_id': sessionId,
    });
    if (response.statusCode != 200) {
      throw Exception('Failed to terminate session');
    }
    return jsonDecode(response.body);
  }

  // Shop & Stripe Operations
  Future<List<ItemModel>> getShopItems() async {
    final response = await apiClient.get('/shop/items');
    if (response.statusCode != 200) {
      throw Exception('Failed to load shop items');
    }
    final List list = jsonDecode(response.body);
    return list.map((item) => ItemModel.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> purchaseItem(int itemId) async {
    final response = await apiClient.post('/shop/purchase', {
      'item_id': itemId,
    });
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Purchase failed');
    }
    return jsonDecode(response.body);
  }


  // Canvas Operations
  Future<List<InventoryItemModel>> getOasisItems() async {
    final response = await apiClient.get('/users/oasis/items');
    if (response.statusCode != 200) {
      throw Exception('Failed to load oasis items');
    }
    final List list = jsonDecode(response.body);
    return list.map((item) => InventoryItemModel.fromJson(item)).toList();
  }

  Future<void> updateItemLayout(List<Map<String, dynamic>> updates) async {
    final response = await apiClient.put('/users/oasis/items', updates);
    if (response.statusCode != 200) {
      throw Exception('Failed to save oasis layout');
    }
  }

  Future<void> deleteAccount() async {
    final response = await apiClient.delete('/auth/delete-account');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete account');
    }
  }
}
