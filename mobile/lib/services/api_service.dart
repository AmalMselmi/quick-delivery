import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

class ApiService {
  // Android emulator → use 10.0.2.2
  // Physical device  → use your PC's local IP e.g. 192.168.1.5
  static const baseUrl = 'http://10.0.2.2:8000/api';

  // Helper to build headers
  Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // AUTH

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Login failed');
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers(),
      body: jsonEncode({'name': name, 'email': email, 'password': password, 'role': 'client'}),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(res.body);
    if (res.statusCode == 201) return data;
    throw Exception(data['message'] ?? 'Registration failed');
  }

  Future<void> logout(String token) async {
    await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 10));
  }

  // RESTAURANTS (public)

  Future<List<Restaurant>> fetchRestaurants() async {
    final res = await http
        .get(Uri.parse('$baseUrl/restaurants'), headers: _headers())
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).map((e) => Restaurant.fromJson(e)).toList();
    }
    throw Exception('Failed to load restaurants');
  }

  // MENU (public)

  Future<List<MenuItem>> fetchMenu(int restaurantId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/menu?restaurantId=$restaurantId'), headers: _headers())
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).map((e) => MenuItem.fromJson(e)).toList();
    }
    throw Exception('Failed to load menu');
  }

  // ADMIN: RESTAURANT CRUD

  Future<Restaurant> createRestaurant(Map<String, dynamic> data, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/restaurants'),
      headers: _headers(token: token),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 201) return Restaurant.fromJson(jsonDecode(res.body));
    throw Exception(jsonDecode(res.body)['message'] ?? 'Failed to create restaurant');
  }

  Future<Restaurant> updateRestaurant(int id, Map<String, dynamic> data, String token) async {
    final res = await http.put(
      Uri.parse('$baseUrl/admin/restaurants/$id'),
      headers: _headers(token: token),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return Restaurant.fromJson(jsonDecode(res.body));
    throw Exception(jsonDecode(res.body)['message'] ?? 'Failed to update restaurant');
  }

  Future<void> deleteRestaurant(int id, String token) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/admin/restaurants/$id'),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Failed to delete restaurant');
  }

  // ADMIN: MENU CRUD
  Future<MenuItem> createMenuItem(Map<String, dynamic> data, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/menu'),
      headers: _headers(token: token),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 201) return MenuItem.fromJson(jsonDecode(res.body));
    throw Exception(jsonDecode(res.body)['message'] ?? 'Failed to create menu item');
  }

  Future<MenuItem> updateMenuItem(int id, Map<String, dynamic> data, String token) async {
    final res = await http.put(
      Uri.parse('$baseUrl/admin/menu/$id'),
      headers: _headers(token: token),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return MenuItem.fromJson(jsonDecode(res.body));
    throw Exception(jsonDecode(res.body)['message'] ?? 'Failed to update menu item');
  }

  Future<void> deleteMenuItem(int id, String token) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/admin/menu/$id'),
      headers: _headers(token: token),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Failed to delete menu item');
  }

  Future<Order> createOrder(Map<String, dynamic> data, String token) async {
    final res = await http
        .post(
      Uri.parse('$baseUrl/orders'),
      headers: _headers(token: token),
      body: jsonEncode(data),
    )
        .timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode == 201) return Order.fromJson(body);
    throw Exception(body['message'] ?? 'Failed to place order');
  }

  Future<List<Order>> fetchMyOrders(String token) async {
    final res = await http
        .get(Uri.parse('$baseUrl/orders'), headers: _headers(token: token))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load orders');
  }
  Future<Quote> quoteOrder(Map<String, dynamic> data, String token) async {
    final res = await http
        .post(
      Uri.parse('$baseUrl/orders/quote'),
      headers: _headers(token: token),
      body: jsonEncode(data),
    )
        .timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return Quote.fromJson(body);
    throw Exception(body['message'] ?? 'Could not calculate delivery fee');
  }

  Future<List<Order>> fetchAdminOrders(String token, {String? status}) async {
    final uri = Uri.parse('$baseUrl/admin/orders').replace(
      queryParameters: status == null ? null : {'status': status},
    );
    final res = await http
        .get(uri, headers: _headers(token: token))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load orders');
  }

  Future<Order> updateOrderStatus(int id, String status, String token) async {
    final res = await http
        .put(
      Uri.parse('$baseUrl/admin/orders/$id/status'),
      headers: _headers(token: token),
      body: jsonEncode({'status': status}),
    )
        .timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return Order.fromJson(body);
    throw Exception(body['message'] ?? 'Failed to update status');
  }

  Future<AdminStats> fetchAdminStats(String token) async {
    final res = await http
        .get(Uri.parse('$baseUrl/admin/stats'), headers: _headers(token: token))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return AdminStats.fromJson(jsonDecode(res.body));
    throw Exception('Failed to load dashboard');
  }
}