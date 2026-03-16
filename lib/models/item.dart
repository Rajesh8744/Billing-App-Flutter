class Item {
  final String sku;
  final String name;
  final double price;

  Item({
    required this.sku,
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'name': name,
      'price': price,
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      sku: json['sku'],
      name: json['name'],
      price: json['price'].toDouble(),
    );
  }
}
