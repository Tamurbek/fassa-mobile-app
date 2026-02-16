import 'package:dio/dio.dart';

class ApiService {
  static final String baseUrl = 'https://cafe-backend-code-production.up.railway.app'; 
  
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  String? _token;

  ApiService._internal() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
    ));
  }

  void setToken(String? token) => _token = token;

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      _token = response.data['access_token'];
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auth/register', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Categories
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Products
  Future<List<dynamic>> getProducts() async {
    try {
      final response = await _dio.get('/products');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Orders
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _dio.post('/orders', data: orderData);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getOrders() async {
    try {
      final response = await _dio.get('/orders');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      final backendStatus = status.toUpperCase().replaceAll(" ", "_");
      await _dio.patch('/orders/$orderId/status', data: {'status': backendStatus});
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadImage(String filePath) async {
    try {
      String fileName = filePath.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post('/uploads/', data: formData);
      return response.data['url'];
    } catch (e) {
      rethrow;
    }
  }

  // Preparation Areas
  Future<List<dynamic>> getPreparationAreas() async {
    try {
      final response = await _dio.get('/preparation-areas');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Printers
  Future<List<dynamic>> getPrinters() async {
    try {
      final response = await _dio.get('/printers');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLatestVersion() async {
    try {
      final response = await _dio.get('/system/version');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
