import 'package:flutter/material.dart';
import 'package:petpal/features/store/models/product.dart';

class CategoryCard extends StatelessWidget {
  final ProductCategory category;
  final VoidCallback onTap;
  
  const CategoryCard({
    Key? key,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: _getCategoryColor(category),
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getCategoryName(category),
              style: theme.textTheme.labelMedium,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(ProductCategory category) {
    switch (category) {
      case ProductCategory.food:
        return Icons.restaurant;
      case ProductCategory.treats:
        return Icons.cake;
      case ProductCategory.toys:
        return Icons.toys;
      case ProductCategory.accessories:
        return Icons.pets;
      case ProductCategory.health:
        return Icons.healing;
      case ProductCategory.grooming:
        return Icons.content_cut;
      case ProductCategory.clothing:
        return Icons.checkroom;
      case ProductCategory.travel:
        return Icons.card_travel;
      case ProductCategory.training:
        return Icons.school;
      case ProductCategory.technology:
        return Icons.devices;
      case ProductCategory.services:
        return Icons.miscellaneous_services;
      case ProductCategory.other:
        return Icons.more_horiz;
    }
  }
  
  String _getCategoryName(ProductCategory category) {
    switch (category) {
      case ProductCategory.food:
        return 'Food';
      case ProductCategory.treats:
        return 'Treats';
      case ProductCategory.toys:
        return 'Toys';
      case ProductCategory.accessories:
        return 'Accessories';
      case ProductCategory.health:
        return 'Health';
      case ProductCategory.grooming:
        return 'Grooming';
      case ProductCategory.clothing:
        return 'Clothing';
      case ProductCategory.travel:
        return 'Travel';
      case ProductCategory.training:
        return 'Training';
      case ProductCategory.technology:
        return 'Tech';
      case ProductCategory.services:
        return 'Services';
      case ProductCategory.other:
        return 'Other';
    }
  }
  
  Color _getCategoryColor(ProductCategory category) {
    switch (category) {
      case ProductCategory.food:
        return Colors.orange;
      case ProductCategory.treats:
        return Colors.amber;
      case ProductCategory.toys:
        return Colors.blue;
      case ProductCategory.accessories:
        return Colors.purple;
      case ProductCategory.health:
        return Colors.red;
      case ProductCategory.grooming:
        return Colors.teal;
      case ProductCategory.clothing:
        return Colors.pink;
      case ProductCategory.travel:
        return Colors.indigo;
      case ProductCategory.training:
        return Colors.green;
      case ProductCategory.technology:
        return Colors.blueGrey;
      case ProductCategory.services:
        return Colors.brown;
      case ProductCategory.other:
        return Colors.grey;
    }
  }
}