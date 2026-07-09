import 'package:equatable/equatable.dart';

class InventoryItem extends Equatable {
  final int id; // inventory_id
  final int itemId;
  final String name;
  final String imageUrl;
  final String category;
  final double xPos;
  final double yPos;
  final bool isPlaced;

  const InventoryItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.xPos,
    required this.yPos,
    required this.isPlaced,
  });

  InventoryItem copyWith({
    double? xPos,
    double? yPos,
    bool? isPlaced,
  }) {
    return InventoryItem(
      id: id,
      itemId: itemId,
      name: name,
      imageUrl: imageUrl,
      category: category,
      xPos: xPos ?? this.xPos,
      yPos: yPos ?? this.yPos,
      isPlaced: isPlaced ?? this.isPlaced,
    );
  }

  @override
  List<Object?> get props => [id, itemId, name, imageUrl, category, xPos, yPos, isPlaced];
}
