import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

class CatalogService {
  static const String _storageKey = 'catalog_items';

  Future<List<Item>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsString = prefs.getStringList(_storageKey) ?? [];
    return itemsString
        .map((itemStr) => Item.fromJson(json.decode(itemStr)))
        .toList();
  }

  Future<void> saveItem(Item item) async {
    final items = await getItems();
    final existingIndex = items.indexWhere((i) => i.sku == item.sku);
    if (existingIndex >= 0) {
      items[existingIndex] = item;
    } else {
      items.add(item);
    }
    await _saveAll(items);
  }

  Future<void> deleteItem(String sku) async {
    final items = await getItems();
    items.removeWhere((i) => i.sku == sku);
    await _saveAll(items);
  }

  Future<Item?> getItemBySku(String sku) async {
    final items = await getItems();
    try {
      return items.firstWhere((item) => item.sku == sku);
    } catch(e) {
      return null;
    }
  }

  Future<void> _saveAll(List<Item> items) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsString = items.map((item) => json.encode(item.toJson())).toList();
    await prefs.setStringList(_storageKey, itemsString);
  }
}
