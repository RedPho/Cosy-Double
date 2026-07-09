import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/shop_repository.dart';
import 'shop_event.dart';
import 'shop_state.dart';

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  final ShopRepository shopRepository;

  ShopBloc({required this.shopRepository}) : super(ShopInitial()) {
    on<LoadShopItems>(_onLoadShopItems);
    on<BuyItemWithLeaves>(_onBuyItemWithLeaves);
  }

  Future<void> _onLoadShopItems(LoadShopItems event, Emitter<ShopState> emit) async {
    emit(ShopLoading());
    try {
      final items = await shopRepository.getShopItems();
      emit(ShopLoaded(items: items));
    } catch (e) {
      emit(ShopError(message: e.toString()));
    }
  }

  Future<void> _onBuyItemWithLeaves(BuyItemWithLeaves event, Emitter<ShopState> emit) async {
    try {
      final res = await shopRepository.purchaseItem(event.itemId);
      final newBalance = res['leaves_balance'] ?? 0;
      emit(PurchaseSuccess(itemId: event.itemId, newBalance: newBalance));
      
      // Reload shop items
      final items = await shopRepository.getShopItems();
      emit(ShopLoaded(items: items, updatedBalance: newBalance));
    } catch (e) {
      emit(ShopError(message: e.toString()));
    }
  }
}
