import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/app_provider.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker();
  
  late TextEditingController _firstNameController;
  late TextEditingController _surnameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  
  String? _selectedRegion;
  String? _selectedProfession;
  String? _selectedGender;
  String? _userEmail;
  bool _isEditing = false;
  bool _isLoading = true;

  final List<String> _professions = [
    'Crop Farmer', 'Commercial Farmer', 'Backyard Gardener',
    'Agricultural Student', 'Extension Officer', 'Researcher', 'Other'
  ];

  final List<String> _regions = [
    'Ahafo', 'Ashanti', 'Bono East', 'Brong Ahafo', 'Central', 'Eastern', 
    'Greater Accra', 'North East', 'Northern', 'Oti', 'Savannah',
    'Upper East', 'Upper West', 'Volta', 'Western', 'Western North'
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _surnameController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _supabaseService.fetchUserProfile();
      _userEmail = _supabaseService.currentUser?.email;
      if (profile != null) {
        if (mounted) {
          final provider = Provider.of<AppProvider>(context, listen: false);
          if (profile['avatar_url'] != null && profile['avatar_url'].toString().isNotEmpty) {
            provider.setAvatarUrl(profile['avatar_url']);
          }
        }
        setState(() {
          _firstNameController.text = profile['first_name'] ?? '';
          _surnameController.text = profile['surname'] ?? '';
          _phoneController.text = profile['phone_number'] ?? '';
          _dobController.text = profile['dob'] ?? '';
          _selectedRegion = _regions.contains(profile['region']) ? profile['region'] : null;
          _selectedProfession = _professions.contains(profile['profession']) ? profile['profession'] : null;
          _selectedGender = profile['gender'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        if (!mounted) return;
        final provider = Provider.of<AppProvider>(context, listen: false);
        await provider.updateAvatar(pickedFile);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated!'), behavior: SnackBarBehavior.floating));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 2))
        : CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, provider, colorScheme, theme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(provider, theme, colorScheme),
                        const SizedBox(height: 48),
                        if (!_isEditing) _buildViewMode(provider, theme, colorScheme)
                        else _buildEditMode(colorScheme),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AppProvider provider, ColorScheme colorScheme, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: colorScheme.primary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Theme.of(context).brightness == Brightness.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => provider.toggleTheme(Theme.of(context).brightness == Brightness.light),
              ),
              IconButton(
                icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_note_rounded, size: 22, color: Colors.white),
                onPressed: () => setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) _loadUserProfile();
                }),
              ),
            ],
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Profile'.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 10, letterSpacing: 3),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colorScheme.primary.withValues(alpha: 0.8), colorScheme.primary],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: CircleAvatar(
                      key: ValueKey(provider.avatarUrl),
                      radius: 56,
                      backgroundColor: theme.cardColor,
                      child: provider.avatarUrl != null 
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: provider.avatarUrl!,
                              width: 112,
                              height: 112,
                              fit: BoxFit.cover,
                              cacheKey: provider.avatarUrl,
                              placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 3, color: Colors.grey),
                              errorWidget: (context, url, error) => Icon(Icons.person_rounded, size: 48, color: colorScheme.primary),
                            ),
                          )
                        : Icon(Icons.person_rounded, size: 48, color: colorScheme.primary),
                    ),
                  ),
                  if (_isEditing)
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: colorScheme.secondary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 44),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(AppProvider provider, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        _buildStatCard('TOTAL SCANS', provider.history.length.toString(), theme, colorScheme),
        const SizedBox(width: 12),
        _buildStatCard('FIELD TASKS', provider.schedules.length.toString(), theme, colorScheme),
        const SizedBox(width: 12),
        _buildStatCard('ACCOUNT', provider.isGuest ? 'FREE' : 'PRO', theme, colorScheme),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, ThemeData theme, ColorScheme colorScheme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildViewMode(AppProvider provider, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('PERSONAL INFORMATION', colorScheme),
        const SizedBox(height: 12),
        _buildInfoCard([
          _buildInfoRow('Email Address', _userEmail ?? 'Not Set', colorScheme),
          _buildInfoRow('Phone Number', _phoneController.text, colorScheme),
          _buildInfoRow('Farm Region', _selectedRegion ?? 'Not Set', colorScheme),
        ], theme, colorScheme),
        const SizedBox(height: 32),
        _buildSectionHeader('FARMING PROFILE', colorScheme),
        const SizedBox(height: 12),
        _buildInfoCard([
          _buildInfoRow('Profession', _selectedProfession ?? 'Not Set', colorScheme),
          _buildInfoRow('Birth Date', _dobController.text, colorScheme),
          _buildInfoRow('Gender', _selectedGender ?? 'Not Set', colorScheme),
        ], theme, colorScheme),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () { provider.signOut(); Navigator.pop(context); },
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F), size: 18),
            label: const Text('Sign out', style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w700)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(20),
              backgroundColor: const Color(0xFFD32F2F).withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Text(title, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }

  Widget _buildInfoCard(List<Widget> children, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w600)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not Provided' : value, 
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('First Name', colorScheme),
        _buildTextField(_firstNameController, colorScheme),
        const SizedBox(height: 24),
        _buildLabel('Surname', colorScheme),
        _buildTextField(_surnameController, colorScheme),
        const SizedBox(height: 24),
        _buildLabel('Phone Number', colorScheme),
        _buildTextField(_phoneController, colorScheme, keyboardType: TextInputType.phone),
        const SizedBox(height: 24),
        _buildLabel('Region', colorScheme),
        _buildDropdown(_regions, _selectedRegion, colorScheme, (v) => setState(() => _selectedRegion = v)),
        const SizedBox(height: 24),
        _buildLabel('Profession', colorScheme),
        _buildDropdownList(_professions, _selectedProfession, colorScheme, (v) => setState(() => _selectedProfession = v)),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: colorScheme.primary.withValues(alpha: 0.3),
          ),
          child: const Text('Save changes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, ColorScheme colorScheme) => Padding(padding: const EdgeInsets.only(bottom: 12.0, left: 4), child: Text(text, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)));

  Widget _buildTextField(TextEditingController controller, ColorScheme colorScheme, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        filled: true, fillColor: colorScheme.primary.withValues(alpha: 0.05), contentPadding: const EdgeInsets.all(20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String? value, ColorScheme colorScheme, Function(String?) onChanged) {
     return DropdownButtonFormField<String>(
      initialValue: value, items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600)))).toList(), onChanged: onChanged,
      dropdownColor: Theme.of(context).cardColor, icon: Icon(Icons.arrow_drop_down_rounded, color: colorScheme.primary),
      decoration: InputDecoration(
        filled: true, fillColor: colorScheme.primary.withValues(alpha: 0.05), contentPadding: const EdgeInsets.all(20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
      ),
    );
  }

  Widget _buildDropdownList(List<String> items, String? value, ColorScheme colorScheme, Function(String?) onChanged) => _buildDropdown(items, value, colorScheme, onChanged);

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _supabaseService.updateUserProfile(
          firstName: _firstNameController.text.trim(),
          surname: _surnameController.text.trim(),
          profession: _selectedProfession ?? '',
          region: _selectedRegion ?? '',
          phone: _phoneController.text.trim(),
          dob: _dobController.text,
          gender: _selectedGender ?? '',
        );
        if (!mounted) return;
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.setUserName('${_firstNameController.text} ${_surnameController.text}');
        setState(() { _isEditing = false; _isLoading = false; });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!'), behavior: SnackBarBehavior.floating));
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
