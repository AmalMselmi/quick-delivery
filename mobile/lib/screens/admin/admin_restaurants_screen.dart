import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../models/restaurant.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart' show apiServiceProvider;
import '../../services/api_service.dart';
import '../../theme.dart';
import '../map_picker_screen.dart';

class AdminRestaurantsScreen extends ConsumerStatefulWidget {
  const AdminRestaurantsScreen({super.key});

  @override
  ConsumerState<AdminRestaurantsScreen> createState() =>
      _AdminRestaurantsScreenState();
}

class _AdminRestaurantsScreenState
    extends ConsumerState<AdminRestaurantsScreen> {
  List<Restaurant> _restaurants = [];
  bool _loading = true;
  String? _error;

  ApiService get _api => ref.read(apiServiceProvider);
  String get _token => ref.read(authProvider).token ?? '';

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.fetchRestaurants();
      if (!mounted) return;
      setState(() {
        _restaurants = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
    ));
  }

  Future<void> _showForm({Restaurant? restaurant}) async {
    final nameCtrl = TextEditingController(text: restaurant?.name);
    final imageCtrl = TextEditingController(text: restaurant?.image);
    final ratingCtrl =
    TextEditingController(text: restaurant?.rating.toString());
    final cuisineCtrl = TextEditingController(text: restaurant?.cuisineType);
    LatLng? location = (restaurant != null && restaurant.hasLocation)
        ? LatLng(restaurant.latitude!, restaurant.longitude!)
        : null;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                restaurant == null ? 'Add Restaurant' : 'Edit Restaurant',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _field(nameCtrl, 'Restaurant Name', Icons.store),
              const SizedBox(height: 12),
              _field(imageCtrl, 'Image URL', Icons.image),
              const SizedBox(height: 12),
              _field(ratingCtrl, 'Rating (0-5)', Icons.star,
                  type: TextInputType.number),
              const SizedBox(height: 12),
              _field(cuisineCtrl, 'Cuisine Type', Icons.food_bank),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await Navigator.push<PickedLocation>(
                    ctx,
                    MaterialPageRoute(builder: (_) => const MapPickerScreen()),
                  );
                  if (picked != null && ctx.mounted) {
                    setModalState(() => location = picked.point);
                  }
                },
                icon: const Icon(Icons.map),
                label: const Text('Set location on map'),
              ),
              const SizedBox(height: 4),
              Text(
                location == null
                    ? 'No location set (flat delivery fee applies)'
                    : 'Location: ${location!.latitude.toStringAsFixed(5)}, '
                    '${location!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(
                    color: AppTheme.textMedium, fontSize: 12),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (nameCtrl.text.trim().isEmpty ||
                        imageCtrl.text.trim().isEmpty ||
                        cuisineCtrl.text.trim().isEmpty) {
                      _showSnack('Please fill in all fields',
                          isError: true);
                      return;
                    }
                    final rating = double.tryParse(ratingCtrl.text);
                    if (rating == null || rating < 0 || rating > 5) {
                      _showSnack('Rating must be between 0 and 5',
                          isError: true);
                      return;
                    }
                    setModalState(() => isSaving = true);
                    final data = {
                      'name': nameCtrl.text.trim(),
                      'image': imageCtrl.text.trim(),
                      'rating': rating,
                      'cuisineType': cuisineCtrl.text.trim(),
                      'latitude': location?.latitude,
                      'longitude': location?.longitude,
                    };
                    try {
                      if (restaurant == null) {
                        await _api.createRestaurant(data, _token);
                      } else {
                        await _api.updateRestaurant(
                            restaurant.id, data, _token);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _showSnack(restaurant == null
                          ? 'Restaurant added'
                          : 'Restaurant updated');
                      await _loadRestaurants();
                    } catch (e) {
                      if (ctx.mounted) {
                        setModalState(() => isSaving = false);
                      }
                      _showSnack(
                          'Error: ${e.toString().replaceFirst('Exception: ', '')}',
                          isError: true);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Text(
                    restaurant == null
                        ? 'Add Restaurant'
                        : 'Update Restaurant',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(Restaurant r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Restaurant'),
        content:
        Text('Delete "${r.name}"? This will also delete all its menu items.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
              const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.deleteRestaurant(r.id, _token);
        _showSnack('Restaurant deleted');
        await _loadRestaurants();
      } catch (e) {
        _showSnack('Error: ${e.toString().replaceFirst('Exception: ', '')}',
            isError: true);
      }
    }
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurants')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Restaurant'),
        onPressed: () => _showForm(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadRestaurants,
                child: const Text('Retry')),
          ],
        ),
      )
          : _restaurants.isEmpty
          ? const Center(child: Text('No restaurants yet. Add one!'))
          : RefreshIndicator(
        onRefresh: _loadRestaurants,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _restaurants.length,
          itemBuilder: (_, i) {
            final r = _restaurants[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(r.image,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.store, size: 56)),
                ),
                title: Text(r.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${r.cuisineType}  |  Rating ${r.rating.toStringAsFixed(1)}'
                      '${r.hasLocation ? '' : '\nNo location set'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit,
                          color: Colors.blue),
                      onPressed: () => _showForm(restaurant: r),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.red),
                      onPressed: () => _delete(r),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}