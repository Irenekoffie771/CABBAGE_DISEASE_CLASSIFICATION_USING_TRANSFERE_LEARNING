import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_provider.dart';
import 'help_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
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
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                provider.tr('Settings').toUpperCase(),
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
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Theme.of(context).brightness == Brightness.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => provider.toggleTheme(Theme.of(context).brightness == Brightness.light),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('APPEARANCE & LANGUAGE', colorScheme),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    ListTile(
                      leading: Icon(
                        provider.themeMode == ThemeMode.dark 
                            ? Icons.dark_mode_rounded 
                            : Icons.light_mode_rounded, 
                        color: colorScheme.primary
                      ),
                      title: Text(
                        provider.tr('Dark Mode'), 
                        style: TextStyle(
                          color: colorScheme.onSurface, 
                          fontSize: 15, 
                          fontWeight: FontWeight.w700
                        )
                      ),
                      subtitle: Text(
                        provider.themeMode == ThemeMode.dark ? 'Enabled' : 'Disabled',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.4), 
                          fontSize: 12, 
                          fontWeight: FontWeight.w500
                        ),
                      ),
                      trailing: Switch(
                        activeColor: colorScheme.primary,
                        value: provider.themeMode == ThemeMode.dark,
                        onChanged: (val) => provider.toggleTheme(val),
                      ),
                    ),
                    _buildSettingsTile(
                      Icons.translate_rounded,
                      provider.tr('Language'), 
                      provider.language, 
                      colorScheme, 
                      () => _showLanguageDialog(context, provider)
                    ),
                  ], theme, colorScheme),
                  
                  const SizedBox(height: 40),
                  _buildSectionLabel('NOTIFICATIONS', colorScheme),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    ListTile(
                      leading: Icon(Icons.notifications_active_rounded, color: colorScheme.primary),
                      title: Text(
                        provider.tr('Field Reminders'), 
                        style: TextStyle(
                          color: colorScheme.onSurface, 
                          fontSize: 15, 
                          fontWeight: FontWeight.w700
                        )
                      ),
                      subtitle: Text(
                        'Important farm alerts',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.4), 
                          fontSize: 12, 
                          fontWeight: FontWeight.w500
                        ),
                      ),
                      trailing: Switch(
                        activeColor: colorScheme.primary,
                        value: provider.notificationsEnabled,
                        onChanged: (val) => provider.toggleNotifications(val),
                      ),
                    ),
                  ], theme, colorScheme),

                  const SizedBox(height: 40),
                  _buildSectionLabel('SUPPORT', colorScheme),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSettingsTile(Icons.help_center_rounded, 'Help', 'Step-by-step instructions', colorScheme, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()))),
                    _buildSettingsTile(Icons.support_agent_rounded, 'Help Center', 'Agricultural support', colorScheme, () => _showSupportDialog(context, colorScheme)),
                    _buildSettingsTile(Icons.privacy_tip_rounded, 'Privacy Policy', 'Data protection', colorScheme, () => _showPrivacyPolicy(context, colorScheme)),
                  ], theme, colorScheme),
                  
                  const SizedBox(height: 100),
                  Center(
                    child: Column(
                      children: [
                        Text('CABBAGE DOCTOR AI', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
                        const SizedBox(height: 4),
                        Text('v1.0.1 Stable Release', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 10, fontWeight: FontWeight.w600)),
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

  Widget _buildSectionLabel(String text, ColorScheme colorScheme) {
    return Text(text, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }

  Widget _buildSettingsCard(List<Widget> children, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String sub, ColorScheme colorScheme, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: colorScheme.primary, size: 22),
      title: Text(title, style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
      subtitle: Text(sub, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withValues(alpha: 0.2), size: 20),
    );
  }

  void _showLanguageDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(provider.tr('Select Language'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langItem(context, provider, 'English'),
            _langItem(context, provider, 'Twi'),
          ],
        ),
      ),
    );
  }

  Widget _langItem(BuildContext context, AppProvider provider, String lang) {
    final isSelected = provider.language == lang;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () { provider.setLanguage(lang); Navigator.pop(context); },
      title: Text(lang, style: TextStyle(color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 16, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 24) : null,
    );
  }

  void _showSupportDialog(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Support', style: TextStyle(color: colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _supportItem(Icons.email_rounded, 'Email Us', 'project0z1258@gmail.com', colorScheme, () => _launch('mailto:project0z1258@gmail.com')),
            _supportItem(Icons.chat_bubble_rounded, 'WhatsApp Support', '0559650921', colorScheme, () => _launch('https://wa.me/233559650921')),
          ],
        ),
      ),
    );
  }

  Widget _supportItem(IconData icon, String title, String sub, ColorScheme colorScheme, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: colorScheme.primary, size: 24),
      title: Text(title, style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
      subtitle: Text(sub, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  void _showPrivacyPolicy(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Privacy Policy', style: TextStyle(color: colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Text(
          'Your farming data is processed with extreme care. Cloud synchronization is only enabled for authenticated pro-accounts.',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Understood', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)))],
      ),
    );
  }

  void _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
