import '../../domain/entities/item.dart';
import '../../domain/repositories/shop_repository.dart';
import '../datasources/remote_data_source.dart';

class ShopRepositoryImpl implements ShopRepository {
  final RemoteDataSource remoteDataSource;

  ShopRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Item>> getShopItems() async {
    return await remoteDataSource.getShopItems();
  }

  @override
  Future<Map<String, dynamic>> purchaseItem(int itemId) async {
    return await remoteDataSource.purchaseItem(itemId);
  }
}
