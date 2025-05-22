import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/services/supabase_service.dart';
import 'package:petpal/core/services/local_storage_service.dart';
import 'package:petpal/features/auth/providers/auth_provider.dart';
import 'package:petpal/features/pets/models/pet.dart';
import 'package:uuid/uuid.dart';

/// Provider for all pets
final petsProvider = StateNotifierProvider<PetNotifier, AsyncValue<List<PetModel>>>(
  (ref) {
    final supabaseService = ref.watch(supabaseServiceProvider);
    final localStorageService = ref.watch(localStorageServiceProvider);
    final userId = ref.watch(currentUserProvider)?.id;
    
    return PetNotifier(
      supabaseService: supabaseService,
      localStorageService: localStorageService,
      userId: userId,
    );
  },
);

/// Provider for a specific pet
final petProvider = FutureProvider.family<PetModel?, String>((ref, petId) async {
  final petsAsync = ref.watch(petsProvider);
  
  if (petsAsync is AsyncData<List<PetModel>>) {
    final pets = petsAsync.value;
    return pets.firstWhere((pet) => pet.id == petId, orElse: () => null);
  }
  
  // If pets are not loaded yet, load directly from storage
  final localStorageService = ref.watch(localStorageServiceProvider);
  await localStorageService.init();
  
  return localStorageService.getPetById(petId);
});

/// Notifier for managing pets
class PetNotifier extends StateNotifier<AsyncValue<List<PetModel>>> {
  final SupabaseService _supabaseService;
  final LocalStorageService _localStorageService;
  final String? _userId;
  final _uuid = const Uuid();
  
  PetNotifier({
    required SupabaseService supabaseService,
    required LocalStorageService localStorageService,
    String? userId,
  })  : _supabaseService = supabaseService,
        _localStorageService = localStorageService,
        _userId = userId,
        super(const AsyncValue.loading()) {
    // Initialize state
    if (_userId != null) {
      loadPets();
    } else {
      state = const AsyncValue.data([]);
    }
  }
  
  /// Load all pets for current user
  Future<void> loadPets({bool forceRefresh = false}) async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    try {
      state = const AsyncValue.loading();
      
      // Initialize local storage
      await _localStorageService.init();
      
      // Load from local storage first
      final localPets = await _localStorageService.getPets();
      
      // Return local data immediately
      if (localPets.isNotEmpty && !forceRefresh) {
        state = AsyncValue.data(localPets);
      }
      
      // Then try to fetch from Supabase
      try {
        final remotePets = await _supabaseService.fetch(
          'pets',
          column: 'user_id',
          value: _userId,
        );
        
        // Convert to models
        final petModels = remotePets
            .map((json) => PetModel.fromJson(json))
            .toList();
        
        // Save to local storage
        for (final pet in petModels) {
          await _localStorageService.savePet(pet);
        }
        
        // Update state with remote data
        state = AsyncValue.data(petModels);
      } catch (e) {
        // If remote fetch fails but we have local data, keep using that
        if (localPets.isNotEmpty) {
          state = AsyncValue.data(localPets);
        } else {
          // Otherwise, show error
          state = AsyncValue.error(e, StackTrace.current);
        }
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  /// Add a new pet
  Future<String?> addPet(PetModel pet) async {
    if (_userId == null) return null;
    
    try {
      // Generate ID if not provided
      final id = pet.id.isEmpty ? _uuid.v4() : pet.id;
      
      // Create new pet with current timestamp
      final newPet = pet.copyWith(
        id: id,
        userId: _userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save to local storage
      await _localStorageService.savePet(newPet);
      
      // Update state
      state = await state.whenData((pets) => [...pets, newPet]);
      
      return id;
    } catch (e) {
      debugPrint('Error adding pet: $e');
      return null;
    }
  }
  
  /// Update an existing pet
  Future<bool> updatePet(PetModel pet) async {
    try {
      // Update timestamp
      final updatedPet = pet.copyWith(
        updatedAt: DateTime.now(),
      );
      
      // Save to local storage
      await _localStorageService.savePet(updatedPet);
      
      // Update state
      state = await state.whenData((pets) {
        final index = pets.indexWhere((p) => p.id == pet.id);
        if (index >= 0) {
          final newList = List<PetModel>.from(pets);
          newList[index] = updatedPet;
          return newList;
        }
        return pets;
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating pet: $e');
      return false;
    }
  }
  
  /// Delete a pet
  Future<bool> deletePet(String petId) async {
    try {
      // Delete from local storage
      await _localStorageService.deletePet(petId);
      
      // Update state
      state = await state.whenData((pets) => 
        pets.where((p) => p.id != petId).toList()
      );
      
      return true;
    } catch (e) {
      debugPrint('Error deleting pet: $e');
      return false;
    }
  }
  
  /// Upload a profile photo for a pet
  Future<String?> uploadProfilePhoto(String petId, File photoFile) async {
    try {
      // Upload to storage
      final path = await _supabaseService.uploadFile(
        photoFile,
        'pets/$petId/profile',
      );
      
      // Get public URL
      final photoUrl = _supabaseService.getFileUrl(path);
      
      // Update pet with new photo URL
      final petAsync = state;
      if (petAsync is AsyncData<List<PetModel>>) {
        final pets = petAsync.value;
        final pet = pets.firstWhere((p) => p.id == petId, orElse: () => null);
        
        if (pet != null) {
          final updatedPet = pet.copyWith(
            profilePhotoUrl: photoUrl,
            photoUrls: [...pet.photoUrls, photoUrl],
            updatedAt: DateTime.now(),
          );
          
          await updatePet(updatedPet);
        }
      }
      
      return photoUrl;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      return null;
    }
  }
  
  /// Add a photo to a pet's gallery
  Future<String?> addPetPhoto(String petId, File photoFile) async {
    try {
      // Upload to storage
      final path = await _supabaseService.uploadFile(
        photoFile,
        'pets/$petId/gallery',
      );
      
      // Get public URL
      final photoUrl = _supabaseService.getFileUrl(path);
      
      // Update pet with new photo URL
      final petAsync = state;
      if (petAsync is AsyncData<List<PetModel>>) {
        final pets = petAsync.value;
        final pet = pets.firstWhere((p) => p.id == petId, orElse: () => null);
        
        if (pet != null) {
          final updatedPet = pet.copyWith(
            photoUrls: [...pet.photoUrls, photoUrl],
            updatedAt: DateTime.now(),
          );
          
          await updatePet(updatedPet);
        }
      }
      
      return photoUrl;
    } catch (e) {
      debugPrint('Error adding pet photo: $e');
      return null;
    }
  }
  
  /// Update pet weight
  Future<bool> updatePetWeight(String petId, double weight) async {
    try {
      final petAsync = state;
      if (petAsync is AsyncData<List<PetModel>>) {
        final pets = petAsync.value;
        final pet = pets.firstWhere((p) => p.id == petId, orElse: () => null);
        
        if (pet != null) {
          final updatedPet = pet.copyWith(
            weight: weight,
            updatedAt: DateTime.now(),
          );
          
          return await updatePet(updatedPet);
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error updating pet weight: $e');
      return false;
    }
  }
}