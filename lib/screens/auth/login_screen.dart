import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/role_based_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    debugPrint('🔐 Login attempt: ${_emailController.text.trim()}');
    
    try {
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        debugPrint('✅ Login successful - User authenticated');
        
        // Verify the auth state was updated
        await Future.delayed(const Duration(milliseconds: 100));
        final updatedAuthProvider = Provider.of<AuthProvider>(context, listen: false);
        debugPrint(
          '🔍 Login Screen: After login - isAuthenticated=${updatedAuthProvider.isAuthenticated}, '
          'isLoading=${updatedAuthProvider.isLoading}, user=${updatedAuthProvider.currentUser?.name}',
        );
        
        // Force navigation after successful login
        // Since Consumer isn't rebuilding, we'll navigate manually
        if (mounted) {
          // Use a small delay to ensure state is fully updated
          await Future.delayed(const Duration(milliseconds: 200));
          
          if (mounted) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            if (authProvider.isAuthenticated && authProvider.currentUser != null) {
              debugPrint('✅ Navigating to main screen for user: ${authProvider.currentUser!.name}');
              
              // Navigate by replacing the entire app with RoleBasedNavigation
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const RoleBasedNavigation(),
                ),
                (route) => false, // Remove all previous routes
              );
              debugPrint('🚀 Navigation completed');
            } else {
              debugPrint('❌ User is NOT authenticated after delay');
            }
          }
        }
        
        // The AuthWrapper should automatically navigate based on auth state
        // If it doesn't, the Consumer should rebuild when notifyListeners() is called
      } else {
        debugPrint('❌ Login failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Login failed. Please check your email and password, or contact your administrator if your account needs to be created.',
              ),
              backgroundColor: AppTheme.errorColor,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Login error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF002911), // Be Electric dark green
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Be Electric Logo - Much Bigger
                    Center(
                      child: Image.asset(
                        'assets/images/beElectricWhiteLogo.png',
                        width: 250,
                        height: 250,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.bolt,
                            size: 200,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXXL),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.email, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingXL),

                  // Login Button
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) => ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () {
                              debugPrint('🔘 Login button pressed');
                              _login();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF002911),
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF002911),
                                ),
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
