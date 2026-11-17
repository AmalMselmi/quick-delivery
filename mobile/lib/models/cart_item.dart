class CartItem {
  final int id;
  final int restaurantId;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  CartItem copyWith({int? quantity}) => CartItem(
    id: id,
    restaurantId: restaurantId,
    name: name,
    price: price,
    quantity: quantity ?? this.quantity,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'restaurantId': restaurantId,
    'name': name,
    'price': price,
    'quantity': quantity,
  };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
    id: map['id'] as int,
    restaurantId: (map['restaurantId'] as int?) ?? 0,
    name: map['name'] as String,
    price: (map['price'] as num).toDouble(),
    quantity: map['quantity'] as int,
  );
}