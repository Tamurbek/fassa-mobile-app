import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:vibration/vibration.dart';
import '../../logic/pos_controller.dart';
import '../../theme/app_colors.dart';

class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  bool _isOnline(dynamic waiter) {
    if (waiter['last_location_update'] == null) return false;
    try {
      final DateTime lastUpdate = DateTime.parse(waiter['last_location_update']);
      final difference = DateTime.now().difference(lastUpdate);
      return difference.inMinutes < 5; // Consider online if updated in last 5 minutes
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

  void _showNfcRegisterDialog(POSController pos, dynamic waiter) async {
    bool isNfcAvailable = await NfcManager.instance.isAvailable();
    if (!isNfcAvailable) {
      Get.snackbar("Xato", "Ushbu qurilmada NFC mavjud emas", 
        backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    String? scannedId;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          if (scannedId == null) {
            NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
              if (await Vibration.hasVibrator() ?? false) {
                Vibration.vibrate(duration: 100);
              }
              
              String? nfcId;
              if (tag.data.containsKey('nfca')) {
                nfcId = (tag.data['nfca']['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
              } else if (tag.data.containsKey('mifareclassic')) {
                nfcId = (tag.data['mifareclassic']['identifier'] as List).map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
              }

              if (nfcId != null) {
                setState(() => scannedId = nfcId);
                NfcManager.instance.stopSession();
              }
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(scannedId == null ? "Karta qo'shish" : "Karta aniqlandi"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (scannedId == null) ...[
                  const Icon(Icons.nfc_rounded, size: 80, color: Colors.blue),
                  const SizedBox(height: 20),
                  const Text("NFC kartani qurilmaga yaqinlashtiring", 
                    textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500)),
                ] else ...[
                  const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
                  const SizedBox(height: 20),
                  Text("ID: $scannedId", style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("${waiter['name']}ga ushbu kartani biriktirilsinmi?", textAlign: TextAlign.center),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  NfcManager.instance.stopSession();
                  Get.back();
                }, 
                child: const Text("Bekor qilish")
              ),
              if (scannedId != null)
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await pos.api.updateNfcCard(waiter['id'].toString(), scannedId!);
                      Get.back();
                      Get.snackbar("Muvaffaqiyatli", "NFC karta saqlandi", 
                        backgroundColor: Colors.green, colorText: Colors.white);
                      pos.refreshData();
                    } catch (e) {
                      Get.snackbar("Xato", "Saqlashda xatolik: $e", 
                        backgroundColor: Colors.red, colorText: Colors.white);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text("Saqlash"),
                ),
            ],
          );
        }
      ),
      barrierDismissible: false,
    ).then((_) => NfcManager.instance.stopSession());
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                      Text(waiter['name'] ?? "Noma'lum", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        tooltip: "NFC karta biriktirish",
                        onPressed: () => _showNfcRegisterDialog(pos, waiter),
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
