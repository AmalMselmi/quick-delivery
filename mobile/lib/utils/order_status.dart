import 'package:flutter/material.dart';

const orderStatusLabels = {
  'pending': 'Pending',
  'preparing': 'Preparing',
  'on_the_way': 'On the way',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
};

Color orderStatusColor(String status) {
  switch (status) {
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