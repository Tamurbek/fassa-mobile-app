import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../logic/pos_controller.dart';
import '../../theme/app_colors.dart';

import 'package:qr_flutter/qr_flutter.dart';

class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final POSController pos = Get.find<POSController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Xodimlar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: waiters.length,
          itemBuilder: (context, index) {
            final waiter = waiters[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
                title: Text(waiter['name'] ?? "Noma'lum", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(waiter['role'] ?? ""),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.qr_code_2_rounded, color: Colors.blue),
                      tooltip: "Tizimga bog'lash",
                      onPressed: () => _showQRDialog(pos, waiter),
                    ),
                    const SizedBox(width: 8),
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
        );
      }),
    );
  }
}
