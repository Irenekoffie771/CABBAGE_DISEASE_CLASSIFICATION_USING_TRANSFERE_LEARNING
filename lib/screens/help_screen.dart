import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          provider.tr('Help').toUpperCase(),
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.tr('How to Use the App'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 32),
            
            _buildStep(
              context,
              '1',
              provider.tr('Capture Image'),
              provider.tr('Use the camera to take a clear photo of the cabbage leaf.'),
              Icons.camera_alt_rounded,
            ),
            _buildStep(
              context,
              '2',
              provider.tr('Upload'),
              provider.tr('Select a cabbage leaf image from your gallery.'),
              Icons.image_rounded,
            ),
            _buildStep(
              context,
              '3',
              provider.tr('Wait'),
              provider.tr('Our AI analyzes the biological features of the leaf.'),
              Icons.hourglass_empty_rounded,
            ),
            _buildStep(
              context,
              '4',
              provider.tr('View Result'),
              provider.tr('Get instant diagnosis and treatment recommendations.'),
              Icons.fact_check_rounded,
              isLast: true,
            ),
            
            const SizedBox(height: 64),
            Center(
              child: Text(
                'Figure X.X: User guide incorporated into the application.',
                textAlign: TextAlign.center,
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
    );
  }

  Widget _buildStep(
    BuildContext context,
    String stepNumber,
    String title,
    String description,
    IconData icon, {
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isLast) const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
