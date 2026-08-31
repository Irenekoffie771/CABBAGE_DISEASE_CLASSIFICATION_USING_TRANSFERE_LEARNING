import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_provider.dart';
import '../models/prediction_model.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  bool _isHealthy(Prediction scan) {
    final name = scan.diseaseName.toLowerCase();
    return name.contains('healthy') || name.contains('nhyehy');
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final history = provider.history;

    final leafScans = history.where((s) => s.isLeaf).toList();
    Map<String, int> counts = {};
    int healthyCount = 0;
    for (var item in leafScans) {
      if (_isHealthy(item)) {
        healthyCount++;
      } else {
        counts[item.diseaseName] = (counts[item.diseaseName] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, provider, colorScheme),
          if (history.isEmpty)
            _buildEmptyState(provider, colorScheme)
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderStats(provider, healthyCount, theme, colorScheme),
                    const SizedBox(height: 40),
                    _buildSectionLabel('DISEASE DISTRIBUTION', colorScheme),
                    const SizedBox(height: 16),
                    _buildChartCard(leafScans, healthyCount, theme, colorScheme, counts),
                    const SizedBox(height: 40),
                    _buildSectionLabel('FIELD INSIGHTS', colorScheme),
                    const SizedBox(height: 16),
                    _buildAIActions(provider, counts, healthyCount, theme, colorScheme),
                    const SizedBox(height: 40),
                    _buildSectionLabel('DETAILED BREAKDOWN', colorScheme),
                    const SizedBox(height: 24),
                    _buildBreakdownList(leafScans, healthyCount, colorScheme, counts),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AppProvider provider, ColorScheme colorScheme) {
    return SliverAppBar(
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
          provider.tr('Field Analytics').toUpperCase(),
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
    );
  }

  Widget _buildEmptyState(AppProvider provider, ColorScheme colorScheme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: colorScheme.primary.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(provider.tr('No data available yet.'), style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStats(AppProvider provider, int healthy, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        _statBox('TOTAL SCANS', provider.history.length.toString(), colorScheme.primary, theme, colorScheme),
        const SizedBox(width: 12),
        _statBox('HEALTHY', healthy.toString(), colorScheme.secondary, theme, colorScheme),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color, ThemeData theme, ColorScheme colorScheme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(List<Prediction> leafScans, int healthy, ThemeData theme, ColorScheme colorScheme, Map<String, int> counts) {
    if (leafScans.isEmpty) return const SizedBox();
    
    final sections = [
      if (healthy > 0) PieChartSectionData(color: colorScheme.primary, value: healthy.toDouble(), title: '', radius: 20),
      ...counts.entries.map((e) => PieChartSectionData(color: _getColor(e.key), value: e.value.toDouble(), title: '', radius: 15)),
    ];

    if (sections.isEmpty) return const SizedBox();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 50,
          sectionsSpace: 4,
        ),
      ),
    );
  }

  Widget _buildAIActions(AppProvider provider, Map<String, int> counts, int healthy, ThemeData theme, ColorScheme colorScheme) {
    final isTwi = provider.language == 'Twi';
    String title = healthy > 0 && counts.isEmpty ? (isTwi ? 'Afuom yɛ papa' : 'Field is Healthy') : (isTwi ? 'Yɛn adwumayɛ' : 'Action Required');
    String desc = healthy > 0 && counts.isEmpty ? (isTwi ? 'Kɔ so scan dabiara.' : 'Continue regular AI monitoring.') : (isTwi ? 'Hwɛ yadeɛ no so yiye.' : 'Review treatment plans for detected diseases.');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_rounded, color: colorScheme.secondary, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownList(List<Prediction> leafScans, int healthy, ColorScheme colorScheme, Map<String, int> counts) {
    if (leafScans.isEmpty) return const SizedBox();
    return Column(
      children: [
        if (healthy > 0) _breakdownRow('Healthy Plants', healthy, leafScans.length, colorScheme.primary, colorScheme),
        ...counts.entries.map((e) => _breakdownRow(e.key, e.value, leafScans.length, _getColor(e.key), colorScheme)),
      ],
    );
  }

  Widget _breakdownRow(String name, int count, int total, Color color, ColorScheme colorScheme) {
    double progress = count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colorScheme.onSurface)),
              Text('$count SCANS', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: colorScheme.onSurface.withValues(alpha: 0.05), color: color),
          ),
        ],
      ),
    );
  }

  Color _getColor(String name) {
    if (name.contains('Black Rot')) return Colors.brown.shade400;
    if (name.contains('Downy')) return const Color(0xFFFBC02D);
    return const Color(0xFFD32F2F);
  }

  Widget _buildSectionLabel(String text, ColorScheme colorScheme) {
    return Text(text, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }
}
