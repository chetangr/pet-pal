import 'package:flutter/material.dart';

class PromoBanner extends StatefulWidget {
  const PromoBanner({Key? key}) : super(key: key);

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  
  // Sample promos
  final List<PromoModel> _promos = [
    PromoModel(
      title: 'New Customer Special',
      subtitle: 'Get 15% off your first order',
      color: Colors.blue,
      actionText: 'Shop Now',
      iconData: Icons.local_offer,
    ),
    PromoModel(
      title: 'Free Shipping',
      subtitle: 'On orders over \$50',
      color: Colors.orange,
      actionText: 'Learn More',
      iconData: Icons.local_shipping,
    ),
    PromoModel(
      title: 'Premium Food Sale',
      subtitle: 'Up to 30% off top brands',
      color: Colors.green,
      actionText: 'View Deals',
      iconData: Icons.restaurant,
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Auto scroll
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _startAutoScroll();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        int nextPage = (_currentPage + 1) % _promos.length;
        _controller.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          // Banner content
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _promos.length,
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return _buildPromoBanner(promo, screenWidth);
            },
          ),
          
          // Page indicator
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_promos.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _currentPage == index ? 16 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPromoBanner(PromoModel promo, double screenWidth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            promo.color,
            promo.color.withBlue(promo.color.blue + 40).withRed(promo.color.red - 30),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: promo.color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              promo.iconData,
              size: 120,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        promo.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promo.subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Navigate to promo page
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: promo.color,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(promo.actionText),
                      ),
                    ],
                  ),
                ),
                
                // Icon
                Icon(
                  promo.iconData,
                  size: 60,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PromoModel {
  final String title;
  final String subtitle;
  final Color color;
  final String actionText;
  final IconData iconData;
  
  PromoModel({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.actionText,
    required this.iconData,
  });
}