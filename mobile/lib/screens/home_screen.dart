import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/restaurant_provider.dart';
import '../theme.dart';
import '../widgets/restaurant_card.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'orders_screen.dart';
import 'restaurant_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _cuisine;

  @override
  void initState() {
    super.initState();
    Future.microtask(
            () => ref.read(restaurantProvider.notifier).fetchRestaurants());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Map<String, String> _cuisines(List<Restaurant> all) {
    final map = <String, String>{};
    for (final r in all) {
      final label = r.cuisineType.trim();
      if (label.isEmpty) continue;
      map.putIfAbsent(label.toLowerCase(),
              () => label[0].toUpperCase() + label.substring(1));
    }
    return map;
  }

  List<Restaurant> _filter(List<Restaurant> all) {
    final q = _query.trim().toLowerCase();
    return all.where((r) {
      final matchesQuery = q.isEmpty ||
          r.name.toLowerCase().contains(q) ||
          r.cuisineType.toLowerCase().contains(q);
      final matchesCuisine =
          _cuisine == null || r.cuisineType.trim().toLowerCase() == _cuisine;
      return matchesQuery && matchesCuisine;
    }).toList();
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Search restaurants or cuisines',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _query = '');
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _cuisineChips(Map<String, String> cuisines) {
    if (cuisines.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: _cuisine == null,
              onSelected: (_) => setState(() => _cuisine = null),
            ),
          ),
          ...cuisines.entries.map((e) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value),
              selected: _cuisine == e.key,
              onSelected: (_) => setState(() => _cuisine = e.key),
            ),
          )),
        ],
      ),
    );
  }

  Widget _content(RestaurantState state) {
    if (state.isLoading && state.restaurants.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (state.error != null && state.restaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(restaurantProvider.notifier).fetchRestaurants(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.restaurants.isEmpty) {
      return const Center(child: Text('No restaurants available'));
    }

    final filtered = _filter(state.restaurants);
    if (filtered.isEmpty) {
      return const Center(child: Text('No restaurants match your search'));
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () =>
          ref.read(restaurantProvider.notifier).fetchRestaurants(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length,
        itemBuilder: (_, i) => RestaurantCard(
          restaurant: filtered[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailScreen(restaurant: filtered[i]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final state = ref.watch(restaurantProvider);
    final cartCount = ref.watch(cartProvider).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('QuickDelivery',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Hello, ${auth.userName ?? 'there'}',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const OrdersScreen())),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _searchBar(),
          _cuisineChips(_cuisines(state.restaurants)),
          Expanded(child: _content(state)),
        ],
      ),
    );
  }
}