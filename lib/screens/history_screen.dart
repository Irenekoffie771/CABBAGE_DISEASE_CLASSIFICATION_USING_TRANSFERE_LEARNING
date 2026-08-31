import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_provider.dart';
import '../models/prediction_model.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isSelectionMode = false;
  final Set<Prediction> _selectedItems = {};

  void _toggleSelection(Prediction item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
        if (_selectedItems.isEmpty) _isSelectionMode = false;
      } else {
        _selectedItems.add(item);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<Prediction> history) {
    setState(() {
      if (_selectedItems.length == history.length) {
        _selectedItems.clear();
        _isSelectionMode = false;
      } else {
        _selectedItems.clear();
        _selectedItems.addAll(history);
        _isSelectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final history = provider.history;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, provider, history, colorScheme),
          if (history.isEmpty)
            _buildEmptyState(provider, colorScheme)
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = history[index];
                    final isSelected = _selectedItems.contains(item);
                    return _buildHistoryItem(context, provider, item, isSelected, theme, colorScheme);
                  },
                  childCount: history.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isSelectionMode ? FloatingActionButton(
        onPressed: () => _deleteSelected(provider),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_sweep_rounded),
      ) : null,
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AppProvider provider, List<Prediction> history, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: _isSelectionMode ? const Color(0xFFD32F2F) : colorScheme.primary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: Icon(_isSelectionMode ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (_isSelectionMode) {
              setState(() { _isSelectionMode = false; _selectedItems.clear(); });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          _isSelectionMode ? '${_selectedItems.length} SELECTED' : provider.tr('Scan History').toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 10, letterSpacing: 3),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isSelectionMode 
                ? [const Color(0xFFB71C1C), const Color(0xFFD32F2F)]
                : [colorScheme.primary.withValues(alpha: 0.8), colorScheme.primary],
            ),
          ),
        ),
      ),
      actions: [
        if (history.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isSelectionMode
              ? IconButton(
                  icon: Icon(_selectedItems.length == history.length ? Icons.deselect_rounded : Icons.select_all_rounded, color: Colors.white, size: 20),
                  onPressed: () => _selectAll(history),
                )
              : Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Theme.of(context).brightness == Brightness.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => provider.toggleTheme(Theme.of(context).brightness == Brightness.light),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 22),
                      onSelected: (value) {
                        if (value == 'select') {
                          setState(() => _isSelectionMode = true);
                        } else if (value == 'delete_all') {
                          _deleteAll(provider);
                        }
                      },
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'select', child: Text(provider.tr('Select Scans'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black))),
                        PopupMenuItem(value: 'delete_all', child: Text(provider.tr('Delete All'), style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 14, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ],
                ),
          ),
        ] else ...[
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => provider.toggleTheme(Theme.of(context).brightness == Brightness.light),
          ),
          const SizedBox(width: 8),
        ]
      ],
    );
  }

  Widget _buildEmptyState(AppProvider provider, ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: colorScheme.primary.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text(provider.tr('No history yet.'), style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, AppProvider provider, Prediction item, bool isSelected, ThemeData theme, ColorScheme colorScheme) {
    final isHealthy = item.diseaseName.toLowerCase().contains('healthy') || item.diseaseName.contains('Nhyehy');
    final statusColor = isHealthy ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.05)),
        boxShadow: [
          if (!isSelected) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: InkWell(
        onLongPress: () => _toggleSelection(item),
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(item);
          } else {
            provider.setCurrentPrediction(item);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultScreen()));
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (_isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (val) => _toggleSelection(item),
                  activeColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 8),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 56, height: 56, child: _buildImage(item)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.diseaseName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM dd, yyyy • hh:mm a').format(item.dateTime), style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${(item.confidence * 100).toInt()}%', style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Prediction scan) {
    if (scan.isAsset) {
      return Image.asset(scan.imagePath, fit: BoxFit.cover);
    }
    if (scan.isNetwork || scan.imagePath.startsWith('http') || scan.imagePath.startsWith('blob:')) {
      return Image.network(scan.imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)));
    }
    if (kIsWeb) {
      return Image.network(scan.imagePath, fit: BoxFit.cover);
    }
    final file = io.File(scan.imagePath);
    return file.existsSync() ? Image.file(file, fit: BoxFit.cover) : const Center(child: Icon(Icons.image_not_supported_rounded, color: Colors.grey));
  }

  Future<void> _deleteSelected(AppProvider provider) async {
    provider.deleteMultipleScans(_selectedItems.toList());
    setState(() { _selectedItems.clear(); _isSelectionMode = false; });
  }

  Future<void> _deleteAll(AppProvider provider) async {
    provider.deleteAllHistory();
    setState(() { _selectedItems.clear(); _isSelectionMode = false; });
  }
}
