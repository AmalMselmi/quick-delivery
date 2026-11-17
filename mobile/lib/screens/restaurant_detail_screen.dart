import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';
import '../providers/cart_provider.dart';
import '../providers/restaurant_provider.dart' show apiServiceProvider;
import '../widgets/menu_item_card.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  late Future<List<MenuItem>> _menu;

  @override
  void initState() {
    super.initState();
    _menu = ref.read(apiServiceProvider).fetchMenu(widget.restaurant.id);
  }

  Future<void> _add(MenuItem item) async {
    final cart = ref.read(cartProvider.notifier);
    final newItem = CartItem(
      id: item.id,
      restaurantId: widget.restaurant.id,
      name: item.name,
      price: item.price,
      quantity: 1,
    );

    final current = cart.restaurantId;
    if (current != null && current != widget.restaurant.id) {
      final startNew = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Start a new cart?'),
          content: const Text(
              'Your cart contains items from another restaurant. '
                  'You can only order from one restaurant at a time.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep current cart')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Start new cart')),
          ],
        ),
      );
      if (startNew != true) return;
      await cart.replaceWith(newItem);
    } else {
      await cart.addItem(newItem);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${item.name} added to cart')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.restaurant.name)),
      body: FutureBuilder<List<MenuItem>>(
        future: _menu,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading menu'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No menu items'));
          }
          final menu = snapshot.data!;
          return ListView.builder(
            itemCount: menu.length,
            itemBuilder: (context, i) {
              final item = menu[i];
              return MenuItemCard(
                item: item,
                onAdd: item.available ? () => _add(item) : null,
              );
            },
          );
        },
      ),
    );
  }
}