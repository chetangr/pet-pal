import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:petpal/features/store/models/product.dart';
import 'package:petpal/features/store/providers/store_provider.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final String? heroTagPrefix;
  
  const ProductCard({
    Key? key,
    required this.product,
    this.heroTagPrefix,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cart = ref.watch(cartProvider);
    final isInCart = cart.containsKey(product.id);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to product detail
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Stack(
              children: [
                Hero(
                  tag: '${heroTagPrefix ?? ''}${product.id}',
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: product.imageUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrls.first,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.error),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                
                // Sale badge
                if (product.isOnSale)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.discountPercent?.toInt()}% OFF',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                
                // Out of stock overlay
                if (!product.isInStock)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.6),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'OUT OF STOCK',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Product details
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Product brand
                  Text(
                    product.brand,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Price and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.isOnSale) ...[
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            Text(
                              '\$${product.discountedPrice.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else ...[
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      // Rating
                      if (product.rating != null)
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product.rating!.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Add to cart button
            Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  onPressed: product.isInStock
                      ? () {
                          if (isInCart) {
                            ref.read(cartProvider.notifier).removeFromCart(product.id);
                          } else {
                            ref.read(cartProvider.notifier).addToCart(product.id);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: isInCart
                        ? colorScheme.primary
                        : colorScheme.surfaceVariant,
                    foregroundColor: isInCart
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                  ),
                  child: Text(
                    isInCart ? 'In Cart' : 'Add to Cart',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isInCart ? colorScheme.onPrimary : colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}