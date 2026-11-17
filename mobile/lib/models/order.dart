double _toDouble(dynamic v) => double.tryParse(v.toString()) ?? 0.0;

class OrderLine {
  final String name;
  final double price;
  final int quantity;

  OrderLine({required this.name, required this.price, required this.quantity});

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    name: json['name']?.toString() ?? '',
    price: _toDouble(json['price']),
    quantity: int.tryParse(json['quantity'].toString()) ?? 1,
  );
}

class Order {
  final int id;
  final String status;
  final double total;
  final double deliveryFee;
  final String address;
  final String customerName;
  final DateTime? createdAt;
  final List<OrderLine> items;

  Order({
    required this.id,
    required this.status,
    required this.total,
    required this.deliveryFee,
    required this.address,
    required this.customerName,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: int.tryParse(json['id'].toString()) ?? 0,
    status: json['status']?.toString() ?? 'pending',
    total: _toDouble(json['total']),
    deliveryFee: _toDouble(json['delivery_fee']),
    address: json['address']?.toString() ?? '',
    customerName: json['user'] is Map
        ? (json['user']['name']?.toString() ?? '')
        : '',
    createdAt:
    DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal(),
    items: ((json['items'] ?? []) as List)
        .map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class Quote {
  final double subtotal;
  final double deliveryFee;
  final double total;

  Quote({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
    subtotal: _toDouble(json['subtotal']),
    deliveryFee: _toDouble(json['delivery_fee']),
    total: _toDouble(json['total']),
  );
}

class AdminStats {
  final int ordersToday;
  final double revenueToday;
  final int pending;
  final int restaurants;
  final int clients;
  final List<Order> recent;

  AdminStats({
    required this.ordersToday,
    required this.revenueToday,
    required this.pending,
    required this.restaurants,
    required this.clients,
    required this.recent,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
    ordersToday: int.tryParse(json['orders_today'].toString()) ?? 0,
    revenueToday: _toDouble(json['revenue_today']),
    pending: int.tryParse(json['pending'].toString()) ?? 0,
    restaurants: int.tryParse(json['restaurants'].toString()) ?? 0,
    clients: int.tryParse(json['clients'].toString()) ?? 0,
    recent: ((json['recent'] ?? []) as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}