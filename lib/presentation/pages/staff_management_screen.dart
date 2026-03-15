import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';
import '../../logic/pos_controller.dart';
import '../../theme/app_colors.dart';

class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  bool _isOnline(dynamic waiter) {
    if (waiter['last_location_update'] == null) return false;
    try {
      final DateTime lastUpdate = DateTime.parse(waiter['last_location_update']);
      final difference = DateTime.now().difference(lastUpdate);
      return difference.inMinutes < 5; 
    } catch (e) {
      return false;
    }
  }

  void _showQRDialog(POSController pos, dynamic waiter) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    final qrToken = await pos.getStaffQRToken(waiter['id'].toString());
    Get.back();

    if (qrToken == null) {
      Get.snackbar("Xato", "QR kod olish imkoni bo'lmadi", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Text(waiter['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            const Text("Tizimga bog'lash", style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Afitsant ushbu kodni o'z telefonida skaner qilishi kerak", 
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              height: 250,
              child: QrImageView(
                data: qrToken,
                version: QrVersions.auto,
                size: 250.0,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Yopish")),
        ],
      ),
    );
  }

  void _showCardRegisterDialog(POSController pos, dynamic waiter) {
    final TextEditingController cardIdController = TextEditingController();
    final FocusNode focusNode = FocusNode();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("${waiter['name']}ga karta biriktirish"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.credit_card_rounded, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              "Karta ID-sini kiriting yoki o'quvchi orqali o'tkazing",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: cardIdController,
              focusNode: focusNode,
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Karta ID",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.pin),
              ),
              onSubmitted: (val) {
                if (val.isNotEmpty) {
                  _saveCard(pos, waiter, val);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Bekor qilish")),
          ElevatedButton(
            onPressed: () => _saveCard(pos, waiter, cardIdController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Saqlash"),
          ),
        ],
      ),
    );

    // Ensure focus for HID reader
    Future.delayed(const Duration(milliseconds: 100), () => focusNode.requestFocus());
  }

  void _saveCard(POSController pos, dynamic waiter, String cardId) async {
    if (cardId.isEmpty) {
      Get.snackbar("Xato", "Karta ID-si bo'sh bo'lishi mumkin emas", 
        backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      await pos.api.updateNfcCard(waiter['id'].toString(), cardId);
      Get.back(); // close loading
      Get.back(); // close dialog
      
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 100);
      }

      Get.snackbar("Muvaffaqiyatli", "Karta muvaffaqiyatli saqlandi", 
        backgroundColor: Colors.green, colorText: Colors.white);
      pos.refreshData();
    } catch (e) {
      Get.back(); // close loading
      Get.snackbar("Xato", "Xatolik yuz berdi: $e", 
        backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final POSController pos = Get.find<POSController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Xodimlar", style: TextStyle(color: Theme.of(context).textTheme.displayLarge?.color, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => Get.find<POSController>().refreshData(),
          ),
        ],
      ),
      body: Obx(() {
        final waiters = pos.users.where((u) {
          final role = u['role']?.toString().toUpperCase();
          return role == "WAITER";
        }).toList();
        
        if (waiters.isEmpty) {
          if (pos.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text("Sizning kafengizda hali ofitsiantlar mavjud emas.", style: TextStyle(color: Colors.grey)),
                TextButton(onPressed: () => pos.refreshData(), child: const Text("Yangilash")),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => pos.refreshData(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: waiters.length,
            itemBuilder: (context, index) {
              final waiter = waiters[index];
              final bool online = _isOnline(waiter);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Stack(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(Icons.person, color: AppColors.primary),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: online ? Colors.green : Colors.grey.shade400,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Text(waiter['name'] ?? "Noma'lum", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      const SizedBox(width: 8),
                      Text(
                        online ? "(Online)" : (waiter['last_location_update'] != null 
                          ? "Oxirgi faollik: ${DateFormat('HH:mm').format(DateTime.parse(waiter['last_location_update']).toLocal())}" 
                          : "(Oflayn)"), 
                        style: TextStyle(
                          fontSize: 11, 
                          color: online ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(waiter['role'] ?? ""),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.qr_code_2_rounded, color: Colors.blue),
                        tooltip: "QR kod orqali bog'lash",
                        onPressed: () => _showQRDialog(pos, waiter),
                      ),
                      IconButton(
                        icon: const Icon(Icons.credit_card_rounded, color: Colors.orange),
                        tooltip: "Karta biriktirish",
                        onPressed: () => _showCardRegisterDialog(pos, waiter),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        onPressed: () => pos.callWaiter(waiter),
                        icon: const Icon(Icons.notifications_active_rounded, size: 18),
                        label: const Text("Chaqirish"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
