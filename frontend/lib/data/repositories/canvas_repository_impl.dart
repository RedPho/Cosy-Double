import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/canvas_repository.dart';
import '../datasources/remote_data_source.dart';

class CanvasRepositoryImpl implements CanvasRepository {
  final RemoteDataSource remoteDataSource;

  CanvasRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<InventoryItem>> getOasisItems() async {
    return await remoteDataSource.getOasisItems();
  }

  @override
  Future<void> updateItemLayout(List<InventoryItem> items) async {
    final updates = items.map((item) => {
      'inventory_id': item.id,
      'x_pos': item.xPos,
      'y_pos': item.yPos,
      'is_placed': item.isPlaced,
    }).toList();
    await remoteDataSource.updateItemLayout(updates);
  }
}
