import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/cart_item.dart';
import 'store_service.dart';

class PrintService {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  final StoreService _storeService = StoreService();

  Future<void> printBill(List<CartItem> cart) async {
    final bool? isConnected = await _bluetooth.isConnected;
    
    if (isConnected == true) {
      await _printViaBluetooth(cart);
    } else {
      await _printViaPdf(cart);
    }
  }

  Future<void> _printViaBluetooth(List<CartItem> cart) async {
    final StoreInfo store = await _storeService.getStoreInfo();
    final double total = cart.fold(0, (sum, item) => sum + item.total);
    final String dateStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    _bluetooth.printCustom(store.name.isEmpty ? "STORE NAME" : store.name, 3, 1);
    if (store.address.isNotEmpty) _bluetooth.printCustom(store.address, 1, 1);
    if (store.phone.isNotEmpty) _bluetooth.printCustom("Tel: ${store.phone}", 1, 1);
    
    _bluetooth.printNewLine();
    _bluetooth.printCustom("Date: $dateStr", 1, 0);
    _bluetooth.printCustom("--------------------------------", 1, 1);
    
    for (var cartItem in cart) {
      _bluetooth.printCustom(cartItem.item.name, 1, 0);
      _bluetooth.printCustom("${cartItem.quantity} x Rs.${cartItem.item.price.toStringAsFixed(2)}    Rs.${cartItem.total.toStringAsFixed(2)}", 1, 2);
    }
    
    _bluetooth.printCustom("--------------------------------", 1, 1);
    _bluetooth.printCustom("TOTAL: Rs.${total.toStringAsFixed(2)}", 2, 1);
    _bluetooth.printNewLine();
    _bluetooth.printCustom("Thank you for shopping!", 1, 1);
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.paperCut();
  }

  Future<void> _printViaPdf(List<CartItem> cart) async {
    final StoreInfo store = await _storeService.getStoreInfo();
    final pdf = pw.Document();
    
    final double total = cart.fold(0, (sum, item) => sum + item.total);
    final String dateStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(store.name.isEmpty ? 'STORE NAME' : store.name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              if (store.address.isNotEmpty) pw.Center(child: pw.Text(store.address)),
              if (store.phone.isNotEmpty) pw.Center(child: pw.Text('Tel: ${store.phone}')),
              pw.SizedBox(height: 10),
              pw.Text('Date: $dateStr'),
              pw.Divider(),
              ...cart.map((cartItem) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text(cartItem.item.name)),
                      pw.Text('${cartItem.quantity} x ₹${cartItem.item.price.toStringAsFixed(2)}'),
                      pw.SizedBox(width: 8),
                      pw.Text('₹${cartItem.total.toStringAsFixed(2)}'),
                    ]
                  )
                );
              }),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('₹${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ]
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Thank you for shopping!')),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
