import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/api_service.dart';
import '../../../logic/pos_controller.dart';
import '../../../theme/app_colors.dart';
import '../main_navigation_screen.dart';
import 'pin_code_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Save user to controller
      Get.find<POSController>().setCurrentUser(response['user']);
      
      try {
        final subStatus = await ApiService().getSubscriptionStatus();
        if (subStatus['is_expired'] == true) {
          Get.snackbar(
            'Obuna muddati tugagan',
            'Sizning obuna muddatingiz tugagan. Iltimos, administrator bilan bog\'laning.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
          Get.find<POSController>().logout();
          return;
        }
      } catch (e) {
        print("Subscription check error on login: $e");
      }

      Get.snackbar(
        'Success',
        'Welcome back, ${response['user']['name']}!',
        backgroundColor: Colors.green.withOpacity(0.7),
        colorText: Colors.white,
      );

      // Redirect based on PIN setup
      final pos = Get.find<POSController>();
      if (pos.pinCode.value == null) {
        Get.offAll(() => const PinCodeScreen(isSettingNewPin: true));
      } else {
        Get.offAll(() => const PinCodeScreen());
      }
    } catch (e) {
      Get.snackbar(
        'Login Failed',
        'Invalid email or password',
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Row(
        children: [
          // Left side - Branding/Illustration (Visible on large screens)
          if (size.width > 800)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.restaurant_menu_rounded,
                        size: 150,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Fast Food Pro',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'The most powerful POS for your business',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Right side - Login Form
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Login',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back! Please enter your details.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Email Field
                  const Text(
                    'Email Address',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Password Field
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Demo mode or Reset password
                      },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
