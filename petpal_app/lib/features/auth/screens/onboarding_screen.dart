import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/config/app_theme.dart';
import 'package:petpal/features/auth/providers/auth_provider.dart';
import 'package:petpal/features/auth/widgets/auth_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to PetPal',
      description: 'Your complete pet management solution in one app.',
      illustration: Icons.pets_rounded,
      backgroundColor: AppColors.primary,
    ),
    OnboardingPage(
      title: 'Track Your Pet\'s Health',
      description: 'Monitor weight, medications, vaccinations, and vet appointments.',
      illustration: Icons.favorite_rounded,
      backgroundColor: AppColors.error,
    ),
    OnboardingPage(
      title: 'Daily Journal',
      description: 'Log meals, activities, and behaviors to better understand your pet.',
      illustration: Icons.auto_stories_rounded,
      backgroundColor: AppColors.secondary,
    ),
    OnboardingPage(
      title: 'Never Lose Your Pet',
      description: 'Lost mode alerts nearby users and helps you find your pet quickly.',
      illustration: Icons.location_on_rounded,
      backgroundColor: AppColors.accent,
    ),
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }
  
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }
  
  void _finishOnboarding() async {
    // Update user settings to mark onboarding as complete
    final authService = ref.read(authServiceProvider);
    await authService.updateProfile(
      settings: {'onboarding_completed': true},
    );
    
    // Navigate to home
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Page content
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _buildPage(page);
            },
          ),
          
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildDot(index),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Buttons
                  Row(
                    children: [
                      // Skip button (only show if not on last page)
                      if (_currentPage < _pages.length - 1)
                        TextButton(
                          onPressed: _finishOnboarding,
                          child: Text('Skip'),
                        )
                      else
                        const Spacer(),
                      const Spacer(),
                      // Next/Finish button
                      AuthButton(
                        label: _currentPage < _pages.length - 1
                            ? 'Next'
                            : 'Get Started',
                        onPressed: _nextPage,
                        icon: _currentPage < _pages.length - 1
                            ? Icons.arrow_forward_rounded
                            : Icons.check_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPage(OnboardingPage page) {
    final theme = Theme.of(context);
    
    return Container(
      color: page.backgroundColor,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Illustration
            Icon(
              page.illustration,
              size: 150,
              color: Colors.white,
            ),
            const SizedBox(height: 60),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(
                    page.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    page.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDot(int index) {
    final isActive = index == _currentPage;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData illustration;
  final Color backgroundColor;
  
  OnboardingPage({
    required this.title,
    required this.description,
    required this.illustration,
    required this.backgroundColor,
  });
}