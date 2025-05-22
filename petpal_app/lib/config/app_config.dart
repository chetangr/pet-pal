class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // API Keys
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  // App Settings
  static const String appName = 'PetPal';
  static const String appVersion = '1.0.0';
  static const int syncIntervalMinutes = 5;
  
  // Subscription Tiers
  static final Map<String, SubscriptionTier> subscriptionTiers = {
    'free': SubscriptionTier(
      id: 'free',
      name: 'Free',
      price: 0,
      petLimit: 2,
      storageLimit: 50, // MB
      features: {
        'basic_pet_profiles': true,
        'medication_tracking': true,
        'basic_reminders': true,
        'barcode_scanning': false,
        'ai_analysis': false,
        'export': false,
        'lost_mode': false,
        'household_members': 2,
        'chat': false,
        'wearable_integration': false,
      },
    ),
    'premium': SubscriptionTier(
      id: 'premium',
      name: 'Premium',
      price: 4.99,
      petLimit: 10,
      storageLimit: 2048, // MB (2GB)
      features: {
        'basic_pet_profiles': true,
        'medication_tracking': true,
        'basic_reminders': true,
        'advanced_reminders': true,
        'barcode_scanning': true,
        'ai_analysis': true,
        'export': true,
        'lost_mode': true,
        'household_members': 5,
        'chat': true,
        'wearable_integration': false,
      },
    ),
    'pro': SubscriptionTier(
      id: 'pro',
      name: 'Pro',
      price: 9.99,
      petLimit: 0, // Unlimited
      storageLimit: 10240, // MB (10GB)
      features: {
        'basic_pet_profiles': true,
        'medication_tracking': true,
        'basic_reminders': true,
        'advanced_reminders': true,
        'barcode_scanning': true,
        'ai_analysis': true,
        'export': true,
        'lost_mode': true,
        'advanced_lost_mode': true,
        'household_members': 15,
        'chat': true,
        'wearable_integration': true,
        'priority_support': true,
      },
    ),
  };
}

class SubscriptionTier {
  final String id;
  final String name;
  final double price;
  final int petLimit;
  final int storageLimit; // In MB
  final Map<String, dynamic> features;
  
  const SubscriptionTier({
    required this.id,
    required this.name,
    required this.price,
    required this.petLimit,
    required this.storageLimit,
    required this.features,
  });
  
  bool hasFeature(String featureKey) {
    return features[featureKey] == true;
  }
}