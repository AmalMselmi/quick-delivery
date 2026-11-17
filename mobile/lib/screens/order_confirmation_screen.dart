import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'orders_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final int orderId;
  final String address;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: AppTheme.primary, size: 100),
              const SizedBox(height: 16),
              Text('Order #$orderId placed',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Your order will be delivered to:',
                  style: TextStyle(color: AppTheme.textMedium)),
              const SizedBox(height: 4),
              Text(address,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textDark)),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                      (route) => route.isFirst,
                ),
                child: const Text('Track my order'),
              ),
              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}