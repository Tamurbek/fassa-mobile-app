import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../logic/pos_controller.dart';
import 'package:fast_food_app/presentation/pages/product_management_screen.dart';
import 'package:fast_food_app/presentation/pages/printer_management_screen.dart';
import 'package:fast_food_app/presentation/pages/preparation_area_management_screen.dart';
import 'package:fast_food_app/presentation/pages/waiter_management_screen.dart';
import 'package:fast_food_app/presentation/pages/inventory_management_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static bool _isTablet(BuildContext ctx) => MediaQuery.of(ctx).size.width >= 700;

  @override
  Widget build(BuildContext context) {
    final POSController pos = Get.find<POSController>();
    final storage = GetStorage();
    final bool tablet = _isTablet(context);
    final int crossCount = tablet ? 3 : 2;
    final double pad = tablet ? 28.0 : 16.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "settings".tr,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Theme.of(context).textTheme.displayLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profil kartasi ──────────────────────────────────────────
            _ProfileCard(pos: pos),
            SizedBox(height: tablet ? 28 : 20),

            // ── Asosiy bo'limlar gridi ──────────────────────────────────
            if (pos.isAdmin) ...[
              _sectionLabel("Asosiy bo'limlar"),
              SizedBox(height: tablet ? 14 : 10),
              _MainSectionsGrid(pos: pos, crossCount: crossCount),
              SizedBox(height: tablet ? 28 : 20),
            ],

            // ── Printer sozlamalari ─────────────────────────────────────
            if (pos.isAdmin) ...[
              _sectionLabel("printer_settings".tr),
              SizedBox(height: tablet ? 14 : 10),
              _PrinterSettingsCard(pos: pos, storage: storage, context: context),
              SizedBox(height: tablet ? 28 : 20),
            ],

            // ── Restoran ma'lumotlari ───────────────────────────────────
            if (pos.isAdmin) ...[
              _sectionLabel("restaurant_info".tr),
              SizedBox(height: tablet ? 14 : 10),
              _RestaurantInfoCard(pos: pos, context: context, tablet: tablet),
              SizedBox(height: tablet ? 28 : 20),
            ],

            // ── Interfeys & Tizim ───────────────────────────────────────
            _sectionLabel("Interfeys & Tizim"),
            SizedBox(height: tablet ? 14 : 10),
            _SystemSettingsCard(pos: pos, storage: storage, context: context),
            SizedBox(height: tablet ? 28 : 20),

            // ── Chiqish tugmasi ─────────────────────────────────────────
            _LogoutRow(pos: pos),
            const SizedBox(height: 24),

            const Center(
              child: Text(
                "© 2026 Fassa POS",
                style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 0),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF9CA3AF),
            letterSpacing: 1.2,
          ),
        ),
      );

  // ────────────────────────────────────────────────────────────────
  void _showLanguageSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sizning tilingiz / Ваш язык / Your Language",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            _langTile("O'zbekcha", 'uz', 'UZ'),
            _langTile("English", 'en', 'US'),
            _langTile("Русский", 'ru', 'RU'),
          ],
        ),
      ),
    );
  }

  static Widget _langTile(String label, String code, String country) {
    final bool sel = Get.locale?.languageCode == code;
    return ListTile(
      title: Text(label,
          style: TextStyle(
            fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
            color: sel ? const Color(0xFFFF9500) : const Color(0xFF1A1A1A),
          )),
      trailing: sel ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF9500)) : null,
      onTap: () {
        Get.updateLocale(Locale(code, country));
        GetStorage().write('lang', '${code}_$country');
        Get.back();
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  PROFIL KARTASI
// ══════════════════════════════════════════════════════════════════════════════
class _ProfileCard extends StatelessWidget {
  final POSController pos;
  const _ProfileCard({required this.pos});

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.of(context).size.width >= 700;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(wide ? 28 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9500), Color(0xFFFF6B00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9500).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: wide ? 72 : 60,
            height: wide ? 72 : 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset('assets/logo.png', width: wide ? 54 : 44, height: wide ? 54 : 44),
            ),
          ),
          SizedBox(width: wide ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(pos.restaurantName.value,
                    style: TextStyle(
                      fontSize: wide ? 22 : 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ))),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on, size: 13, color: Colors.white70),
                  const SizedBox(width: 4),
                  Obx(() => Flexible(
                    child: Text(pos.restaurantAddress.value,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  )),
                ]),
                const SizedBox(height: 10),
                Obx(() {
                  final isVip = pos.isVip.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.stars_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        isVip ? "VIP — CHEKSIZ OBUNA" : "STANDART PLAN",
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ]),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ASOSIY BO'LIMLAR GRIDI (Xodimlar, Menyu, Inventar)
// ══════════════════════════════════════════════════════════════════════════════
class _MainSectionsGrid extends StatelessWidget {
  final POSController pos;
  final int crossCount;
  const _MainSectionsGrid({required this.pos, required this.crossCount});

  @override
  Widget build(BuildContext context) {
    final sections = [
      _SectionItem(
        icon: Icons.badge_rounded,
        label: "waiter_management".tr,
        color: const Color(0xFF6366F1),
        onTap: () => Get.to(() => const StaffManagementScreen()),
      ),
      _SectionItem(
        icon: Icons.restaurant_menu_rounded,
        label: "menu_management".tr,
        color: const Color(0xFF10B981),
        onTap: () => Get.to(() => ProductManagementScreen()),
      ),
      _SectionItem(
        icon: Icons.inventory_2_rounded,
        label: "inventory_management".tr,
        color: const Color(0xFFEC4899),
        onTap: () => Get.to(() => const InventoryManagementPage()),
      ),
      _SectionItem(
        icon: Icons.tune_rounded,
        label: "printer_management".tr,
        color: const Color(0xFF0EA5E9),
        onTap: () => Get.to(() => const PrinterManagementScreen()),
      ),
      _SectionItem(
        icon: Icons.restaurant_rounded,
        label: "preparation_area_management".tr,
        color: const Color(0xFFF59E0B),
        onTap: () => Get.to(() => const PreparationAreaManagementScreen()),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: sections.length,
      itemBuilder: (_, i) => _SectionCard(item: sections[i]),
    );
  }
}

class _SectionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SectionItem({required this.icon, required this.label, required this.color, required this.onTap});
}

class _SectionCard extends StatelessWidget {
  final _SectionItem item;
  const _SectionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text("Ochish", style: TextStyle(fontSize: 11, color: item.color, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 11, color: item.color),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  PRINTER SOZLAMALARI KARTASI
// ══════════════════════════════════════════════════════════════════════════════
class _PrinterSettingsCard extends StatelessWidget {
  final POSController pos;
  final GetStorage storage;
  final BuildContext context;
  const _PrinterSettingsCard({required this.pos, required this.storage, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final bool wide = MediaQuery.of(ctx).size.width >= 700;

    final List<Widget> toggleItems = [
      Obx(() => _ToggleTile(
        icon: Icons.print_rounded,
        label: "auto_print_receipt".tr,
        color: const Color(0xFF0EA5E9),
        value: pos.autoPrintReceipt.value,
        onChanged: (v) {
          pos.autoPrintReceipt.value = v;
          storage.write('auto_print_receipt', v);
        },
      )),
      Obx(() => _ToggleTile(
        icon: Icons.handshake_rounded,
        label: "enable_kitchen_print".tr,
        color: const Color(0xFFF59E0B),
        value: pos.enableKitchenPrint.value,
        onChanged: (v) => pos.setEnableKitchenPrint(v),
      )),
      Obx(() => _ToggleTile(
        icon: Icons.description_rounded,
        label: "enable_bill_print".tr,
        color: const Color(0xFF10B981),
        value: pos.enableBillPrint.value,
        onChanged: (v) => pos.setEnableBillPrint(v),
      )),
      Obx(() => _ToggleTile(
        icon: Icons.payments_rounded,
        label: "enable_payment_print".tr,
        color: const Color(0xFF6366F1),
        value: pos.enablePaymentPrint.value,
        onChanged: (v) => pos.setEnablePaymentPrint(v),
      )),
      Obx(() => _ToggleTile(
        icon: Icons.stars_rounded,
        label: "Asosiy printer terminali",
        color: const Color(0xFFFF9500),
        value: pos.isMainPrinterTerminal.value,
        onChanged: (v) => pos.setIsMainPrinterTerminal(v),
      )),
    ];

    // Kog'oz o'lchami tugmasi
    Widget paperSize = Obx(() => _ActionTile(
      icon: Icons.receipt_rounded,
      label: "printer_paper_size".tr,
      value: pos.printerPaperSize.value,
      color: const Color(0xFF0EA5E9),
      onTap: () => _showPaperSizeDialog(ctx, pos),
    ));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(ctx).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          paperSize,
          const _Divider(),
          if (wide)
            // Planshetda 2 ustunli toggle grid
            _ToggleGrid(items: toggleItems)
          else
            ...toggleItems.map((e) => Column(children: [e, const _Divider()])).toList()
              ..last.children.removeLast(),
        ],
      ),
    );
  }

  void _showPaperSizeDialog(BuildContext ctx, POSController pos) {
    Get.defaultDialog(
      title: "printer_paper_size".tr,
      titleStyle: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(ctx).textTheme.displayLarge?.color),
      backgroundColor: Theme.of(ctx).cardColor,
      radius: 24,
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
      content: Obx(() => Column(
        children: ["58mm", "80mm"].map((size) => RadioListTile(
          title: Text(size, style: const TextStyle(fontWeight: FontWeight.w600)),
          value: size,
          groupValue: pos.printerPaperSize.value,
          activeColor: const Color(0xFFFF9500),
          onChanged: (val) {
            pos.printerPaperSize.value = val.toString();
            GetStorage().write('printer_paper_size', val);
            Get.back();
          },
        )).toList(),
      )),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  RESTORAN MA'LUMOTLARI
// ══════════════════════════════════════════════════════════════════════════════
class _RestaurantInfoCard extends StatelessWidget {
  final POSController pos;
  final BuildContext context;
  final bool tablet;
  const _RestaurantInfoCard({required this.pos, required this.context, required this.tablet});

  @override
  Widget build(BuildContext ctx) {
    final items = [
      Obx(() => _ActionTile(
        icon: Icons.store_rounded,
        label: "restaurant_name".tr,
        value: pos.restaurantName.value,
        color: const Color(0xFF6366F1),
        onTap: () => _showEdit(ctx, "restaurant_name".tr, pos.restaurantName, 'restaurant_name',
            onSave: (v) => pos.updateCafeInfo(name: v)),
      )),
      Obx(() => _ActionTile(
        icon: Icons.location_on_rounded,
        label: "restaurant_address".tr,
        value: pos.restaurantAddress.value,
        color: const Color(0xFF10B981),
        onTap: () => _showEdit(ctx, "restaurant_address".tr, pos.restaurantAddress, 'restaurant_address',
            onSave: (v) => pos.updateCafeInfo(address: v)),
      )),
      Obx(() => _ActionTile(
        icon: Icons.call_rounded,
        label: "restaurant_phone".tr,
        value: pos.restaurantPhone.value,
        color: const Color(0xFF0EA5E9),
        onTap: () => _showEdit(ctx, "restaurant_phone".tr, pos.restaurantPhone, 'restaurant_phone',
            onSave: (v) => pos.updateCafeInfo(phone: v)),
      )),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(ctx).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: tablet
          ? Row(
              children: items
                  .map((e) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: items.indexOf(e) < items.length - 1 ? 12 : 0),
                          child: e,
                        ),
                      ))
                  .toList(),
            )
          : Column(
              children: List.generate(items.length, (i) {
                if (i == items.length - 1) return items[i];
                return Column(children: [items[i], const _Divider()]);
              }),
            ),
    );
  }

  void _showEdit(BuildContext ctx, String title, RxString obs, String key, {Function(String)? onSave}) {
    final ctrl = TextEditingController(text: obs.value);
    Get.defaultDialog(
      title: title,
      titleStyle: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(ctx).textTheme.displayLarge?.color),
      backgroundColor: Theme.of(ctx).cardColor,
      radius: 24,
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            filled: true, fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            hintText: title,
          ),
        ),
      ),
      confirm: ElevatedButton(
        onPressed: () {
          if (onSave != null) onSave(ctrl.text);
          else { obs.value = ctrl.text; if (key.isNotEmpty) GetStorage().write(key, ctrl.text); }
          Get.back();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF9500), foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text("save".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TIZIM SOZLAMALARI KARTASI
// ══════════════════════════════════════════════════════════════════════════════
class _SystemSettingsCard extends StatelessWidget {
  final POSController pos;
  final GetStorage storage;
  final BuildContext context;
  const _SystemSettingsCard({required this.pos, required this.storage, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final bool wide = MediaQuery.of(ctx).size.width >= 700;

    final toggles = [
      Obx(() => _ToggleTile(
        icon: Icons.dark_mode_rounded,
        label: "Tungi rejim",
        color: const Color(0xFF6366F1),
        value: pos.isDarkMode.value,
        onChanged: (_) => pos.toggleTheme(),
      )),
      Obx(() => _ToggleTile(
        icon: Icons.fullscreen_rounded,
        label: "To'liq ekran",
        color: const Color(0xFF0EA5E9),
        value: pos.isFullScreen.value,
        onChanged: (_) => pos.toggleFullScreen(),
      )),
      Obx(() => _ToggleTile(
        icon: Icons.power_settings_new_rounded,
        label: "Avto-yuklash",
        color: const Color(0xFF10B981),
        value: pos.isAutoStart.value,
        onChanged: (_) => pos.toggleAutoStart(),
      )),
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
        Obx(() => _ToggleTile(
          icon: Icons.auto_awesome_rounded,
          label: "Mijoz ekrani avto-ochish",
          color: const Color(0xFFEC4899),
          value: pos.autoOpenCustomerDisplay.value,
          onChanged: (v) {
            pos.autoOpenCustomerDisplay.value = v;
            GetStorage().write('auto_open_customer_display', v);
          },
        )),
    ];

    final actions = [
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
        _ActionTile(
          icon: Icons.monitor_rounded,
          label: "Mijoz ekranini ochish",
          color: const Color(0xFFEC4899),
          onTap: () => pos.openCustomerDisplay(),
        ),
      _ActionTile(
        icon: Icons.language_rounded,
        label: "language".tr,
        color: const Color(0xFF0EA5E9),
        value: Get.locale?.languageCode == 'uz'
            ? "O'zbekcha"
            : (Get.locale?.languageCode == 'ru' ? "Русский" : "English"),
        onTap: () => _showLanguageSwitcher(ctx),
      ),
      _ActionTile(
        icon: Icons.info_rounded,
        label: "app_version".tr,
        color: const Color(0xFF9CA3AF),
        value: "v1.0.5",
        onTap: () {},
      ),
      if (pos.isAdmin)
        _ActionTile(
          icon: Icons.delete_forever_rounded,
          label: "clear_data".tr,
          color: Colors.redAccent,
          isDestructive: true,
          onTap: () => _confirmClearData(ctx, pos, storage),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(ctx).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          if (wide)
            _ToggleGrid(items: toggles)
          else
            ...List.generate(toggles.length, (i) {
              if (i == toggles.length - 1) return toggles[i];
              return Column(children: [toggles[i], const _Divider()]);
            }),
          const _Divider(),
          ...List.generate(actions.length, (i) {
            if (i == actions.length - 1) return actions[i];
            return Column(children: [actions[i], const _Divider()]);
          }),
        ],
      ),
    );
  }

  void _showLanguageSwitcher(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Theme.of(ctx).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Tilni tanlang", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          _langTile("O'zbekcha", 'uz', 'UZ'),
          _langTile("English", 'en', 'US'),
          _langTile("Русский", 'ru', 'RU'),
        ]),
      ),
    );
  }

  Widget _langTile(String label, String code, String country) {
    final bool sel = Get.locale?.languageCode == code;
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: sel ? FontWeight.w800 : FontWeight.w500, color: sel ? const Color(0xFFFF9500) : null)),
      trailing: sel ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF9500)) : null,
      onTap: () { Get.updateLocale(Locale(code, country)); GetStorage().write('lang', '${code}_$country'); Get.back(); },
    );
  }

  void _confirmClearData(BuildContext ctx, POSController pos, GetStorage storage) {
    Get.defaultDialog(
      title: "clear_data_confirm".tr,
      titleStyle: const TextStyle(fontWeight: FontWeight.w900),
      middleText: "clear_data_msg".tr,
      textConfirm: "Yes, Reset",
      textCancel: "cancel".tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      radius: 24,
      onConfirm: () {
        pos.allOrders.clear(); pos.currentOrder.clear(); storage.remove('all_orders');
        Get.back();
        Get.snackbar("Reset", "Application data cleared.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CHIQISH TUGMASI
// ══════════════════════════════════════════════════════════════════════════════
class _LogoutRow extends StatelessWidget {
  final POSController pos;
  const _LogoutRow({required this.pos});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => pos.logout(),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text("logout".tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        style: TextButton.styleFrom(
          foregroundColor: Colors.redAccent,
          backgroundColor: const Color(0xFFFFF1F2),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  REUSABLE KICHIK WIDGETLAR
// ══════════════════════════════════════════════════════════════════════════════

/// Toggle uchun tile
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.icon, required this.label, required this.color, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFF9500),
            activeTrackColor: const Color(0xFFFF9500).withOpacity(0.2),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

/// Action (chevron) uchun tile
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? value;
  final bool isDestructive;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.color, this.value, this.isDestructive = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red.withOpacity(0.08) : color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isDestructive ? Colors.redAccent : color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? Colors.redAccent : Theme.of(context).textTheme.bodyLarge?.color,
                  )),
            ),
            if (value != null) ...[
              Text(value!, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
            ],
            Icon(
              isDestructive ? Icons.warning_amber_rounded : Icons.chevron_right_rounded,
              size: 18,
              color: isDestructive ? Colors.redAccent : const Color(0xFFD1D5DB),
            ),
          ],
        ),
      ),
    );
  }
}

/// Toggle larni 2 ustunli grid qilish
class _ToggleGrid extends StatelessWidget {
  final List<Widget> items;
  const _ToggleGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : const SizedBox();
      rows.add(Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      ));
      if (i + 2 < items.length) rows.add(const _Divider());
    }
    return Column(children: rows);
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.15));
  }
}
