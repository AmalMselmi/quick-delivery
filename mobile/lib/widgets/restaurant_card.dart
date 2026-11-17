import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../theme.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const RestaurantCard({super.key, required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(restaurant.image, width: 60, height: 60, fit: BoxFit.cover)),
        title: Text(restaurant.name, style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        subtitle: Text('${restaurant.cuisineType} • ⭐ ${restaurant.rating}'),
        onTap: onTap,
      ),
    );
  }
}
