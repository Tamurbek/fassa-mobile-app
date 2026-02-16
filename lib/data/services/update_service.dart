import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../../theme/app_colors.dart';

class UpdateService {
  final ApiService _api = ApiService();

  Future<void> checkForUpdate() async {
    try {
      final updateInfo = await _api.getLatestVersion();
      final packageInfo = await PackageInfo.fromPlatform();
      
      final currentVersion = packageInfo.version;
      final currentBuild = int.parse(packageInfo.buildNumber);
      
      final latestVersion = updateInfo['latest_version'];
      final latestBuild = updateInfo['build_number'];
      
      if (latestBuild > currentBuild) {
        _showUpdateDialog(
          version: latestVersion,
          notes: updateInfo['release_notes'],
          url: updateInfo['url'],
          critical: updateInfo['critical'] ?? false,
        );
      }
    } catch (e) {
      print("Update check failed: $e");
    }
  }

  void _showUpdateDialog({
    required String version,
    required String notes,
    required String url,
    required bool critical,
  }) {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => !critical,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.system_update_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Text("Yangi versiya: v$version"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Yangi imkoniyatlar:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(notes),
              const SizedBox(height: 16),
              if (critical)
                const Text(
                  "Ushbu yangilanish majburiy. Ilovadan foydalanishda davom etish uchun yangilang.",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
            ],
          ),
          actions: [
            if (!critical)
              TextButton(
                onPressed: () => Get.back(),
                child: const Text("Keyinroq", style: TextStyle(color: Colors.grey)),
              ),
            ElevatedButton(
              onPressed: () => _launchURL(url),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Hozir yangilash", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      barrierDismissible: !critical,
    );
  }

  Future<void> _launchURL(String url) async {
    String absoluteUrl = url.startsWith('http') 
        ? url 
        : "${ApiService.baseUrl}$url";
        
    final Uri uri = Uri.parse(absoluteUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Xato", "Yangilanishni yuklab bo'lmadi");
    }
  }
}
