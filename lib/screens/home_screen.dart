import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/app_provider.dart';
import '../models/prediction_model.dart';
import 'result_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'chatbot_screen.dart';
import 'schedule_screen.dart';
import 'weather_screen.dart';
import 'login_screen.dart';
import 'help_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handleScan(BuildContext context, ImageSource source) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show friendly reminder dialog before scanning
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.cardColor,
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              provider.tr('Cabbage Focus'),
              style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurface),
            ),
          ],
        ),
        content: Text(
          provider.tr('To get the most accurate results, please ensure you are scanning a cabbage leaf. Other objects or non-cabbage plants might be misidentified as diseased cabbage.'),
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(provider.tr('CANCEL'), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(provider.tr('PROCEED'), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    if (!context.mounted) return;
    await provider.pickImage(source, context);
    if (context.mounted && provider.currentPrediction != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildRefinedDrawer(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatbotScreen())),
        backgroundColor: colorScheme.secondary,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.forum_rounded),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
                  surfaceTintColor: Colors.transparent,
                  centerTitle: true,
                  title: Column(
                    children: [
                      Text(
                        'Cabbage Doctor'.toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 12,
                        height: 2,
                        decoration: BoxDecoration(
                          color: colorScheme.secondary,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.notes_rounded, color: colorScheme.primary, size: 22),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        theme.brightness == Brightness.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      onPressed: () => provider.toggleTheme(theme.brightness == Brightness.light),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1), width: 1.5),
                          ),
                          child: CircleAvatar(
                            key: ValueKey(provider.avatarUrl),
                            radius: 15,
                            backgroundColor: theme.cardColor,
                            child: provider.avatarUrl != null 
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: provider.avatarUrl!,
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.cover,
                                    cacheKey: provider.avatarUrl, // Use URL as unique key
                                    placeholder: (context, url) => const SizedBox(
                                      width: 15, 
                                      height: 15, 
                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.grey)
                                    ),
                                    errorWidget: (context, url, error) {
                                      debugPrint('Image error: $error');
                                      return Icon(Icons.person_rounded, color: colorScheme.primary, size: 14);
                                    },
                                  ),
                                )
                              : Icon(Icons.person_rounded, color: colorScheme.primary, size: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildWelcomeSection(provider, colorScheme),
                        const SizedBox(height: 32),
                        const LeafSlideshow(),
                        const SizedBox(height: 32),
      
                        _buildSectionHeader('DIAGNOSTICS TOOLS', colorScheme),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildActionCard('Camera', 'Scan Leaf', Icons.camera_rounded, colorScheme.primary, () => _handleScan(context, ImageSource.camera))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildActionCard('Gallery', 'Upload', Icons.image_search_rounded, colorScheme.secondary, () => _handleScan(context, ImageSource.gallery))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            provider.tr('Friendly Tip: For the best results, please take a clear photo of the leaf. Occasionally, other objects might be mistaken for a cabbage leaf.'),
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        _buildSectionHeader('MY FARM DASHBOARD', colorScheme),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeatherScreen())),
                                child: _buildSensorMetric(Icons.wb_sunny_rounded, '${provider.temp.toInt()}°C', 'Weather', theme, colorScheme),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen())),
                                child: _buildSensorMetric(Icons.analytics_rounded, provider.history.length.toString(), 'Field Stats', theme, colorScheme),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildDynamicScheduleCard(context, provider, theme, colorScheme),
                        const SizedBox(height: 32),
      
                        _buildHomepageCharts(provider, theme, colorScheme),
                        const SizedBox(height: 32),
      
                        if (provider.history.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader('RECENT SCANS', colorScheme),
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
                                child: Text('View all', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ],
                          ),
                          _buildModernHistoryList(context, provider, theme, colorScheme),
                        ],
                        SizedBox(height: bottomPadding + 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (provider.isLoading) _buildAnalysisOverlay(context, provider, theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.4),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildWelcomeSection(AppProvider provider, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${provider.timeBasedGreeting},',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          provider.firstName,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 36, color: colorScheme.onSurface, letterSpacing: -1),
        ),
      ],
    );
  }

  Widget _buildSensorMetric(IconData icon, String value, String label, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: -0.5)),
          Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    final isYellow = color.computeLuminance() > 0.6;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3), 
              blurRadius: 15, 
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isYellow ? Colors.black : Colors.white).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isYellow ? Colors.black : Colors.white, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isYellow ? Colors.black : Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(subtitle.toUpperCase(), style: TextStyle(color: (isYellow ? Colors.black : Colors.white).withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHistoryList(BuildContext context, AppProvider provider, ThemeData theme, ColorScheme colorScheme) {
    final history = provider.history;
    final displayCount = history.length > 3 ? 3 : history.length;

    return Column(
      children: List.generate(displayCount, (index) {
        final scan = history[index];
        final isHealthy = scan.diseaseName.toLowerCase().contains('healthy') || scan.diseaseName.contains('Nhyehy');
        final statusColor = isHealthy ? const Color(0xFF4CAF50) : const Color(0xFFD32F2F);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
          ),
          child: InkWell(
            onTap: () {
              provider.setCurrentPrediction(scan);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultScreen()));
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(width: 60, height: 60, child: _buildImage(scan)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scan.diseaseName, 
                          style: TextStyle(
                            fontWeight: FontWeight.w800, 
                            fontSize: 16, 
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5
                          )
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 12, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, hh:mm a').format(scan.dateTime),
                              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1), 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${(scan.confidence * 100).toInt()}%',
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                        Text(
                          'MATCH',
                          style: TextStyle(color: statusColor.withValues(alpha: 0.5), fontWeight: FontWeight.w900, fontSize: 7, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildImage(Prediction scan) {
    if (scan.isAsset) return Image.asset(scan.imagePath, fit: BoxFit.cover);
    if (scan.isNetwork || scan.imagePath.startsWith('http') || scan.imagePath.startsWith('blob:')) {
      return Image.network(scan.imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded));
    }
    if (kIsWeb) return Image.network(scan.imagePath, fit: BoxFit.cover);
    final file = io.File(scan.imagePath);
    return file.existsSync() ? Image.file(file, fit: BoxFit.cover) : const Icon(Icons.image_not_supported_rounded);
  }

  Widget _buildAnalysisOverlay(BuildContext context, AppProvider provider, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 3, color: colorScheme.primary)),
            const SizedBox(height: 32),
            Text(
              provider.tr(provider.analysisMessage).toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text('Processing biological features', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicScheduleCard(BuildContext context, AppProvider provider, ThemeData theme, ColorScheme colorScheme) {
    final suggestion = provider.getSuggestedActivity(DateTime.now());
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SMART RECOMMENDATION', 
                  style: TextStyle(
                    fontSize: 9, 
                    color: colorScheme.primary, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 1.5
                  )
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion, 
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 18, 
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5
                  )
                ),
              ],
            ),
          ),
          Material(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduleScreen())),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.primary, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefinedDrawer(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32))),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.only(topRight: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  key: ValueKey(provider.avatarUrl),
                  radius: 32,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  child: provider.avatarUrl != null 
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: provider.avatarUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          cacheKey: provider.avatarUrl,
                          placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                          errorWidget: (context, url, error) => Icon(Icons.person_rounded, color: colorScheme.primary, size: 32),
                        ),
                      )
                    : Icon(Icons.person_rounded, color: colorScheme.primary, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  provider.userName,
                  style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5),
                ),
                Text(
                  provider.isGuest ? 'Free Access' : 'Pro Farmer Account',
                  style: TextStyle(color: colorScheme.primary.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _drawerTile(context, Icons.dashboard_rounded, provider.tr('Home'), null, true),
                _drawerTile(context, Icons.wb_sunny_rounded, provider.tr('Weather'), const WeatherScreen(), false),
                _drawerTile(context, Icons.event_note_rounded, provider.tr('Planner'), const ScheduleScreen(), false),
                _drawerTile(context, Icons.insights_rounded, provider.tr('Analytics'), const AnalyticsScreen(), false),
                _drawerTile(context, Icons.history_edu_rounded, provider.tr('History'), const HistoryScreen(), false),
                Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(color: theme.dividerColor.withValues(alpha: 0.1))),
                _drawerTile(context, Icons.help_outline_rounded, provider.tr('Help'), const HelpScreen(), false),
                _drawerTile(context, Icons.settings_rounded, provider.tr('Settings'), const SettingsScreen(), false),
                _drawerTile(context, Icons.info_rounded, provider.tr('About Cabbage Doctor'), const AboutScreen(), false),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(32),
            child: ElevatedButton.icon(
              onPressed: () async {
                await provider.signOut();
                if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomepageCharts(AppProvider provider, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildSectionHeader('DISEASE INSIGHTS', colorScheme),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: provider.history.isEmpty
            ? Center(child: Text('No scan data yet', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.w600)))
            : HealthDistributionChart(history: provider.history, colorScheme: colorScheme),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('SCAN ACTIVITY', colorScheme),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(10, 24, 24, 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
          ),
          child: provider.history.isEmpty
            ? Center(child: Text('No activity yet', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.w600)))
            : ActivityTrendChart(history: provider.history, colorScheme: colorScheme),
        ),
        const SizedBox(height: 24),
        _buildHealthMatrix(provider, theme, colorScheme),
      ],
    );
  }

  Widget _buildHealthMatrix(AppProvider provider, ThemeData theme, ColorScheme colorScheme) {
    final leafScans = provider.history.where((s) => s.isLeaf).toList();
    int healthy = leafScans.where((s) => s.diseaseName.toLowerCase().contains('healthy') || s.diseaseName.contains('Nhyehy')).length;
    int diseased = leafScans.length - healthy;
    
    return Row(
      children: [
        _matrixBox('HEALTHY', healthy.toString(), colorScheme.primary, theme, colorScheme),
        const SizedBox(width: 12),
        _matrixBox('DISEASED', diseased.toString(), const Color(0xFFD32F2F), theme, colorScheme),
        const SizedBox(width: 12),
        _matrixBox('OFFLINE', provider.history.length.toString(), colorScheme.secondary, theme, colorScheme),
      ],
    );
  }

  Widget _matrixBox(String label, String value, Color color, ThemeData theme, ColorScheme colorScheme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(BuildContext context, IconData icon, String label, Widget? target, bool isSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        if (target != null) Navigator.push(context, MaterialPageRoute(builder: (context) => target));
      },
      leading: Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.3), size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.6),
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 15,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: isSelected,
      selectedTileColor: colorScheme.primary.withValues(alpha: 0.05),
    );
  }
}

class LeafSlideshow extends StatefulWidget {
  const LeafSlideshow({super.key});
  @override
  State<LeafSlideshow> createState() => _LeafSlideshowState();
}

class _LeafSlideshowState extends State<LeafSlideshow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  final List<String> _assetImages = ['assets/images/c1.jpg', 'assets/images/c2.jpg', 'assets/images/c3.jpg', 'assets/images/c4.jpg', 'assets/images/c5.jpg', 'assets/images/c6.jpg', 'assets/images/c7.jpg', 'assets/images/c8.jpg', 'assets/images/c9.jpg'];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _assetImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 800), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final List<String> tips = ['Regular scanning helps in early disease detection.', 'Early diagnosis can increase crop yield by up to 40%.', 'Frequent field scouting prevents major outbreaks.'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            PageView.builder(controller: _pageController, itemCount: _assetImages.length, onPageChanged: (index) => setState(() => _currentPage = index), itemBuilder: (context, index) => Image.asset(_assetImages[index], fit: BoxFit.cover)),
            Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.center, colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent])))),
            Positioned(
              bottom: 24, left: 24, right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: colorScheme.secondary, borderRadius: BorderRadius.circular(8)),
                    child: const Text('EXPERT TIP', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 8),
                  Text(tips[_currentPage % tips.length], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.3)),
                ],
              ),
            ),
            Positioned(top: 20, right: 24, child: Row(children: List.generate(_assetImages.length, (index) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.only(left: 4), height: 4, width: _currentPage == index ? 16 : 4, decoration: BoxDecoration(color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))))),
          ],
        ),
      ),
    );
  }
}

class HealthDistributionChart extends StatelessWidget {
  final List<Prediction> history;
  final ColorScheme colorScheme;
  const HealthDistributionChart({super.key, required this.history, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final leafScans = history.where((s) => s.isLeaf).toList();
    int healthy = leafScans.where((s) => s.diseaseName.toLowerCase().contains('healthy') || s.diseaseName.contains('Nhyehy')).length;
    int diseased = leafScans.length - healthy;

    if (healthy == 0 && diseased == 0) {
      return Center(
        child: Text(
          'No leaf scans analyzed', 
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 12, fontWeight: FontWeight.w600)
        ),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          if (healthy > 0) PieChartSectionData(
            value: healthy.toDouble(),
            title: '$healthy',
            radius: 20,
            color: colorScheme.primary,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          if (diseased > 0) PieChartSectionData(
            value: diseased.toDouble(),
            title: '$diseased',
            radius: 18,
            color: const Color(0xFFD32F2F),
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class ActivityTrendChart extends StatelessWidget {
  final List<Prediction> history;
  final ColorScheme colorScheme;
  const ActivityTrendChart({super.key, required this.history, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    // Group scans by day for the last 7 days
    final now = DateTime.now();
    final List<FlSpot> spots = [];
    
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final count = history.where((s) => 
        s.dateTime.year == day.year && 
        s.dateTime.month == day.month && 
        s.dateTime.day == day.day
      ).length;
      spots.add(FlSpot((6 - i).toDouble(), count.toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Text(days[val.toInt() % 7], style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.bold));
              },
              reservedSize: 22,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: colorScheme.primary.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }
}
