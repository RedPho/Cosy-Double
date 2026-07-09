import '../entities/item.dart';

abstract class ShopRepository {
  Future<List<Item>> getShopItems();
  Future<Map<String, dynamic>> purchaseItem(int itemId);
}
