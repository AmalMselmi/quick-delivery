import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../services/db_helper.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  final dbHelper = DBHelper.instance;

  CartNotifier() : super([]) {
    loadCart();
  }

  int? get restaurantId => state.isEmpty ? null : state.first.restaurantId;

  double get total =>
      state.fold(0, (sum, item) => sum + item.price * item.quantity);

  Future<void> loadCart() async {
    state = await dbHelper.getCartItems();
  }

  Future<void> addItem(CartItem item) async {
    final index = state.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      await dbHelper.updateItem(
          state[index].copyWith(quantity: state[index].quantity + 1));
    } else {
      await dbHelper.insertItem(item);
    }
    await loadCart();
  }

  Future<void> replaceWith(CartItem item) async {
    await dbHelper.clearCart();
    await dbHelper.insertItem(item);
    await loadCart();
  }

  Future<void> updateItem(CartItem item) async {
    await dbHelper.updateItem(item);
    await loadCart();
  }

  Future<void> removeItem(int id) async {
    await dbHelper.deleteItem(id);
    await loadCart();
  }

  Future<void> clearCart() async {
    await dbHelper.clearCart();
    await loadCart();
  }
}