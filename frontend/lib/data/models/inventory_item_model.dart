import '../../domain/entities/inventory_item.dart';

class InventoryItemModel extends InventoryItem {
  const InventoryItemModel({
    required super.id,
    required super.itemId,
    required super.name,
    required super.imageUrl,
    required super.category,
    required super.xPos,
    required super.yPos,
    required super.isPlaced,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] ?? 0,
      itemId: json['item_id'] ?? 0,
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      category: json['category'] ?? '',
      xPos: (json['x_pos'] as num?)?.toDouble() ?? 0.0,
      yPos: (json['y_pos'] as num?)?.toDouble() ?? 0.0,
      isPlaced: json['is_placed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'name': name,
      'image_url': imageUrl,
      'category': category,
      'x_pos': xPos,
      'y_pos': yPos,
      'is_placed': isPlaced,
    };
  }
}
