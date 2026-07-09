import '../entities/inventory_item.dart';

abstract class CanvasRepository {
  Future<List<InventoryItem>> getOasisItems();
  Future<void> updateItemLayout(List<InventoryItem> items);
}
