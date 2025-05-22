import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/services/supabase_service.dart';
import 'package:petpal/core/services/local_storage_service.dart';
import 'package:petpal/features/auth/providers/auth_provider.dart';
import 'package:petpal/features/store/models/product.dart';
import 'package:petpal/features/pets/providers/pet_provider.dart';

/// Provider for all products
final productsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>(
  (ref) {
    final supabaseService = ref.watch(supabaseServiceProvider);
    final localStorageService = ref.watch(localStorageServiceProvider);
    
    return ProductsNotifier(
      supabaseService: supabaseService,
      localStorageService: localStorageService,
    );
  },
);

/// Provider for featured products
final featuredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  
  return productsAsync.whenData((products) {
    return products.where((product) => product.isFeatured).toList();
  });
});

/// Provider for best seller products
final bestSellerProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  
  return productsAsync.whenData((products) {
    return products.where((product) => product.isBestSeller).toList();
  });
});

/// Provider for new products
final newProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  
  return productsAsync.whenData((products) {
    return products.where((product) => product.isNew).toList();
  });
});

/// Provider for products by category
final productsByCategoryProvider = Provider.family<AsyncValue<List<Product>>, ProductCategory>((ref, category) {
  final productsAsync = ref.watch(productsProvider);
  
  return productsAsync.whenData((products) {
    return products.where((product) => product.category == category).toList();
  });
});

/// Provider for products by pet type
final productsByPetTypeProvider = Provider.family<AsyncValue<List<Product>>, String>((ref, petType) {
  final productsAsync = ref.watch(productsProvider);
  
  return productsAsync.whenData((products) {
    return products.where((product) => product.forPetTypes.contains(petType)).toList();
  });
});

/// Provider for recommended products for a pet
final recommendedProductsProvider = FutureProvider.family<List<Product>, String>((ref, petId) async {
  final petAsync = ref.watch(petProvider(petId));
  final productsAsync = ref.watch(productsProvider);
  
  // Wait for both pet and products to load
  if (petAsync is! AsyncData || productsAsync is! AsyncData) {
    return [];
  }
  
  final pet = petAsync.value;
  if (pet == null) return [];
  
  final products = productsAsync.value;
  
  // Filter products suitable for this pet type
  final suitableProducts = products
      .where((product) => product.forPetTypes.contains(pet.type.name.toLowerCase()))
      .toList();
  
  // Custom recommendation logic could be implemented here
  // For now, simply return suitable products sorted by rating
  suitableProducts.sort((a, b) {
    if (a.rating == null && b.rating == null) return 0;
    if (a.rating == null) return 1;
    if (b.rating == null) return -1;
    return b.rating!.compareTo(a.rating!);
  });
  
  // Return top 10 recommended products
  return suitableProducts.take(10).toList();
});

/// Provider for product search
final productSearchProvider = StateProvider.family<List<Product>, String>((ref, query) {
  final productsAsync = ref.watch(productsProvider);
  
  if (query.isEmpty || productsAsync is! AsyncData) {
    return [];
  }
  
  final products = productsAsync.value;
  final normalizedQuery = query.toLowerCase();
  
  // Search in name, description, brand, and tags
  return products.where((product) {
    return product.name.toLowerCase().contains(normalizedQuery) ||
           product.description.toLowerCase().contains(normalizedQuery) ||
           product.brand.toLowerCase().contains(normalizedQuery) ||
           product.tags.any((tag) => tag.toLowerCase().contains(normalizedQuery));
  }).toList();
});

/// Provider for shopping cart
final cartProvider = StateNotifierProvider<CartNotifier, Map<String, int>>((ref) {
  final user = ref.watch(currentUserProvider);
  
  return CartNotifier(userId: user?.id);
});

/// Provider for cart total
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  final productsAsync = ref.watch(productsProvider);
  
  if (productsAsync is! AsyncData) return 0.0;
  
  final products = productsAsync.value;
  double total = 0.0;
  
  cart.forEach((productId, quantity) {
    final product = products.firstWhere(
      (p) => p.id == productId,
      orElse: () => null!,
    );
    
    if (product != null) {
      total += product.discountedPrice * quantity;
    }
  });
  
  return total;
});

/// Provider for cart item count
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  
  int count = 0;
  cart.forEach((_, quantity) => count += quantity);
  
  return count;
});

/// Notifier for managing products
class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final SupabaseService _supabaseService;
  final LocalStorageService _localStorageService;
  
  ProductsNotifier({
    required SupabaseService supabaseService,
    required LocalStorageService localStorageService,
  })  : _supabaseService = supabaseService,
        _localStorageService = localStorageService,
        super(const AsyncValue.loading()) {
    // Initialize state
    loadProducts();
  }
  
  /// Load products
  Future<void> loadProducts({bool forceRefresh = false}) async {
    try {
      state = const AsyncValue.loading();
      
      // Initialize local storage
      await _localStorageService.init();
      
      // TODO: Implement local storage for products
      
      // Fetch from Supabase
      try {
        final remoteProducts = await _supabaseService.fetch(
          'products',
          orderBy: 'name',
        );
        
        // Convert to models
        final productModels = remoteProducts
            .map((json) => Product.fromJson(json))
            .toList();
        
        // Update state with remote data
        state = AsyncValue.data(productModels);
      } catch (e) {
        // Show error
        state = AsyncValue.error(e, StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  /// Get product by ID
  Product? getProductById(String productId) {
    if (state is AsyncData<List<Product>>) {
      final products = (state as AsyncData<List<Product>>).value;
      
      return products.firstWhere(
        (product) => product.id == productId,
        orElse: () => null!,
      );
    }
    
    return null;
  }
  
  /// Filter products by category
  List<Product> filterByCategory(ProductCategory category) {
    if (state is AsyncData<List<Product>>) {
      final products = (state as AsyncData<List<Product>>).value;
      
      return products.where((product) => product.category == category).toList();
    }
    
    return [];
  }
  
  /// Filter products by pet type
  List<Product> filterByPetType(String petType) {
    if (state is AsyncData<List<Product>>) {
      final products = (state as AsyncData<List<Product>>).value;
      
      return products.where((product) => product.forPetTypes.contains(petType)).toList();
    }
    
    return [];
  }
  
  /// Search products
  List<Product> searchProducts(String query) {
    if (query.isEmpty || state is! AsyncData<List<Product>>) {
      return [];
    }
    
    final products = (state as AsyncData<List<Product>>).value;
    final normalizedQuery = query.toLowerCase();
    
    return products.where((product) {
      return product.name.toLowerCase().contains(normalizedQuery) ||
             product.description.toLowerCase().contains(normalizedQuery) ||
             product.brand.toLowerCase().contains(normalizedQuery) ||
             product.tags.any((tag) => tag.toLowerCase().contains(normalizedQuery));
    }).toList();
  }
}

/// Notifier for managing shopping cart
class CartNotifier extends StateNotifier<Map<String, int>> {
  final String? userId;
  
  CartNotifier({this.userId}) : super({});
  
  /// Add product to cart
  void addToCart(String productId, {int quantity = 1}) {
    final currentQuantity = state[productId] ?? 0;
    
    final updatedCart = Map<String, int>.from(state);
    updatedCart[productId] = currentQuantity + quantity;
    
    state = updatedCart;
  }
  
  /// Remove product from cart
  void removeFromCart(String productId) {
    if (!state.containsKey(productId)) return;
    
    final updatedCart = Map<String, int>.from(state);
    updatedCart.remove(productId);
    
    state = updatedCart;
  }
  
  /// Update product quantity
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    
    final updatedCart = Map<String, int>.from(state);
    updatedCart[productId] = quantity;
    
    state = updatedCart;
  }
  
  /// Clear cart
  void clearCart() {
    state = {};
  }
  
  /// Check if product is in cart
  bool isInCart(String productId) {
    return state.containsKey(productId);
  }
  
  /// Get product quantity
  int getQuantity(String productId) {
    return state[productId] ?? 0;
  }
}