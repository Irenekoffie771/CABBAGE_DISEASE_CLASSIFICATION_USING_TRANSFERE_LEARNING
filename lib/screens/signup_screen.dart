import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_provider.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedRegion;
  String? _selectedGender;
  String? _selectedProfession;
  double _passwordStrength = 0;
  bool _showStrength = false;
  bool _isLoading = false;

  final List<String> _professions = [
    'Crop Farmer', 'Commercial Farmer', 'Backyard Gardener',
    'Agricultural Student', 'Extension Officer', 'Researcher', 'Other'
  ];

  final Map<String, List<double>> _regions = {
    'Ahafo': [6.8043, -2.5186], 'Ashanti': [6.6666, -1.6163], 'Bono East': [7.5833, -1.9333],
    'Brong Ahafo': [7.3349, -2.3123], 'Central': [5.1053, -1.2466], 'Eastern': [6.0784, -0.2713],
    'Greater Accra': [5.6037, -0.1870], 'North East': [10.5306, -0.3686], 'Northern': [9.4034, -0.8424],
    'Oti': [8.0700, 0.1800], 'Savannah': [9.0833, -1.8167], 'Upper East': [10.7856, -0.8514],
    'Upper West': [10.0601, -2.5019], 'Volta': [6.6101, 0.4785], 'Western': [4.8951, -1.7554],
    'Western North': [6.1248, -2.4838],
  };

  @override
  void dispose() {
    for (var c in [_firstNameController, _surnameController, _emailController, _phoneController, _dobController, _passwordController, _confirmPasswordController]) {
      c.dispose();
    }
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    setState(() => _showStrength = password.isNotEmpty);
    double strength = 0;
    if (password.length >= 6) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;
    setState(() => _passwordStrength = strength);
  }

  Color _getStrengthColor() {
    if (_passwordStrength <= 0.25) return Colors.redAccent;
    if (_passwordStrength <= 0.5) return Colors.orangeAccent;
    if (_passwordStrength <= 0.75) return Colors.yellowAccent;
    return const Color(0xFF4CAF50);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2E7D32), onPrimary: Colors.white, surface: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dobController.text = DateFormat('MMM dd, yyyy').format(picked));
    }
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final provider = Provider.of<AppProvider>(context, listen: false);
        final navigator = Navigator.of(context);
        
        await provider.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          firstName: _firstNameController.text.trim(),
          surname: _surnameController.text.trim(),
          dob: _dobController.text,
          gender: _selectedGender!,
          profession: _selectedProfession!,
          region: _selectedRegion!,
          phone: _phoneController.text.trim(),
        );

        if (!mounted) return;

        navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Registration'.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.primary, fontSize: 10, letterSpacing: 3),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)],
                    ).createShader(bounds),
                    child: const Text(
                      'Join the Network', 
                      style: TextStyle(
                        fontSize: 36, 
                        fontWeight: FontWeight.w800, 
                        color: Colors.white, 
                        letterSpacing: -1.5,
                        height: 1.1,
                      )
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your farmer profile to get started.', 
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.4), 
                      fontSize: 16, 
                      fontWeight: FontWeight.w500,
                    )
                  ),
                  const SizedBox(height: 40),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('BASIC INFORMATION', Icons.person_rounded),
                        _buildCard([
                          Row(
                            children: [
                              Expanded(
                                child: _buildField(
                                  _firstNameController, 
                                  'First Name', 
                                  'John',
                                  Icons.person_outline, 
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))],
                                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildField(
                                  _surnameController, 
                                  'Surname', 
                                  'Doe',
                                  Icons.badge_outlined, 
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))],
                                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildField(
                            _dobController, 
                            'Date of Birth', 
                            'Select date',
                            Icons.calendar_today_rounded, 
                            readOnly: true, 
                            onTap: () => _selectDate(context),
                            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null
                          ),
                          const SizedBox(height: 20),
                          _buildDropdown('Gender', 'Select gender', Icons.wc_rounded, ['Male', 'Female', 'Other'], _selectedGender, (v) => setState(() => _selectedGender = v), validator: (v) => v == null ? 'Required' : null),
                        ]),
                        
                        const SizedBox(height: 32),
                        _buildSectionHeader('FARMING PROFILE', Icons.agriculture_rounded),
                        _buildCard([
                          _buildDropdown('Profession', 'Select profession', Icons.work_outline, _professions, _selectedProfession, (v) => setState(() => _selectedProfession = v), validator: (v) => v == null ? 'Required' : null),
                          const SizedBox(height: 20),
                          _buildDropdown('Farm Region', 'Select region', Icons.map_outlined, _regions.keys.toList(), _selectedRegion, (v) {
                            setState(() => _selectedRegion = v);
                            if (v != null) provider.setLocation(_regions[v]![0], _regions[v]![1], v);
                          }, validator: (v) => v == null ? 'Required' : null),
                        ]),

                        const SizedBox(height: 32),
                        _buildSectionHeader('CONTACT & SECURITY', Icons.security_rounded),
                        _buildCard([
                          _buildField(
                            _phoneController, 
                            'Phone Number', 
                            '024XXXXXXX',
                            Icons.phone_android_rounded, 
                            keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (v.length < 10) return 'Must be 10 digits';
                              return null;
                            }
                          ),
                          const SizedBox(height: 20),
                          _buildField(
                            _emailController, 
                            'Email Address', 
                            'farmer@example.com',
                            Icons.alternate_email_rounded, 
                            keyboardType: TextInputType.emailAddress, 
                            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Invalid email format';
                              return null;
                            }
                          ),
                          const SizedBox(height: 20),
                          _buildField(
                            _passwordController, 
                            'Password', 
                            'Min 6 characters',
                            Icons.lock_outline_rounded, 
                            obscure: _obscurePassword, 
                            suffix: _toggleIcon(() => setState(() => _obscurePassword = !_obscurePassword), _obscurePassword), 
                            onChanged: _checkPasswordStrength,
                            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                            validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null
                          ),
                          
                          if (_showStrength) ...[
                            const SizedBox(height: 8),
                            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: _passwordStrength, backgroundColor: colorScheme.primary.withValues(alpha: 0.1), color: _getStrengthColor(), minHeight: 6)),
                            const SizedBox(height: 4),
                            Text(
                              'Password Strength', 
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _getStrengthColor())
                            ),
                          ],

                          const SizedBox(height: 20),
                          _buildField(
                            _confirmPasswordController, 
                            'Confirm Password', 
                            'Retype password',
                            Icons.lock_reset_rounded, 
                            obscure: _obscureConfirmPassword, 
                            suffix: _toggleIcon(() => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword), _obscureConfirmPassword), 
                            validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                          ),
                        ]),
                        
                        const SizedBox(height: 48),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 64),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 8,
                            shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                          ),
                          child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                            : const Text('Complete Registration', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5)),
                        ),
                        const SizedBox(height: 40),
                      ],
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

  Widget _buildSectionHeader(String text, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 16.0, left: 4), 
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1B5E20).withValues(alpha: 0.4)),
        const SizedBox(width: 8),
        Text(
          text, 
          style: TextStyle(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.4), 
            fontSize: 10, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.5
          )
        ),
      ],
    )
  );

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildField(TextEditingController controller, String label, String hint, IconData icon, {bool readOnly = false, VoidCallback? onTap, bool obscure = false, Widget? suffix, TextInputType? keyboardType, Function(String)? onChanged, String? Function(String?)? validator, List<TextInputFormatter>? inputFormatters}) {
    return TextFormField(
      controller: controller, readOnly: readOnly, onTap: onTap, obscureText: obscure, keyboardType: keyboardType, onChanged: onChanged, validator: validator,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: const Color(0xFF1B5E20).withValues(alpha: 0.5), fontWeight: FontWeight.w700),
        hintText: hint, 
        hintStyle: TextStyle(color: const Color(0xFF2E7D32).withValues(alpha: 0.2)), 
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 20), 
        suffixIcon: suffix,
        filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: const Color(0xFF2E7D32).withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD32F2F))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5)),
      ),
    );
  }

  Widget _buildDropdown(String label, String hint, IconData icon, List<String> items, String? value, Function(String?) onChanged, {String? Function(String?)? validator}) {
    return DropdownButtonFormField<String>(
      value: value, items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w600, fontSize: 14)))).toList(), onChanged: onChanged,
      validator: validator,
      dropdownColor: Colors.white, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2E7D32)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: const Color(0xFF1B5E20).withValues(alpha: 0.5), fontWeight: FontWeight.w700),
        hintText: hint, 
        hintStyle: TextStyle(color: const Color(0xFF2E7D32).withValues(alpha: 0.2)), 
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: const Color(0xFF2E7D32).withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD32F2F))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5)),
      ),
    );
  }

  Widget _toggleIcon(VoidCallback onTap, bool obscure) => IconButton(icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF2E7D32).withValues(alpha: 0.4), size: 20), onPressed: onTap);
}
