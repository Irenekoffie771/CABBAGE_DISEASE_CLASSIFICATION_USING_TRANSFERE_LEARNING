import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/app_provider.dart';
import '../services/supabase_service.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      
      try {
        final provider = Provider.of<AppProvider>(context, listen: false);

        final response = await provider.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (!mounted) return;

        if (response.user != null) {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(e is AuthException ? e.message : 'Login failed'),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
          backgroundColor: Color(0xFFFBC02D),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Reset Password?', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
        content: Text('We will send a reset link to $email.', style: const TextStyle(color: Colors.black54)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              
              navigator.pop();
              setState(() => _isLoading = true);
              try {
                await SupabaseService().resetPassword(email);
                if (!mounted) return;
                _showSuccessDialog(email);
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Send Link', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF2E7D32), size: 48),
        title: const Text('Email Sent', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
        content: Text('Check $email for reset instructions.', style: const TextStyle(color: Colors.black54)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Hero(
                        tag: 'app_logo',
                        child: Container(
                          width: 100,
                          height: 100,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/c10.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)],
                      ).createShader(bounds),
                      child: const Text(
                        'Cabbage Doctor',
                        style: TextStyle(
                          fontSize: 42, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.white, 
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your personal agricultural AI assistant.',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.4), 
                        fontSize: 16, 
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 48),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(
                            controller: _emailController,
                            label: 'EMAIL ADDRESS',
                            hint: 'farmer@example.com',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email is required';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Invalid email format';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'PASSWORD',
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscurePassword,
                            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                          ),
                          
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleForgotPassword,
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.secondary.withValues(alpha: 0.8),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text('Forgot password?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ),
                          
                          const SizedBox(height: 32),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 8,
                              shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                            ),
                            child: _isLoading 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Sign In to Farm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.black.withValues(alpha: 0.05))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR', style: TextStyle(color: Colors.black.withValues(alpha: 0.2), fontSize: 12, fontWeight: FontWeight.w800)),
                              ),
                              Expanded(child: Divider(color: Colors.black.withValues(alpha: 0.05))),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          OutlinedButton.icon(
                            onPressed: () {
                              provider.setGuestUser();
                              if (!mounted) return;
                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
                            },
                            icon: Icon(Icons.person_search_rounded, size: 20, color: colorScheme.primary),
                            label: const Text('Continue as Guest'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),
                    Center(
                      child: Column(
                        children: [
                          Text("New to the field?", style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                            child: Text(
                              'Create Farmer Account', 
                              style: TextStyle(
                                color: colorScheme.primary, 
                                fontWeight: FontWeight.w800, 
                                fontSize: 15,
                                decoration: TextDecoration.underline,
                                decorationColor: colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4),
          child: Text(
            label,
            style: TextStyle(color: const Color(0xFF1B5E20).withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF2E7D32), size: 20) : null,
            filled: true,
            fillColor: const Color(0xFFF1F8E9).withValues(alpha: 0.5),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: const Color(0xFF2E7D32).withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
