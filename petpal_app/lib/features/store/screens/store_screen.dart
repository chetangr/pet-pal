import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/constants/app_icons.dart';
import 'package:petpal/features/store/models/product.dart';
import 'package:petpal/features/store/providers/store_provider.dart';
import 'package:petpal/features/store/widgets/product_card.dart';
import 'package:petpal/features/store/widgets/category_card.dart';
import 'package:petpal/features/store/widgets/promo_banner.dart';
import 'package:petpal/features/pets/providers/pet_provider.dart';
import 'package:petpal/widgets/loading_indicator.dart';
import 'package:petpal/widgets/empty_state.dart';
import 'package:petpal/widgets/error_view.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ProductCategory? _selectedCategory;
  String? _selectedPetType;
  
  @override
  void initState() {
    super.initState();
    
    // Load products
    Future.microtask(() {
      ref.read(productsProvider.notifier).loadProducts();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
  }
  
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }
  
  void _selectCategory(ProductCategory category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;
      } else {
        _selectedCategory = category;
      }
    });
  }
  
  void _selectPetType(String petType) {
    setState(() {
      if (_selectedPetType == petType) {
        _selectedPetType = null;
      } else {
        _selectedPetType = petType;
      }
    });
  }
  
  List<Product> _filterProducts(List<Product> products) {
    if (_searchQuery.isNotEmpty) {
      final normalizedQuery = _searchQuery.toLowerCase();
      products = products.where((product) {
        return product.name.toLowerCase().contains(normalizedQuery) ||
               product.description.toLowerCase().contains(normalizedQuery) ||
               product.brand.toLowerCase().contains(normalizedQuery) ||
               product.tags.any((tag) => tag.toLowerCase().contains(normalizedQuery));
      }).toList();
    }
    
    if (_selectedCategory != null) {
      products = products.where((product) => product.category == _selectedCategory).toList();
    }
    
    if (_selectedPetType != null) {
      products = products.where((product) => product.forPetTypes.contains(_selectedPetType)).toList();
    }
    
    return products;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final productsAsync = ref.watch(productsProvider);
    final petsAsync = ref.watch(petsProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    
    // Search results
    final searchResults = _searchQuery.isNotEmpty
        ? ref.watch(productSearchProvider(_searchQuery))
        : [];
    
    // Featured products
    final featuredProductsAsync = ref.watch(featuredProductsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Store'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  // TODO: Navigate to cart
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      cartItemCount.toString(),
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant,
              ),
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
            ),
          ),
          
          // Filter chips
          if (_selectedCategory != null || _selectedPetType != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedCategory != null)
                    Chip(
                      label: Text(_getCategoryName(_selectedCategory!)),
                      onDeleted: () {
                        setState(() {
                          _selectedCategory = null;
                        });
                      },
                    ),
                  if (_selectedPetType != null)
                    Chip(
                      label: Text('For: $_selectedPetType'),
                      onDeleted: () {
                        setState(() {
                          _selectedPetType = null;
                        });
                      },
                    ),
                ],
              ),
            ),
          
          // Main content
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults(searchResults)
                : _buildMainStoreContent(productsAsync, petsAsync),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults(List<Product> results) {
    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No Results Found',
        message: 'Try a different search term or browse categories',
        actionLabel: 'Clear Search',
        onAction: _clearSearch,
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ProductCard(product: product);
      },
    );
  }
  
  Widget _buildMainStoreContent(AsyncValue<List<Product>> productsAsync, AsyncValue<List<PetModel>> petsAsync) {
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const EmptyState(
            icon: AppIcons.store,
            title: 'Store Coming Soon',
            message: 'Check back later for pet products and supplies',
          );
        }
        
        // Apply filters if any
        final filteredProducts = _filterProducts(products);
        
        if (_selectedCategory != null || _selectedPetType != null) {
          if (filteredProducts.isEmpty) {
            return EmptyState(
              icon: Icons.filter_list_off,
              title: 'No Matching Products',
              message: 'Try different filters',
              actionLabel: 'Clear Filters',
              onAction: () {
                setState(() {
                  _selectedCategory = null;
                  _selectedPetType = null;
                });
              },
            );
          }
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return ProductCard(product: product);
            },
          );
        }
        
        // Main store content with sections
        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(productsProvider.notifier).loadProducts(
              forceRefresh: true,
            );
          },
          child: ListView(
            children: [
              // Promotional banner
              const PromoBanner(),
              
              const SizedBox(height: 16),
              
              // Pet type filter
              petsAsync.when(
                data: (pets) {
                  if (pets.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  // Get unique pet types
                  final petTypes = <String>{};
                  for (final pet in pets) {
                    petTypes.add(pet.type.name);
                  }
                  
                  return SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: petTypes.map((type) {
                        final isSelected = _selectedPetType == type;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('For $type'),
                            selected: isSelected,
                            onSelected: (_) => _selectPetType(type),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              
              const SizedBox(height: 16),
              
              // Categories section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Categories',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    CategoryCard(
                      category: ProductCategory.food,
                      onTap: () => _selectCategory(ProductCategory.food),
                    ),
                    CategoryCard(
                      category: ProductCategory.treats,
                      onTap: () => _selectCategory(ProductCategory.treats),
                    ),
                    CategoryCard(
                      category: ProductCategory.toys,
                      onTap: () => _selectCategory(ProductCategory.toys),
                    ),
                    CategoryCard(
                      category: ProductCategory.accessories,
                      onTap: () => _selectCategory(ProductCategory.accessories),
                    ),
                    CategoryCard(
                      category: ProductCategory.health,
                      onTap: () => _selectCategory(ProductCategory.health),
                    ),
                    CategoryCard(
                      category: ProductCategory.grooming,
                      onTap: () => _selectCategory(ProductCategory.grooming),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Featured products section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured Products',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to all featured products
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 260,
                child: _buildFeaturedProducts(),
              ),
              
              const SizedBox(height: 24),
              
              // Best sellers section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Best Sellers',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to all best sellers
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 260,
                child: _buildBestSellers(products),
              ),
              
              const SizedBox(height: 24),
              
              // New arrivals section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Arrivals',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to all new arrivals
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 260,
                child: _buildNewArrivals(products),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stack) => ErrorView(
        title: 'Error',
        message: 'Failed to load products: $error',
        actionLabel: 'Retry',
        onAction: () {
          ref.read(productsProvider.notifier).loadProducts(
            forceRefresh: true,
          );
        },
      ),
    );
  }
  
  Widget _buildFeaturedProducts() {
    final featuredProductsAsync = ref.watch(featuredProductsProvider);
    
    return featuredProductsAsync.when(
      data: (featuredProducts) {
        if (featuredProducts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No featured products'),
            ),
          );
        }
        
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: featuredProducts.length,
          itemBuilder: (context, index) {
            final product = featuredProducts[index];
            return SizedBox(
              width: 160,
              child: ProductCard(
                product: product,
                heroTagPrefix: 'featured',
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (_, __) => const Center(
        child: Text('Error loading featured products'),
      ),
    );
  }
  
  Widget _buildBestSellers(List<Product> products) {
    final bestSellers = products.where((p) => p.isBestSeller).toList();
    
    if (bestSellers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No best sellers'),
        ),
      );
    }
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: bestSellers.length,
      itemBuilder: (context, index) {
        final product = bestSellers[index];
        return SizedBox(
          width: 160,
          child: ProductCard(
            product: product,
            heroTagPrefix: 'bestseller',
          ),
        );
      },
    );
  }
  
  Widget _buildNewArrivals(List<Product> products) {
    final newArrivals = products.where((p) => p.isNew).toList();
    
    if (newArrivals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No new arrivals'),
        ),
      );
    }
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: newArrivals.length,
      itemBuilder: (context, index) {
        final product = newArrivals[index];
        return SizedBox(
          width: 160,
          child: ProductCard(
            product: product,
            heroTagPrefix: 'new',
          ),
        );
      },
    );
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
        return 'Technology';
      case ProductCategory.services:
        return 'Services';
      case ProductCategory.other:
        return 'Other';
    }
  }
}