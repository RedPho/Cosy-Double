import 'package:equatable/equatable.dart';
import '../../../domain/entities/inventory_item.dart';

abstract class CanvasEvent extends Equatable {
  const CanvasEvent();

  @override
  List<Object?> get props => [];
}

class LoadOasisItems extends CanvasEvent {}

class PlaceItemOnCanvas extends CanvasEvent {
  final int inventoryId;

  const PlaceItemOnCanvas({required this.inventoryId});

  @override
  List<Object?> get props => [inventoryId];
}

class RemoveItemFromCanvas extends CanvasEvent {
  final int inventoryId;

  const RemoveItemFromCanvas({required this.inventoryId});

  @override
  List<Object?> get props => [inventoryId];
}

class MoveItemOnCanvas extends CanvasEvent {
  final int inventoryId;
  final double xPos;
  final double yPos;

  const MoveItemOnCanvas({
    required this.inventoryId,
    required this.xPos,
    required this.yPos,
  });

  @override
  List<Object?> get props => [inventoryId, xPos, yPos];
}

class SaveCanvasLayout extends CanvasEvent {}
