import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../theme.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const CartItemTile({super.key, required this.item, required this.onIncrease, required this.onDecrease});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.name, style: TextStyle(color: AppTheme.textDark)),
      subtitle: Text('${item.price.toStringAsFixed(2)} DT'),      trailing: SizedBox(
        width: 120,
        child: Row(
          children: [
            IconButton(onPressed: onDecrease, icon: const Icon(Icons.remove, color: AppTheme.accent)),
            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(onPressed: onIncrease, icon: const Icon(Icons.add, color: AppTheme.secondary)),
          ],
        ),
      ),
    );
  }
}
