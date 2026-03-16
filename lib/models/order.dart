import 'package:uuid/uuid.dart';
import 'cart_item.dart';
import 'item.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final DateTime date;

  Order({
    String? id,
    required this.items,
    required this.total,
    DateTime? date,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((i) => {
        'sku': i.item.sku,
        'name': i.item.name,
        'price': i.item.price,
        'quantity': i.quantity,
      }).toList(),
      'total': total,
      'date': date.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = json['items'];
    final List<CartItem> parsedItems = itemsJson.map((itemData) {
      return CartItem(
        item: Item(
          sku: itemData['sku'],
          name: itemData['name'],
          price: (itemData['price'] as num).toDouble(),
        ),
        quantity: itemData['quantity'],
      );
    }).toList();

    return Order(
      id: json['id'],
      items: parsedItems,
      total: (json['total'] as num).toDouble(),
      date: DateTime.parse(json['date']),
    );
  }
}
