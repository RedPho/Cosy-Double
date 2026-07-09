import 'package:equatable/equatable.dart';

class Item extends Equatable {
  final int id;
  final String name;
  final int costLeaves;
  final double priceUsd;
  final bool isPremium;
  final String imageUrl;
  final String category;

  const Item({
    required this.id,
    required this.name,
    required this.costLeaves,
    required this.priceUsd,
    required this.isPremium,
    required this.imageUrl,
    required this.category,
  });

  @override
  List<Object?> get props => [id, name, costLeaves, priceUsd, isPremium, imageUrl, category];
}
