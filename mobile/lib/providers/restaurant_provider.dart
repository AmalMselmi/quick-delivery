import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/restaurant.dart';

// BUG FIX: apiServiceProvider, MenuState, MenuNotifier, and menuProvider were
// duplicated here AND in menu_provider.dart — causes "already defined" compile error.
// Removed all Menu-related code from this file; import from menu_provider.dart instead.

// Restaurant state class
class RestaurantState {
  final List<Restaurant> restaurants;
  final bool isLoading;
  final String? error;
  final Restaurant? selectedRestaurant;

  RestaurantState({
    required this.restaurants,
    this.isLoading = false,
    this.error,
    this.selectedRestaurant,
  });

  RestaurantState copyWith({
    List<Restaurant>? restaurants,
    bool? isLoading,
    String? error,
    Restaurant? selectedRestaurant,
  }) {
    return RestaurantState(
      restaurants: restaurants ?? this.restaurants,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedRestaurant: selectedRestaurant ?? this.selectedRestaurant,
    );
  }
}

// RestaurantNotifier class
class RestaurantNotifier extends StateNotifier<RestaurantState> {
  final ApiService apiService;

  RestaurantNotifier({required this.apiService})
      : super(RestaurantState(restaurants: []));

  Future<void> fetchRestaurants() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final restaurants = await apiService.fetchRestaurants();
      state = state.copyWith(restaurants: restaurants, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load restaurants: ${e.toString()}',
      );
    }
  }

  void selectRestaurant(Restaurant restaurant) {
    state = state.copyWith(selectedRestaurant: restaurant);
  }

  void clearSelectedRestaurant() {
    state = state.copyWith(selectedRestaurant: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// BUG FIX: apiServiceProvider lives here as the single source of truth.
// menu_provider.dart must import and reuse this instead of redefining it.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final restaurantProvider =
StateNotifierProvider<RestaurantNotifier, RestaurantState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RestaurantNotifier(apiService: apiService);
});