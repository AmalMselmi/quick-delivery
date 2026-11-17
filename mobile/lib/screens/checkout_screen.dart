import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/restaurant_provider.dart' show apiServiceProvider;
import '../theme.dart';
import 'map_picker_screen.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  LatLng? _picked;
  bool _placing = false;
  bool _quoting = false;
  Quote? _quote;
  String? _quoteError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuote());
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  List<Map<String, dynamic>> _items() => ref
      .read(cartProvider)
      .map((i) => {'id': i.id, 'quantity': i.quantity})
      .toList();

  Future<void> _loadQuote() async {
    if (ref.read(cartProvider).isEmpty) return;
    setState(() {
      _quoting = true;
      _quoteError = null;
    });
    try {
      final token = ref.read(authProvider).token ?? '';
      final quote = await ref.read(apiServiceProvider).quoteOrder({
        'latitude': _picked?.latitude,
        'longitude': _picked?.longitude,
        'items': _items(),
      }, token);
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _quoting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _quote = null;
        _quoting = false;
        _quoteError = _clean(e);
      });
    }
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (result != null) {
      setState(() {
        _addressCtrl.text = result.address;
        _picked = result.point;
      });
      await _loadQuote();
    }
  }

  Future<void> _placeOrder() async {
    if (_addressCtrl.text.trim().isEmpty) {
      _snack('Please enter or choose a delivery address');
      return;
    }

    setState(() => _placing = true);
    try {
      final token = ref.read(authProvider).token ?? '';
      final order = await ref.read(apiServiceProvider).createOrder({
        'address': _addressCtrl.text.trim(),
        'latitude': _picked?.latitude,
        'longitude': _picked?.longitude,
        'items': _items(),
      }, token);

      await ref.read(cartProvider.notifier).clearCart();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(
            orderId: order.id,
            address: order.address,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      _snack(_clean(e));
    }
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _quote;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Delivery Address',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Address',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _pickOnMap,
              icon: const Icon(Icons.map),
              label: const Text('Choose on map'),
            ),
          ),
          if (_picked != null)
            Text(
              'Location selected on map',
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
          const SizedBox(height: 24),
          const Text('Payment',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.payments_outlined, color: AppTheme.primary),
              title: Text('Cash on delivery'),
              subtitle: Text('Pay the courier when your order arrives'),
              trailing: Icon(Icons.check_circle, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          if (_quoting)
            const Center(child: CircularProgressIndicator())
          else if (_quoteError != null)
            Text(_quoteError!, style: TextStyle(color: Colors.red.shade700))
          else if (q != null) ...[
              _row('Subtotal', '${q.subtotal.toStringAsFixed(2)} DT'),
              _row('Delivery fee', '${q.deliveryFee.toStringAsFixed(2)} DT'),
              const Divider(),
              _row('Total', '${q.total.toStringAsFixed(2)} DT', bold: true),
              const SizedBox(height: 4),
              const Text(
                'The delivery fee depends on the distance between the restaurant '
                    'and your location. A flat fee applies if no location is selected.',
                style: TextStyle(color: AppTheme.textMedium, fontSize: 12),
              ),
            ],
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (_placing || _quote == null) ? null : _placeOrder,
              child: _placing
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : const Text('Place Order',
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}