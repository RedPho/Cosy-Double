import 'package:equatable/equatable.dart';

abstract class ShopEvent extends Equatable {
  const ShopEvent();

  @override
  List<Object?> get props => [];
}

class LoadShopItems extends ShopEvent {}

class BuyItemWithLeaves extends ShopEvent {
  final int itemId;

  const BuyItemWithLeaves({required this.itemId});

  @override
  List<Object?> get props => [itemId];
}


