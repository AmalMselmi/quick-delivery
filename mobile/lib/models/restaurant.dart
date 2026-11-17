class Restaurant {
  final int id;
  final String name;
  final String image;
  final double rating;
  final String cuisineType;
  final double? latitude;
  final double? longitude;

  Restaurant({
    required this.id,
    required this.name,
    required this.image,
    required this.rating,
    required this.cuisineType,
    this.latitude,
    this.longitude,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
    id: int.tryParse(json['id'].toString()) ?? 0,
    name: json['name']?.toString() ?? '',
    image: json['image']?.toString() ?? '',
    rating: double.tryParse(json['rating'].toString()) ?? 0.0,
    cuisineType: json['cuisineType']?.toString() ?? '',
    latitude: json['latitude'] == null
        ? null
        : double.tryParse(json['latitude'].toString()),
    longitude: json['longitude'] == null
        ? null
        : double.tryParse(json['longitude'].toString()),
  );
}