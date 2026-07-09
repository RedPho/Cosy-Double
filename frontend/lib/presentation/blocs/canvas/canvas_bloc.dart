import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/inventory_item.dart';
import '../../../domain/repositories/canvas_repository.dart';
import 'canvas_event.dart';
import 'canvas_state.dart';

class CanvasBloc extends Bloc<CanvasEvent, CanvasState> {
  final CanvasRepository canvasRepository;
  Timer? _debounceTimer;

  CanvasBloc({required this.canvasRepository}) : super(CanvasInitial()) {
    on<LoadOasisItems>(_onLoadOasisItems);
    on<PlaceItemOnCanvas>(_onPlaceItemOnCanvas);
    on<RemoveItemFromCanvas>(_onRemoveItemFromCanvas);
    on<MoveItemOnCanvas>(_onMoveItemOnCanvas);
    on<SaveCanvasLayout>(_onSaveCanvasLayout);
  }

  Future<void> _onLoadOasisItems(LoadOasisItems event, Emitter<CanvasState> emit) async {
    emit(CanvasLoading());
    try {
      final items = await canvasRepository.getOasisItems();
      emit(CanvasLoaded(items: items));
    } catch (e) {
      emit(CanvasError(message: e.toString()));
    }
  }

  Future<void> _onPlaceItemOnCanvas(PlaceItemOnCanvas event, Emitter<CanvasState> emit) async {
    if (state is! CanvasLoaded) return;
    final currentItems = (state as CanvasLoaded).items;
    
    final updatedItems = currentItems.map((item) {
      if (item.id == event.inventoryId) {
        return item.copyWith(isPlaced: true);
      }
      // Only one theme can be applied at a time
      return item.copyWith(isPlaced: false);
    }).toList();
    
    emit(CanvasLoaded(items: updatedItems));
    
    // Save placement immediately
    add(SaveCanvasLayout());
  }

  Future<void> _onRemoveItemFromCanvas(RemoveItemFromCanvas event, Emitter<CanvasState> emit) async {
    if (state is! CanvasLoaded) return;
    final currentItems = (state as CanvasLoaded).items;
    
    final updatedItems = currentItems.map((item) {
      if (item.id == event.inventoryId) {
        return item.copyWith(isPlaced: false);
      }
      return item;
    }).toList();
    
    emit(CanvasLoaded(items: updatedItems));
    
    // Save removal immediately
    add(SaveCanvasLayout());
  }

  void _onMoveItemOnCanvas(MoveItemOnCanvas event, Emitter<CanvasState> emit) {
    if (state is! CanvasLoaded) return;
    final currentItems = (state as CanvasLoaded).items;
    
    // Update local coordinate state instantly for 60fps responsiveness
    final updatedItems = currentItems.map((item) {
      if (item.id == event.inventoryId) {
        return item.copyWith(xPos: event.xPos, yPos: event.yPos);
      }
      return item;
    }).toList();
    
    emit(CanvasLoaded(items: updatedItems));
    
    // Debounce the PUT request to the server by 1 second to avoid database transaction spamming
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      add(SaveCanvasLayout());
    });
  }

  Future<void> _onSaveCanvasLayout(SaveCanvasLayout event, Emitter<CanvasState> emit) async {
    if (state is! CanvasLoaded) return;
    final currentItems = (state as CanvasLoaded).items;
    
    try {
      await canvasRepository.updateItemLayout(currentItems);
      print("Persisted oasis canvas items to backend.");
    } catch (_) {
      // Keep state as loaded, handle error silently or log
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
