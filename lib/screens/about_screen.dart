import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
            expandedHeight: 150,
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
                'About'.toUpperCase(),
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
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.8), 
                          colorScheme.primary
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      Icons.info_outline_rounded, 
                      size: 150, 
                      color: Colors.white.withValues(alpha: 0.05)
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  theme.brightness == Brightness.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => provider.toggleTheme(theme.brightness == Brightness.light),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Hero(
                          tag: 'app_logo',
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset(
                                'assets/images/c10.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Cabbage Doctor AI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28, 
                            fontWeight: FontWeight.w900, 
                            color: colorScheme.onSurface, 
                            letterSpacing: -1
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            'v1.0.1 STABLE',
                            style: TextStyle(
                              color: colorScheme.secondary, 
                              fontSize: 10, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 1
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 56),
                  _buildSection(
                    context,
                    'OUR MISSION', 
                    'Empowering Ghanaian farmers with AI to secure food production and improve yields through cutting-edge diagnostics.',
                    Icons.auto_awesome_rounded
                  ),
                  _buildSection(
                    context,
                    'DEVELOPMENT TEAM', 
                    'Crafted by Final Year IT Students from UENR, Sunyani. Our team is dedicated to solving real-world agricultural challenges using technology.',
                    Icons.groups_rounded
                  ),
                  _buildSection(
                    context,
                    'CORE TECHNOLOGY', 
                    'The platform leverages Flutter for multi-platform reach, Google Gemini for expert agricultural advice, and Supabase for secure data orchestration.',
                    Icons.psychology_rounded
                  ),
                  
                  const SizedBox(height: 32),
                  const Divider(height: 1),
                  const SizedBox(height: 32),
                  
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'POWERED BY UENR IT'.toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.3), 
                            fontSize: 10, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 2
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '© ${DateTime.now().year} ALL RIGHTS RESERVED',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.15), 
                            fontSize: 9, 
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.primary, 
                    fontSize: 11, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 1.5
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7), 
                fontSize: 15, 
                height: 1.6, 
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
      ),
    );
  }
}
