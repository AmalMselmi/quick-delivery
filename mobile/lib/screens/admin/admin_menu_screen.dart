// FILE: lib/screens/admin/admin_menu_screen.dart  (NEW FILE)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/menu_item.dart';
import '../../models/restaurant.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AdminMenuScreen extends ConsumerStatefulWidget {
  const AdminMenuScreen({super.key});
  @override
  ConsumerState<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends ConsumerState<AdminMenuScreen> {
  final _api = ApiService();
  List<MenuItem> _items = [];
  List<Restaurant> _restaurants = [];
  Restaurant? _selectedRestaurant;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _restaurants = await _api.fetchRestaurants();
      if (_selectedRestaurant == null && _restaurants.isNotEmpty) {
        _selectedRestaurant = _restaurants.first;
      }
      if (_selectedRestaurant != null) {
        _items = await _api.fetchMenu(_selectedRestaurant!.id);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadMenu() async {
    if (_selectedRestaurant == null) return;
    setState(() => _loading = true);
    try {
      _items = await _api.fetchMenu(_selectedRestaurant!.id);
    } catch (_) {}
    setState(() => _loading = false);
  }

  String get _token => ref.read(authProvider).token ?? '';

  Future<void> _showForm({MenuItem? item}) async {
    final nameCtrl  = TextEditingController(text: item?.name);
    final priceCtrl = TextEditingController(text: item?.price.toString());
    final imageCtrl = TextEditingController(text: item?.image);
    bool available  = item?.available ?? true;
    Restaurant? selectedRest = _selectedRestaurant;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(item == null ? 'Add Menu Item' : 'Edit Menu Item',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Restaurant picker
              DropdownButtonFormField<Restaurant>(
                value: selectedRest,
                decoration: InputDecoration(
                  labelText: 'Restaurant',
                  prefixIcon: const Icon(Icons.store, color: Color(0xFFFF6B35)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _restaurants.map((r) =>
                    DropdownMenuItem(value: r, child: Text(r.name))).toList(),
                onChanged: (r) => setModalState(() => selectedRest = r),
              ),
              const SizedBox(height: 12),
              _field(nameCtrl, 'Item Name', Icons.fastfood),
              const SizedBox(height: 12),
              _field(priceCtrl, 'Price', Icons.attach_money, type: TextInputType.number),
              const SizedBox(height: 12),
              _field(imageCtrl, 'Image URL', Icons.image),
              const SizedBox(height: 12),

              // Available toggle
              Row(
                children: [
                  const Text('Available', style: TextStyle(fontSize: 15)),
                  const Spacer(),
                  Switch(
                    value: available,
                    activeColor: const Color(0xFFFF6B35),
                    onChanged: (v) => setModalState(() => available = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  Navigator.pop(context);
                  final data = {
                    'restaurantId': selectedRest?.id,
                    'name': nameCtrl.text,
                    'price': double.tryParse(priceCtrl.text) ?? 0.0,
                    'image': imageCtrl.text,
                    'available': available,
                  };
                  try {
                    if (item == null) {
                      await _api.createMenuItem(data, _token);
                    } else {
                      await _api.updateMenuItem(item.id, data, _token);
                    }
                    _loadMenu();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                    }
                  }
                },
                child: Text(item == null ? 'Add Item' : 'Update Item',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text('Delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.deleteMenuItem(item.id, _token);
        _loadMenu();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        }
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
        prefixIcon: Icon(icon, color: const Color(0xFFFF6B35)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Items', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        onPressed: () => _showForm(),
      ),
      body: Column(
        children: [
          // Restaurant filter
          if (_restaurants.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<Restaurant>(
                value: _selectedRestaurant,
                decoration: InputDecoration(
                  labelText: 'Filter by Restaurant',
                  prefixIcon: const Icon(Icons.store, color: Color(0xFFFF6B35)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _restaurants.map((r) =>
                    DropdownMenuItem(value: r, child: Text(r.name))).toList(),
                onChanged: (r) {
                  setState(() => _selectedRestaurant = r);
                  _loadMenu();
                },
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
                : _items.isEmpty
                ? const Center(child: Text('No menu items. Add one!'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(item.image, width: 56, height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 56)),
                    ),
                    title: Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.price.toStringAsFixed(2)} \DT'),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.available
                                ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.available ? 'Available' : 'Unavailable',
                            style: TextStyle(
                                fontSize: 11,
                                color: item.available ? Colors.green.shade700 : Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
                          onPressed: () => _showForm(item: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _delete(item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}