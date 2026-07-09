import 'package:equatable/equatable.dart';
import '../../../domain/entities/inventory_item.dart';

abstract class CanvasState extends Equatable {
  const CanvasState();

  @override
  List<Object?> get props => [];
}

class CanvasInitial extends CanvasState {}

class CanvasLoading extends CanvasState {}

class CanvasLoaded extends CanvasState {
  final List<InventoryItem> items;
  final bool isSaving;

  const CanvasLoaded({required this.items, this.isSaving = false});

  @override
  List<Object?> get props => [items, isSaving];
}

class CanvasError extends CanvasState {
  final String message;

  const CanvasError({required this.message});

  @override
  List<Object?> get props => [message];
}
