import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../models/prediction_model.dart';

class DiseaseInfoScreen extends StatelessWidget {
  final Prediction prediction;

  const DiseaseInfoScreen({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final details = provider.getDiseaseDetails(prediction.diseaseName);
    final isTwi = provider.language == 'Twi';
    
    final String description = isTwi 
        ? (details?['twi_description'] ?? prediction.description)
        : (details?['description'] ?? prediction.description);
        
    final String treatment = isTwi
        ? (details?['twi_treatment'] ?? prediction.treatment)
        : (details?['treatment'] ?? prediction.treatment);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: colorScheme.primary,
            elevation: 0,
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
                provider.tr('Disease Info').toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900, 
                  color: Colors.white, 
                  fontSize: 10, 
                  letterSpacing: 3
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    details?['image'] ?? 'assets/images/c1.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction.diseaseName,
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.w800, 
                      color: colorScheme.onSurface, 
                      letterSpacing: -1
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      provider.tr('AI ANALYSIS REPORT'),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  _buildInfoSection(
                    context: context,
                    title: provider.tr('DESCRIPTION'),
                    content: description,
                    icon: Icons.description_outlined,
                  ),
                  
                  _buildInfoSection(
                    context: context,
                    title: provider.tr('SYMPTOMS'),
                    content: details?['symptoms'] ?? 'No symptoms data available.',
                    icon: Icons.coronavirus_outlined,
                  ),
                  
                  _buildInfoSection(
                    context: context,
                    title: provider.tr('CAUSES'),
                    content: details?['causes'] ?? 'No causes data available.',
                    icon: Icons.help_outline_rounded,
                  ),
                  
                  _buildInfoSection(
                    context: context,
                    title: provider.tr('PREVENTION'),
                    content: details?['prevention'] ?? 'No prevention data available.',
                    icon: Icons.shield_outlined,
                  ),
                  
                  _buildInfoSection(
                    context: context,
                    title: provider.tr('TREATMENT'),
                    content: treatment,
                    icon: Icons.medication_outlined,
                    isLast: true,
                  ),
                  
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'Figure X.X: Disease information page generated after classification.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required BuildContext context,
    required String title,
    required String content,
    required IconData icon,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
            ),
            child: Text(
              content,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
