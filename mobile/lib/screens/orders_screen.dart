import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/restaurant_provider.dart' show apiServiceProvider;
import '../theme.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(
        const Duration(seconds: 15), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final token = ref.read(authProvider).token ?? '';
      final result = await ref.read(apiServiceProvider).fetchMyOrders(token);
      if (!mounted) return;
      setState(() { _orders = result; _loading = false; _error = null; });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  static const _labels = {
    'pending': 'Pending',
    'preparing': 'Preparing',
    'on_the_way': 'On the way',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  Color _statusColor(String s) {
    switch (s) {
      case 'preparing':
        return Colors.orange;
      case 'on_the_way':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _date(DateTime? d) {
    if (d == null) return '';
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year}  ${d.hour}:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      )
          : _orders.isEmpty
          ? const Center(child: Text('You have no orders yet'))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _orders.length,
          itemBuilder: (_, i) {
            final o = _orders[i];
            final color = _statusColor(o.status);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Order #${o.id}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_labels[o.status] ?? o.status,
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_date(o.createdAt),
                        style: const TextStyle(
                            color: AppTheme.textMedium,
                            fontSize: 12)),
                    const Divider(height: 20),
                    ...o.items.map((it) => Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(
                                  '${it.quantity} x ${it.name}')),
                          Text(
                              '${(it.price * it.quantity).toStringAsFixed(2)} DT'),
                        ],
                      ),
                    )),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('${o.total.toStringAsFixed(2)} DT',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(o.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textMedium,
                            fontSize: 12)),
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