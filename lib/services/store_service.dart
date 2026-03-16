import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StoreInfo {
  final String name;
  final String address;
  final String phone;

  StoreInfo({this.name = '', this.address = '', this.phone = ''});

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'phone': phone,
  };

  factory StoreInfo.fromJson(Map<String, dynamic> json) => StoreInfo(
    name: json['name'] ?? '',
    address: json['address'] ?? '',
    phone: json['phone'] ?? '',
  );
}

class StoreService {
  static const String _key = 'store_info';

  Future<StoreInfo> getStoreInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      return StoreInfo.fromJson(jsonDecode(data));
    }
    return StoreInfo(); // default empty
  }

  Future<void> saveStoreInfo(StoreInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(info.toJson()));
  }
}
