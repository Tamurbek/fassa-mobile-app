import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../logic/pos_controller.dart';
import '../../theme/app_colors.dart';

class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

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
        final waiters = pos.users.where((u) => u['role'] == "WAITER").toList();
        
        if (waiters.isEmpty) {
          return const Center(child: Text("Ofitsiantlar topilmadi"));
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
                trailing: ElevatedButton.icon(
                  onPressed: () => pos.callWaiter(waiter),
                  icon: const Icon(Icons.notifications_active_rounded, size: 18),
                  label: const Text("Chaqirish"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
