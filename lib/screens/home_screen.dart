import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/catalog_service.dart';
import '../services/print_service.dart';
import '../services/history_service.dart';
import 'history_screen.dart';
import 'account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CatalogService _catalogService = CatalogService();
  final PrintService _printService = PrintService();
  final HistoryService _historyService = HistoryService();
  
  final List<CartItem> _cart = [];
  bool _isScanning = true;
  String _lastScannedSku = '';
  DateTime _lastScanTime = DateTime.fromMillisecondsSinceEpoch(0);

  double get _total => _cart.fold(0, (sum, item) => sum + item.total);

  void _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String code = barcodes.first.rawValue!;
      
      // Debounce to prevent rapid duplicate scans
      if (code == _lastScannedSku && DateTime.now().difference(_lastScanTime).inSeconds < 2) {
        return;
      }
      
      _lastScannedSku = code;
      _lastScanTime = DateTime.now();

      final item = await _catalogService.getItemBySku(code);
      if (!mounted) return;

      if (item != null) {
        setState(() {
          final existing = _cart.indexWhere((c) => c.item.sku == item.sku);
          if (existing >= 0) {
            _cart[existing].quantity++;
          } else {
            _cart.insert(0, CartItem(item: item)); // Add to top of list
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${item.name} to bill!', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item not found: $code. Please add to catalog.', style: const TextStyle(color: Colors.white)),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      _cart[index].quantity += delta;
      if (_cart[index].quantity <= 0) {
        _cart.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Billing System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Order History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined),
            tooltip: 'Account & Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AccountScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Integrated Small Scanner section
          Container(
            height: 220,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
              ]
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _isScanning
                    ? MobileScanner(
                        onDetect: _onDetect,
                        errorBuilder: (context, error) => const Center(child: Text('Camera error', style: TextStyle(color: Colors.red))),
                      )
                    : Container(color: Colors.black87, child: const Center(child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 50))),
                
                // Overlay for scanner
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: FloatingActionButton.small(
                    onPressed: () => setState(() => _isScanning = !_isScanning),
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: Icon(_isScanning ? Icons.pause : Icons.play_arrow, color: Colors.black),
                  ),
                ),
                if (_isScanning)
                  Center(
                    child: Container(
                      width: 200,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
              ],
            ),
          ),
          
          // Header for the list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Bill',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
                ),
                Text(
                  '${_cart.length} Items',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
          ),

          // List of items added (shown directly under scanner)
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Scan items to add to the cart', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final cartItem = _cart[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.shopping_bag_outlined, color: Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cartItem.item.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('₹${cartItem.item.price.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                    onPressed: () => _updateQuantity(index, -1),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('${cartItem.quantity}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                                    onPressed: () => _updateQuantity(index, 1),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  '₹${cartItem.total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Bottom Total & Print Section
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Amount', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(
                        '₹${_total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28, color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: _cart.isEmpty ? null : () async {
                      // 1. Save to history
                      final newOrder = Order(items: List.from(_cart), total: _total);
                      await _historyService.saveOrder(newOrder);

                      // 2. Print
                      await _printService.printBill(_cart);
                      
                      setState(() {
                        _cart.clear();
                      });
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order saved to history and printed!')),
                      );
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print Bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
