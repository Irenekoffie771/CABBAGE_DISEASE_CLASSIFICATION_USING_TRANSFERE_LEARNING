import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import '../services/app_provider.dart';
import '../models/prediction_model.dart';
import 'disease_info_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text, String language) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      if (language == 'Twi') {
        await _flutterTts.setLanguage("ak-GH");
      } else {
        await _flutterTts.setLanguage("en-US");
      }
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak(text);
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
    }
  }

  void _shareReport(String disease, String treatment, String imagePath, bool isAsset, bool isNetwork) {
    String text = 'Cabbage Doctor Report\n\nDisease: $disease\n\nRecommended Treatment: $treatment';
    if (isAsset) {
      Share.share(text, subject: 'Cabbage Health Report');
    } else {
      Share.shareXFiles([XFile(imagePath)], text: text, subject: 'Cabbage Health Report');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final prediction = provider.currentPrediction;
    final isTwi = provider.language == 'Twi';

    if (prediction == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: Text('No result found')),
      );
    }

    final isNotLeaf = !prediction.isLeaf;
    final isHealthy = prediction.diseaseName.toLowerCase().contains('healthy') || 
                      prediction.diseaseName.toLowerCase().contains('nhyehyɛe');

    Color statusColor = isNotLeaf ? const Color(0xFFD32F2F) : (isHealthy ? const Color(0xFF2E7D32) : const Color(0xFFFBC02D));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: colorScheme.primary,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
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
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                  onPressed: () => _shareReport(prediction.diseaseName, prediction.treatment, prediction.imagePath, prediction.isAsset, prediction.isNetwork),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Diagnosis'.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 10, letterSpacing: 3),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(prediction),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isNotLeaf ? 'ERROR' : (isHealthy ? 'HEALTHY' : 'DISEASE DETECTED'),
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              prediction.diseaseName,
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -1),
                            ),
                          ],
                        ),
                      ),
                      _buildConfidenceCircle(prediction.confidence, statusColor),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  _buildVoiceAction(provider, prediction, isTwi, colorScheme),
                  
                  const SizedBox(height: 48),
                  _buildSectionLabel('DIAGNOSIS ANALYSIS', colorScheme),
                  const SizedBox(height: 12),
                  _buildInfoCard(prediction.description, theme, colorScheme),
                  
                  if (!isNotLeaf) ...[
                    const SizedBox(height: 32),
                    _buildSectionLabel('TREATMENT RECOMMENDATIONS', colorScheme),
                    const SizedBox(height: 12),
                    _buildInfoCard(prediction.treatment, theme, colorScheme),
                  ],

                  const SizedBox(height: 48),
                  if (!isNotLeaf) ...[
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DiseaseInfoScreen(prediction: prediction),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary.withValues(alpha: 0.1),
                        foregroundColor: colorScheme.secondary,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: colorScheme.secondary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 20),
                          const SizedBox(width: 12),
                          Text(provider.tr('View Detailed Disease Info'), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 48),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        provider.tr('Friendly Tip: For the best results, please take a clear photo of the leaf. Occasionally, other objects might be mistaken for a cabbage leaf.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 100),
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

  Widget _buildInfoCard(String text, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05)),
      ),
      child: Text(text, style: TextStyle(color: colorScheme.onSurface, fontSize: 16, height: 1.6, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildConfidenceCircle(double confidence, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('${(confidence * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color)),
          Text('MATCH', style: TextStyle(fontSize: 8, color: color.withValues(alpha: 0.5), fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildVoiceAction(AppProvider provider, Prediction prediction, bool isTwi, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => _speak('${prediction.diseaseName}. ${prediction.description}. ${isTwi ? 'Ayaresa' : 'Treatment'}: ${prediction.treatment}', provider.language),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: colorScheme.primary.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))
          ],
        ),
        child: Row(
          children: [
            Icon(_isSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 20),
            Text(
              isTwi ? 'Tie afutuo no' : 'Listen to AI Advice', 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(Prediction scan) {
    if (scan.isAsset) return Image.asset(scan.imagePath, fit: BoxFit.cover);
    if (scan.isNetwork || scan.imagePath.startsWith('http') || scan.imagePath.startsWith('blob:')) {
      return Image.network(scan.imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)));
    }
    if (kIsWeb) return Image.network(scan.imagePath, fit: BoxFit.cover);
    final file = io.File(scan.imagePath);
    return file.existsSync() ? Image.file(file, fit: BoxFit.cover) : const Center(child: Icon(Icons.image_not_supported));
  }
}
