import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';

class HistoryService {
  static const String _storageKey = 'order_history';

  Future<List<Order>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersString = prefs.getStringList(_storageKey) ?? [];
    return ordersString
        .map((orderStr) => Order.fromJson(json.decode(orderStr)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort newest first
  }

  Future<void> saveOrder(Order order) async {
    final orders = await getOrders();
    orders.add(order);
    
    final prefs = await SharedPreferences.getInstance();
    final ordersString = orders.map((o) => json.encode(o.toJson())).toList();
    await prefs.setStringList(_storageKey, ordersString);
  }
  
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
