import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../services/store_service.dart';
import 'catalog_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final StoreService _storeService = StoreService();
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
    _initBluetooth();
  }

  Future<void> _loadStoreInfo() async {
    final info = await _storeService.getStoreInfo();
    setState(() {
      _nameCtrl.text = info.name;
      _addressCtrl.text = info.address;
      _phoneCtrl.text = info.phone;
    });
  }

  Future<void> _saveStoreInfo() async {
    final newInfo = StoreInfo(
      name: _nameCtrl.text,
      address: _addressCtrl.text,
      phone: _phoneCtrl.text,
    );
    await _storeService.saveStoreInfo(newInfo);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store info saved!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _initBluetooth() async {
    try {
      final devices = await _bluetooth.getBondedDevices();
      final isConnected = await _bluetooth.isConnected;
      
      if (!mounted) return;
      
      setState(() {
        _devices = devices;
        _connected = isConnected ?? false;
      });
    } catch (e) {
      debugPrint('Bluetooth Error: $e');
    }
  }

  Future<void> _connectBluetooth() async {
    if (_selectedDevice != null) {
      try {
        await _bluetooth.connect(_selectedDevice!);
        setState(() => _connected = true);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected to ${_selectedDevice!.name}'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to connect to printer'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _disconnectBluetooth() async {
    await _bluetooth.disconnect();
    setState(() => _connected = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Store Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Store Information', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Store Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _saveStoreInfo,
                        child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bluetooth Printer Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bluetooth Printer', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
                        IconButton(icon: const Icon(Icons.refresh), onPressed: _initBluetooth),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<BluetoothDevice>(
                          isExpanded: true,
                          hint: const Text('Select Printer Device'),
                          value: _selectedDevice,
                          items: _devices.map((device) => DropdownMenuItem(
                            value: device,
                            child: Text(device.name ?? 'Unknown Device'),
                          )).toList(),
                          onChanged: (device) => setState(() => _selectedDevice = device),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _connected ? Colors.grey : Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _connected ? null : _connectBluetooth,
                            icon: const Icon(Icons.bluetooth_connected),
                            label: const Text('Connect'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                           style: ElevatedButton.styleFrom(
                              backgroundColor: !_connected ? Colors.grey : Colors.red.shade700,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: !_connected ? null : _disconnectBluetooth,
                            icon: const Icon(Icons.bluetooth_disabled),
                            label: const Text('Disconnect'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Products Management Card
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.secondary),
                ),
                title: const Text('Products & Catalog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: const Text('Add, edit, and remove products'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CatalogScreen()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
