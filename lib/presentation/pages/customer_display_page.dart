import 'dart:async';
import 'dart:convert';
import 'dart:ui';
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
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateData(widget.initialData);
    
    // Clock timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    // Listen for updates from main window
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'updateData') {
        final data = jsonDecode(call.arguments);
        _updateData(data);
      }
      return null;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateData(Map<String, dynamic> data) {
    if (mounted) {
      setState(() {
        items = data['items'] ?? [];
        total = (data['total'] ?? 0.0).toDouble();
        restaurantName = data['restaurantName'] ?? "Fassa";
        currency = data['currency'] ?? "so'm";
      });
    }
  }

  String _formatPrice(dynamic amount) {
    double value = double.tryParse(amount.toString()) ?? 0.0;
    final formatter = NumberFormat("#,###", "en_US");
    return "${formatter.format(value).replaceAll(',', ' ')} $currency";
  }

  String _safeFormatDate(String pattern, String locale) {
    try {
      return DateFormat(pattern, locale).format(_now);
    } catch (e) {
      return DateFormat(pattern, 'en_US').format(_now);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Aesthetic
          _buildBackground(),

          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: animation.drive(Tween(begin: const Offset(0.05, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
                    child: child,
                  ),
                );
              },
              child: items.isEmpty 
                ? _buildIdleState() 
                : _buildOrderState(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF9500).withOpacity(0.08),
                    const Color(0xFFFF9500).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blue.withOpacity(0.05),
                    Colors.blue.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    String timeStr = _safeFormatDate('HH:mm', 'en_US');
    String dateStr = _safeFormatDate('EEEE, d MMMM', 'uz_UZ').toUpperCase();

    return Center(
      key: const ValueKey("idle_state"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_rounded, size: 80, color: Color(0xFFFF9500)),
          const SizedBox(height: 30),
          Text(
            restaurantName.isNotEmpty ? restaurantName.toUpperCase() : "FAST FOOD PRO",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Text(
              "HUŞ KELIB SIZ! / ДОБРО ПОЖАЛОВАТЬ!",
              style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 60),
          _buildClockSection(Colors.white, Colors.white54),
        ],
      ),
    );
  }

  Widget _buildClockSection(Color primaryColor, Color secondaryColor) {
    String timeStr = _safeFormatDate('HH:mm', 'en_US');
    String secondsStr = _safeFormatDate(':ss', 'en_US');
    String dateStr = _safeFormatDate('EEEE, d MMMM', 'uz_UZ').toUpperCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              timeStr,
              style: TextStyle(
                color: primaryColor,
                fontSize: 100,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: -5,
              ),
            ),
            Text(
              secondsStr,
              style: const TextStyle(
                color: Color(0xFFFF9500),
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        Text(
          dateStr,
          style: TextStyle(
            color: secondaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderState() {
    return Row(
      key: const ValueKey("order_state"),
      children: [
        // Order Items List
        Expanded(
          flex: 5,
          child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("BUYURTMA TAFSILOTLARI", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    Text("Hush kelibsiz, $restaurantName".toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final double itemTotal = (item['price'] ?? 0).toDouble() * (item['quantity'] ?? 1).toDouble();
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9500).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${item['quantity']}x",
                            style: const TextStyle(color: Color(0xFFFF9500), fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                              if (item['variant'] != null)
                                Text(item['variant'], style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                            ],
                          ),
                        ),
                        Text(_formatPrice(itemTotal), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),

        Container(
          width: 480,
          padding: const EdgeInsets.all(50),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            border: Border(left: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Column(
            children: [
              _buildClockSection(Colors.white, Colors.white70),
              const Spacer(),
              _buildTotalCard(const Color(0xFFFF9500), total),
              const Spacer(),
              _buildFooter(Colors.white38),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(Color accentColor, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor, accentColor.withOpacity(0.9)],
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "UMUMIY SUMMA",
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, letterSpacing: 3, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 15),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatPrice(total),
              style: const TextStyle(color: Colors.white, fontSize: 55, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color secondaryTextColor) {
    return Column(
      children: [
        Text(
          "Xaridingiz uchun rahmat!",
          textAlign: TextAlign.center,
          style: TextStyle(color: secondaryTextColor, fontSize: 22, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 15),
        Opacity(
          opacity: 0.3,
          child: Image.asset('assets/images/app_icon.png', height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2, size: 40)),
        ),
      ],
    );
  }
}
