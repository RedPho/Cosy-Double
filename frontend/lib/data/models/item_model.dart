import '../../domain/entities/item.dart';

class ItemModel extends Item {
  const ItemModel({
    required super.id,
    required super.name,
    required super.costLeaves,
    required super.priceUsd,
    required super.isPremium,
    required super.imageUrl,
    required super.category,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      costLeaves: json['cost_leaves'] ?? 0,
      priceUsd: (json['price_usd'] as num?)?.toDouble() ?? 0.0,
      isPremium: json['is_premium'] ?? false,
      imageUrl: json['image_url'] ?? '',
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cost_leaves': costLeaves,
      'price_usd': priceUsd,
      'is_premium': isPremium,
      'image_url': imageUrl,
      'category': category,
    };
  }
}
