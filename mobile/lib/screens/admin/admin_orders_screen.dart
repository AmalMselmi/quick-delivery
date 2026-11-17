import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart' show apiServiceProvider;
import '../../theme.dart';
import '../../utils/order_status.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final _filterScroll = ScrollController();
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  String? _filter;
  Timer? _timer;

  String get _token => ref.read(authProvider).token ?? '';

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
    _filterScroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await ref
          .read(apiServiceProvider)
          .fetchAdminOrders(_token, status: _filter);
      if (!mounted) return;
      setState(() {
        _orders = result;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _setStatus(Order order, String status) async {
    try {
      await ref
          .read(apiServiceProvider)
          .updateOrderStatus(order.id, status, _token);
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red.shade700,
      ));
    }
  }

  String _date(DateTime? d) {
    if (d == null) return '';
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year}  ${d.hour}:$m';
  }

  Widget _filters() {
    final options = <String?>[null, ...orderStatusLabels.keys];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Scrollbar(
        controller: _filterScroll,
        thumbVisibility: true,
        thickness: 4,
        child: SingleChildScrollView(
          controller: _filterScroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            children: options.map((s) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s == null ? 'All' : orderStatusLabels[s]!),
                  selected: _filter == s,
                  onSelected: (_) {
                    setState(() => _filter = s);
                    _load();
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _statusMenu(Order o) {
    final color = orderStatusColor(o.status);
    return PopupMenuButton<String>(
      onSelected: (s) => _setStatus(o, s),
      itemBuilder: (_) => orderStatusLabels.entries
          .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(orderStatusLabels[o.status] ?? o.status,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            Icon(Icons.arrow_drop_down, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _orderCard(Order o) {
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
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                _statusMenu(o),
              ],
            ),
            const SizedBox(height: 4),
            Text('${o.customerName}  |  ${_date(o.createdAt)}',
                style: const TextStyle(
                    color: AppTheme.textMedium, fontSize: 12)),
            const Divider(height: 20),
            ...o.items.map((it) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Text('${it.quantity} x ${it.name}')),
                  Text(
                      '${(it.price * it.quantity).toStringAsFixed(2)} DT'),
                ],
              ),
            )),
            const Divider(height: 20),
            Row(
              children: [
                const Text('Delivery fee'),
                const Spacer(),
                Text('${o.deliveryFee.toStringAsFixed(2)} DT'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${o.total.toStringAsFixed(2)} DT',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(o.address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppTheme.textMedium, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Column(
        children: [
          _filters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
                : _orders.isEmpty
                ? const Center(child: Text('No orders'))
                : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (_, i) => _orderCard(_orders[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}