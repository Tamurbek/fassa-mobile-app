import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../models/printer_model.dart';
import '../../logic/pos_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  String _formatPrice(dynamic amount) {
    double value = double.tryParse(amount.toString()) ?? 0.0;
    final formatter = NumberFormat("#,###", "en_US");
    return formatter.format(value).replaceAll(',', ' ');
  }

  Future<bool> printReceipt(PrinterModel printer, Map<String, dynamic> order, {String? title}) async {
    if (printer.ipAddress == null || printer.ipAddress!.isEmpty) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(
          printer.paperSize == '58mm' ? PaperSize.mm58 : PaperSize.mm80, profile);
      
      List<int> bytes = [];
      final posController = Get.find<POSController>();

      // --- Header: Restaurant Info ---
      bytes += generator.feed(1);
      bytes += generator.text(posController.restaurantName.value.toUpperCase(),
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            bold: true,
          ));
      
      if (posController.restaurantAddress.value.isNotEmpty) {
        bytes += generator.text(posController.restaurantAddress.value,
            styles: const PosStyles(align: PosAlign.center));
      }
      if (posController.restaurantPhone.value.isNotEmpty) {
        bytes += generator.text(posController.restaurantPhone.value,
            styles: const PosStyles(align: PosAlign.center));
      }
      bytes += generator.feed(1);
      
      // Ticket Title
      bytes += generator.text('*** ${title ?? "TO\'LOV CHEKI"} ***', 
          styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size1, width: PosTextSize.size1));
      bytes += generator.hr(ch: '=');

      // --- Order Info ---
      bytes += generator.row([
        PosColumn(text: 'CHЕK:', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(text: '#${order['id']}', width: 8, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
      
      bytes += generator.row([
        PosColumn(text: 'SANA:', width: 4),
        PosColumn(text: DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()), width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);

      String modeName = "ZALDA";
      if (order['mode'] == "Takeaway") modeName = "OLIB KETISH";
      else if (order['mode'] == "Delivery") modeName = "YETKAZIB BERISH";
      
      bytes += generator.row([
        PosColumn(text: 'TURI:', width: 4),
        PosColumn(text: modeName, width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);

      if (order['table'] != null && order['table'] != '-') {
        bytes += generator.row([
          PosColumn(text: 'STOL:', width: 4, styles: const PosStyles(bold: true)),
          PosColumn(text: '${order['table']}', width: 8, styles: const PosStyles(align: PosAlign.right, bold: true)),
        ]);
      }
      bytes += generator.hr(ch: '-');

      // --- Items Table ---
      bytes += generator.row([
        PosColumn(text: 'NOMI', width: 7, styles: const PosStyles(bold: true)),
        PosColumn(text: 'SONI', width: 2, styles: const PosStyles(bold: true, align: PosAlign.center)),
        PosColumn(text: 'NARXI', width: 3, styles: const PosStyles(bold: true, align: PosAlign.right)),
      ]);
      bytes += generator.hr(ch: '-');

      final items = order['details'] as List;
      double itemsSubtotal = 0;
      for (var item in items) {
        double price = double.tryParse(item['price'].toString()) ?? 0.0;
        int qty = int.tryParse(item['qty'].toString()) ?? 0;
        double lineTotal = price * qty;
        itemsSubtotal += lineTotal;

        // Long names support: wrap if needed (handled by row or manually)
        bytes += generator.row([
          PosColumn(text: item['name'], width: 7),
          PosColumn(text: qty.toString(), width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: _formatPrice(lineTotal), width: 3, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      bytes += generator.hr(ch: '-');

      // --- Totals ---
      double serviceFee = 0;
      if (order['mode'] == "Dine-in") {
        serviceFee = itemsSubtotal * 0.10;
      } else if (order['mode'] == "Delivery") {
        serviceFee = 3000; // Example fixed fee if delivery
      }
      
      double tax = itemsSubtotal * 0.05;
      double finalTotal = itemsSubtotal + serviceFee + tax;

      bytes += generator.row([
        PosColumn(text: 'JAMI:', width: 7),
        PosColumn(text: '${_formatPrice(itemsSubtotal)} so\'m', width: 5, styles: const PosStyles(align: PosAlign.right)),
      ]);

      if (serviceFee > 0) {
        bytes += generator.row([
          PosColumn(text: 'XIZMAT HAQI:', width: 7),
          PosColumn(text: '${_formatPrice(serviceFee)} so\'m', width: 5, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }

      bytes += generator.row([
        PosColumn(text: 'SOLIQ (5%):', width: 7),
        PosColumn(text: '${_formatPrice(tax)} so\'m', width: 5, styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.hr(ch: '=');
      bytes += generator.row([
        PosColumn(text: 'TO\'LOV:', width: 5, styles: const PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size1)),
        PosColumn(text: '${_formatPrice(finalTotal)} so\'m', width: 7, styles: const PosStyles(bold: true, align: PosAlign.right, height: PosTextSize.size2, width: PosTextSize.size1)),
      ]);
      bytes += generator.hr(ch: '=');

      // --- Footer ---
      bytes += generator.feed(1);
      bytes += generator.text('*** Xaridingiz uchun rahmat! ***', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('YANA KELING!', styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.feed(3);
      bytes += generator.cut();

      final socket = await Socket.connect(printer.ipAddress, printer.port,
          timeout: const Duration(seconds: 5));
      socket.add(bytes);
      await socket.flush();
      await socket.close();
      
      return true;
    } catch (e) {
      print('Printing error: $e');
      return false;
    }
  }

  Future<bool> printKitchenTicket(PrinterModel printer, Map<String, dynamic> order, List<dynamic> items) async {
    if (printer.ipAddress == null || printer.ipAddress!.isEmpty || items.isEmpty) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(
          printer.paperSize == '58mm' ? PaperSize.mm58 : PaperSize.mm80, profile);
      
      List<int> bytes = [];

      // Large Header
      bytes += generator.feed(1);
      bytes += generator.text('OSHXONA CHEKI',
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            bold: true,
          ));
      bytes += generator.hr(ch: '=');

      // Order & Table Info (XL Size)
      bytes += generator.text('STOL: ${order['table']}', 
          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true, align: PosAlign.center));
      bytes += generator.text('BUYURTMA: #${order['id']}', 
          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true, align: PosAlign.center));
      
      bytes += generator.feed(1);
      bytes += generator.text('VAQT: ${DateFormat('HH:mm').format(DateTime.now())}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.hr(ch: '-');

      // Items (Large and Bold)
      for (var item in items) {
        bytes += generator.row([
          PosColumn(text: '${item['qty']} x', width: 3, styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true)),
          PosColumn(text: '${item['name']}', width: 9, styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size1, bold: true)),
        ]);
        
        if (item['note'] != null && item['note'].toString().isNotEmpty) {
          bytes += generator.text(' >> IZOH: ${item['note']}', styles: const PosStyles(bold: true));
        }
        bytes += generator.hr(ch: '.');
      }

      bytes += generator.feed(3);
      bytes += generator.cut();

      final socket = await Socket.connect(printer.ipAddress, printer.port,
          timeout: const Duration(seconds: 5));
      socket.add(bytes);
      await socket.flush();
      await socket.close();
      
      return true;
    } catch (e) {
      print('Kitchen printing error: $e');
      return false;
    }
  }

  Future<bool> printCancellationTicket(PrinterModel printer, Map<String, dynamic> order, List<dynamic> items) async {
    if (printer.ipAddress == null || printer.ipAddress!.isEmpty || items.isEmpty) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(
          printer.paperSize == '58mm' ? PaperSize.mm58 : PaperSize.mm80, profile);
      
      List<int> bytes = [];

      // Large Header - Red-like warning (Capitalized and Bold)
      bytes += generator.feed(1);
      bytes += generator.text('!!! BEKOR QILINDI !!!',
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            bold: true,
          ));
      bytes += generator.hr(ch: '*');

      // Order & Table Info
      bytes += generator.text('STOL: ${order['table']}', 
          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true, align: PosAlign.center));
      bytes += generator.text('BUYURTMA: #${order['id']}', 
          styles: const PosStyles(height: PosTextSize.size1, width: PosTextSize.size1, bold: true, align: PosAlign.center));
      
      bytes += generator.feed(1);
      bytes += generator.text('VAQT: ${DateFormat('HH:mm').format(DateTime.now())}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.hr(ch: '-');

      // Cancelled Items
      for (var item in items) {
        bytes += generator.row([
          PosColumn(text: '${item['qty']} x', width: 3, styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true)),
          PosColumn(text: '${item['name']}', width: 9, styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size1, bold: true)),
        ]);
        bytes += generator.hr(ch: '-');
      }

      bytes += generator.feed(3);
      bytes += generator.cut();

      final socket = await Socket.connect(printer.ipAddress, printer.port,
          timeout: const Duration(seconds: 5));
      socket.add(bytes);
      await socket.flush();
      await socket.close();
      
      return true;
    } catch (e) {
      print('Cancellation printing error: $e');
      return false;
    }
  }

  Future<bool> printTestPage(PrinterModel printer) async {
    if (printer.ipAddress == null || printer.ipAddress!.isEmpty) return false;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(
          printer.paperSize == '58mm' ? PaperSize.mm58 : PaperSize.mm80, profile);
      List<int> bytes = [];

      bytes += generator.text('TEST PRINT',
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            bold: true,
          ));
      bytes += generator.text('Printer: ${printer.name}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('IP: ${printer.ipAddress}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Port: ${printer.port}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.hr();
      bytes += generator.text('If you see this, your printer is working correctly.', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(3);
      bytes += generator.cut();

      final socket = await Socket.connect(printer.ipAddress, printer.port,
          timeout: const Duration(seconds: 5));
      socket.add(bytes);
      await socket.flush();
      await socket.close();
      return true;
    } catch (e) {
      print('Test print error: $e');
      return false;
    }
  }
}
