import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onQuickScan() {
    Provider.of<AppProvider>(context, listen: false).setGuestUser();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isTwi = provider.language == 'Twi';

    final List<OnboardingData> pages = [
      OnboardingData(
        title: isTwi ? 'Nhwehwɛmu\na Ɛdi Mu' : 'Precision\nDetection',
        subtitle: isTwi ? 'AI NHWEHWƐMU' : 'AI DIAGNOSTICS',
        description: isTwi 
            ? 'Yɛn AI adwuma yi hu kabeji yadeɛ nyinaa ntɛm paa.' 
            : 'Advanced neural networks detect cabbage diseases with high accuracy in seconds.',
        imagePath: 'assets/images/c2.jpg',
      ),
      OnboardingData(
        title: isTwi ? 'Afutuo Pa\nfiri AI Mu' : 'Expert Field\nGuidance',
        subtitle: isTwi ? 'AKUAFOƆ MMOA' : 'FARM ASSISTANT',
        description: isTwi 
            ? 'Nya ayaresa ne akwan a wobɛfa so asiw yadeɛ kwan.' 
            : 'Receive localized treatment plans and preventive measures tailored for your crop.',
        imagePath: 'assets/images/c3.jpg',
      ),
      OnboardingData(
        title: isTwi ? 'Intanɛt\nNni Ho a' : 'Reliable\nOffline',
        subtitle: isTwi ? 'AFUO MU MMOA' : 'OFFLINE CAPABLE',
        description: isTwi 
            ? 'Scan wo nnɔbae no wɔ baabiara, mpo mmeae a intanɛt nni hɔ.' 
            : 'Scan your crops anywhere, even in remote fields. All models run directly on your device.',
        imagePath: 'assets/images/c4.jpg',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _currentPage > 0 
                    ? IconButton(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2E7D32), size: 20),
                      )
                    : const SizedBox(width: 40),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                    child: Text(
                      'Skip',
                      style: TextStyle(color: Colors.black.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (int page) => setState(() => _currentPage = page),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE8F5E9), width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: AssetImage(pages[index].imagePath),
                            backgroundColor: const Color(0xFFF1F8E9),
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          pages[index].subtitle,
                          style: const TextStyle(
                            color: Color(0xFFFBC02D),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          pages[index].title,
                          style: const TextStyle(
                            color: Color(0xFF1B5E20),
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          pages[index].description,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.5),
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 6,
                        width: _currentPage == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == pages.length - 1) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                      } else {
                        _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                    ),
                    child: Text(
                      _currentPage == pages.length - 1 ? 'Get Started' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              Center(
                child: TextButton(
                  onPressed: _onQuickScan,
                  child: Text(
                    isTwi ? 'Yɛ Nhwehwɛmu Ntɛm' : 'Try Quick Scan',
                    style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
  });
}
