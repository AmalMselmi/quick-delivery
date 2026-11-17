import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/menu_item.dart';
// BUG FIX: import the single apiServiceProvider instead of redefining it here
import 'restaurant_provider.dart' show apiServiceProvider;

// Menu state class
class MenuState {
  final List<MenuItem> items;
  final bool isLoading;
  final String? error;
  final int? currentRestaurantId;
  final Map<int, bool> availabilityFilter;

  MenuState({
    required this.items,
    this.isLoading = false,
    this.error,
    this.currentRestaurantId,
    this.availabilityFilter = const {},
  });

  List<MenuItem> get filteredItems {
    if (availabilityFilter.isEmpty) return items;
    final showOnlyAvailable =
    availabilityFilter.values.firstWhere((v) => v == true, orElse: () => false);
    return showOnlyAvailable ? items.where((i) => i.available).toList() : items;
  }

  int get availableCount => items.where((i) => i.available).length;
  int get unavailableCount => items.where((i) => !i.available).length;

  // FIX: priceRange must live on MenuState (not only on the notifier)
  // so providers that do ref.watch(menuProvider) can access it.
  Map<String, double> get priceRange {
    if (items.isEmpty) return {'min': 0, 'max': 0};
    double min = items[0].price, max = items[0].price;
    for (final item in items) {
      if (item.price < min) min = item.price;
      if (item.price > max) max = item.price;
    }
    return {'min': min, 'max': max};
  }

  MenuState copyWith({
    List<MenuItem>? items,
    bool? isLoading,
    String? error,
    int? currentRestaurantId,
    Map<int, bool>? availabilityFilter,
  }) {
    return MenuState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentRestaurantId: currentRestaurantId ?? this.currentRestaurantId,
      availabilityFilter: availabilityFilter ?? this.availabilityFilter,
    );
  }
}

class MenuNotifier extends StateNotifier<MenuState> {
  final ApiService apiService;

  MenuNotifier({required this.apiService}) : super(MenuState(items: []));

  Future<void> fetchMenu(int restaurantId) async {
    if (state.isLoading && state.currentRestaurantId == restaurantId) return;
    state = state.copyWith(
        isLoading: true, error: null, currentRestaurantId: restaurantId);
    try {
      final menuItems = await apiService.fetchMenu(restaurantId);
      state = state.copyWith(items: menuItems, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load menu: ${e.toString()}');
    }
  }

  Future<void> refreshMenu() async {
    if (state.currentRestaurantId != null) {
      await fetchMenu(state.currentRestaurantId!);
    }
  }

  List<MenuItem> searchItems(String query) {
    if (query.isEmpty) return state.items;
    final lowerQuery = query.toLowerCase();
    return state.items.where((i) => i.name.toLowerCase().contains(lowerQuery)).toList();
  }

  MenuItem? getItemById(int id) {
    try {
      return state.items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  void toggleAvailabilityFilter(bool showOnlyAvailable) {
    state = state.copyWith(availabilityFilter: {0: showOnlyAvailable});
  }

  void clearAvailabilityFilter() {
    state = state.copyWith(availabilityFilter: {});
  }

  void sortByPrice({bool ascending = true}) {
    final sorted = List<MenuItem>.from(state.items)
      ..sort((a, b) => ascending ? a.price.compareTo(b.price) : b.price.compareTo(a.price));
    state = state.copyWith(items: sorted);
  }

  void sortByName({bool ascending = true}) {
    final sorted = List<MenuItem>.from(state.items)
      ..sort((a, b) => ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
    state = state.copyWith(items: sorted);
  }

  List<MenuItem> filterByPriceRange(double min, double max) {
    return state.items.where((i) => i.price >= min && i.price <= max).toList();
  }

  List<MenuItem> getAvailableItems() => state.items.where((i) => i.available).toList();
  List<MenuItem> getUnavailableItems() => state.items.where((i) => !i.available).toList();
  bool get hasAvailableItems => state.items.any((i) => i.available);

  void clearMenu() => state = MenuState(items: []);
  void clearError() => state = state.copyWith(error: null);
}

final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MenuNotifier(apiService: apiService);
});

final menuSearchProvider = Provider((ref) {
  return (String query) => ref.read(menuProvider.notifier).searchItems(query);
});

final menuItemByIdProvider = Provider.family<MenuItem?, int>((ref, id) {
  final menuState = ref.watch(menuProvider);
  try {
    return menuState.items.firstWhere((i) => i.id == id);
  } catch (_) {
    return null;
  }
});

final filteredMenuProvider = Provider<List<MenuItem>>((ref) {
  return ref.watch(menuProvider).filteredItems;
});

final availableMenuItemsProvider = Provider<List<MenuItem>>((ref) {
  return ref.watch(menuProvider).items.where((i) => i.available).toList();
});

final menuStatsProvider = Provider((ref) {
  final s = ref.watch(menuProvider);
  return {
    'total': s.items.length,
    'available': s.availableCount,
    'unavailable': s.unavailableCount,
    'minPrice': s.priceRange['min'],
    'maxPrice': s.priceRange['max'],
  };
});