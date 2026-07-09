import '../../domain/entities/room.dart';

class RoomModel extends Room {
  const RoomModel({
    required super.id,
    required super.name,
    required super.category,
    required super.isActive,
    required super.activeUsers,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      isActive: json['is_active'] ?? true,
      activeUsers: List<String>.from(json['active_users'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'is_active': isActive,
      'active_users': activeUsers,
    };
  }
}
