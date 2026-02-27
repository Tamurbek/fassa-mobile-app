import 'package:get_storage/get_storage.dart';
import '../../data/services/api_service.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final GetStorage _storage = GetStorage('offline_queue');
  final ApiService _api = ApiService();

  List<dynamic> get queue => _storage.read<List<dynamic>>('orders_queue') ?? [];

  Future<void> queueOrder(Map<String, dynamic> orderData) async {
    final List<dynamic> currentQueue = queue;
    // Add local timestamp to know when it was created
    orderData['local_timestamp'] = DateTime.now().toIso8601String();
    orderData['offline_sync_status'] = 'pending';
    
    currentQueue.add(orderData);
    await _storage.write('orders_queue', currentQueue);
  }

  Future<void> syncQueue() async {
    final List<dynamic> currentQueue = List.from(queue);
    if (currentQueue.isEmpty) return;

    print("OfflineService: Syncing ${currentQueue.length} orders...");
    
    final List<dynamic> failedOrders = [];
    
    for (var order in currentQueue) {
      try {
        await _api.createOrder(order);
        print("OfflineService: Order synced successfully");
      } catch (e) {
        print("OfflineService: Failed to sync order: $e");
        failedOrders.add(order);
      }
    }

    await _storage.write('orders_queue', failedOrders);
  }

  void clearQueue() {
    _storage.remove('orders_queue');
  }

  int get queueCount => queue.length;
}
