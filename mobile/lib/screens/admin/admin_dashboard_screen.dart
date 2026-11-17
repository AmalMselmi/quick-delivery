import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart' show apiServiceProvider;
import '../../theme.dart';
import '../../utils/order_status.dart';
import '../login_screen.dart';
import 'admin_menu_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_restaurants_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  AdminStats? _stats;
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
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final token = ref.read(authProvider).token ?? '';
      final stats = await ref.read(apiServiceProvider).fetchAdminStats(token);
      if (!mounted) return;
      setState(() {
        _stats = stats;
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

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _load(silent: true));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final s = _stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
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
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back,',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text(auth.userName ?? 'Admin',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),

                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary)),
              )
            else if (_error != null)
              Column(
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              )
            else if (s != null) ...[
                Row(
                  children: [
                    Expanded(
                        child: _StatTile(
                            icon: Icons.receipt_long,
                            label: 'Orders today',
                            value: '${s.ordersToday}')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _StatTile(
                            icon: Icons.payments_outlined,
                            label: 'Revenue today',
                            value: '${s.revenueToday.toStringAsFixed(2)} DT')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _StatTile(
                            icon: Icons.hourglass_top,
                            label: 'Pending',
                            value: '${s.pending}')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _StatTile(
                            icon: Icons.people_outline,
                            label: 'Clients',
                            value: '${s.clients}')),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Recent orders',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (s.recent.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No orders yet'),
                  )
                else
                  ...s.recent.map((o) => Card(
                    child: ListTile(
                      onTap: () => _open(const AdminOrdersScreen()),
                      title: Text('Order #${o.id}  |  ${o.customerName}'),
                      subtitle: Text('${o.total.toStringAsFixed(2)} DT'),
                      trailing: Text(
                        orderStatusLabels[o.status] ?? o.status,
                        style: TextStyle(
                            color: orderStatusColor(o.status),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  )),
              ],
            const SizedBox(height: 24),
            const Text('Manage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _NavCard(
              icon: Icons.receipt_long,
              title: 'Orders',
              subtitle: 'View orders and update their status',
              onTap: () => _open(const AdminOrdersScreen()),
            ),
            _NavCard(
              icon: Icons.store_rounded,
              title: 'Restaurants',
              subtitle: 'Add, edit or remove restaurants',
              onTap: () => _open(const AdminRestaurantsScreen()),
            ),
            _NavCard(
              icon: Icons.restaurant_menu_rounded,
              title: 'Menu Items',
              subtitle: 'Add, edit or remove menu items',
              onTap: () => _open(const AdminMenuScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(height: 10),
          Text(value,
              style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label,
              style:
              const TextStyle(color: AppTheme.textMedium, fontSize: 12)),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.primary),
        title:
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}