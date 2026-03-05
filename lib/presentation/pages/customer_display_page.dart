import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import '../../theme/app_colors.dart';

class CustomerDisplayPage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const CustomerDisplayPage({super.key, required this.initialData});

  @override
  State<CustomerDisplayPage> createState() => _CustomerDisplayPageState();
}

class _CustomerDisplayPageState extends State<CustomerDisplayPage> {
  List<dynamic> items = [];
  double total = 0.0;
  String restaurantName = "";
  String currency = "so'm";

  @override
  void initState() {
    super.initState();
    _updateData(widget.initialData);
    
    // Listen for updates from main window
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'updateData') {
        final data = jsonDecode(call.arguments);
        _updateData(data);
      }
      return null;
    });
  }

  void _updateData(Map<String, dynamic> data) {
    setState(() {
      items = data['items'] ?? [];
      total = (data['total'] ?? 0.0).toDouble();
      restaurantName = data['restaurantName'] ?? "Fassa";
      currency = data['currency'] ?? "so'm";
    });
  }

  String _formatPrice(dynamic amount) {
    double value = double.tryParse(amount.toString()) ?? 0.0;
    final formatter = NumberFormat("#,###", "en_US");
    return "${formatter.format(value).replaceAll(',', ' ')} $currency";
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = AppColors.background;
    const accentColor = AppColors.primary;
    const textColor = AppColors.textPrimary;
    const secondaryTextColor = AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // Left Side: Order List
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: textColor.withOpacity(0.05))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.shopping_cart_outlined, color: accentColor, size: 30),
                      ),
                      const SizedBox(width: 20),
                      const Text(
                        "Sizning Buyurtmangiz",
                        style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restaurant, color: textColor.withOpacity(0.05), size: 100),
                                const SizedBox(height: 20),
                                Text(
                                  "Xush kelibsiz!",
                                  style: TextStyle(color: secondaryTextColor, fontSize: 24),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => Divider(color: textColor.withOpacity(0.05), height: 30),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] ?? "",
                                          style: const TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w600),
                                        ),
                                        if (item['variant'] != null)
                                          Text(
                                            item['variant'],
                                            style: const TextStyle(color: secondaryTextColor, fontSize: 16),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${item['quantity']} x",
                                    style: const TextStyle(color: secondaryTextColor, fontSize: 20),
                                  ),
                                  const SizedBox(width: 30),
                                  Text(
                                    _formatPrice((item['price'] ?? 0) * (item['quantity'] ?? 1)),
                                    style: const TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Side: Summary & Total
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(50),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: accentColor.withOpacity(0.1),
                    child: Text(
                      restaurantName.isNotEmpty ? restaurantName[0] : "F",
                      style: const TextStyle(color: accentColor, fontSize: 50, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    restaurantName,
                    style: const TextStyle(color: textColor, fontSize: 30, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "UMUMIY SUMMA",
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _formatPrice(total),
                          style: const TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Xaridingiz uchun rahmat!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryTextColor, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
