// FILE: lib/models/menu_item.dart  (REPLACE entire file)

class MenuItem {
  final int id;
  final String name;
  final double price;
  final String image;
  final bool available;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.available,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    // FIX: safe parsing for all fields — Laravel can return numbers as strings
    id: int.tryParse(json['id'].toString()) ?? 0,
    name: json['name']?.toString() ?? '',
    price: double.tryParse(json['price'].toString()) ?? 0.0,
    image: json['image']?.toString() ?? '',
    available: json['available'] == true ||
        json['available'] == 1 ||
        json['available'].toString() == 'true',
  );
}