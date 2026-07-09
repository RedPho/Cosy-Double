import 'package:equatable/equatable.dart';
import '../../../domain/entities/item.dart';

abstract class ShopState extends Equatable {
  const ShopState();

  @override
  List<Object?> get props => [];
}

class ShopInitial extends ShopState {}

class ShopLoading extends ShopState {}

class ShopLoaded extends ShopState {
  final List<Item> items;
  final int? updatedBalance; // To display balance updates

  const ShopLoaded({required this.items, this.updatedBalance});

  @override
  List<Object?> get props => [items, updatedBalance];
}

class PurchaseSuccess extends ShopState {
  final int itemId;
  final int newBalance;

  const PurchaseSuccess({required this.itemId, required this.newBalance});

  @override
  List<Object?> get props => [itemId, newBalance];
}



class ShopError extends ShopState {
  final String message;

  const ShopError({required this.message});

  @override
  List<Object?> get props => [message];
}
