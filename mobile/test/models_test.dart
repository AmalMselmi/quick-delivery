import 'package:flutter_test/flutter_test.dart';
import 'package:quick_delivery/models/cart_item.dart';
import 'package:quick_delivery/models/menu_item.dart';
import 'package:quick_delivery/models/order.dart';
import 'package:quick_delivery/models/restaurant.dart';

void main() {
  test('Restaurant parses string rating and missing coordinates', () {
    final r = Restaurant.fromJson({
      'id': '3',
      'name': 'Sushi Garden',
      'image': 'x',
      'rating': '4.5',
      'cuisineType': 'Japanese',
    });

    expect(r.id, 3);
    expect(r.rating, 4.5);
    expect(r.hasLocation, isFalse);
  });

  test('Restaurant parses coordinates', () {
    final r = Restaurant.fromJson({
      'id': 1,
      'name': 'A',
      'image': 'x',
      'rating': 4,
      'cuisineType': 'Italian',
      'latitude': '36.8065',
      'longitude': '10.1815',
    });

    expect(r.hasLocation, isTrue);
    expect(r.latitude, closeTo(36.8065, 0.0001));
  });

  test('MenuItem availability accepts 1 and true', () {
    final a = MenuItem.fromJson(
        {'id': 1, 'name': 'A', 'price': '9.5', 'image': '', 'available': 1});
    final b = MenuItem.fromJson(
        {'id': 2, 'name': 'B', 'price': 5, 'image': '', 'available': false});

    expect(a.available, isTrue);
    expect(a.price, 9.5);
    expect(b.available, isFalse);
  });

  test('CartItem survives a map round trip', () {
    final item = CartItem(
        id: 4, restaurantId: 2, name: 'Pizza', price: 12.5, quantity: 3);
    final copy = CartItem.fromMap(item.toMap());

    expect(copy.restaurantId, 2);
    expect(copy.price, 12.5);
    expect(copy.quantity, 3);
  });

  test('Order parses customer name and items', () {
    final o = Order.fromJson({
      'id': 7,
      'status': 'preparing',
      'total': '23.00',
      'delivery_fee': '3.00',
      'address': 'Tunis',
      'user': {'name': 'Ali'},
      'items': [
        {'name': 'Pizza', 'price': '10.00', 'quantity': 2}
      ],
    });

    expect(o.customerName, 'Ali');
    expect(o.total, 23.0);
    expect(o.items.single.quantity, 2);
  });
}
