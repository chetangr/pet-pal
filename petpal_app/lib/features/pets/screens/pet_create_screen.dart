import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:petpal/core/constants/app_icons.dart';
import 'package:petpal/features/pets/models/pet.dart';
import 'package:petpal/features/pets/providers/pet_provider.dart';
import 'package:petpal/features/auth/providers/auth_provider.dart';

class PetCreateScreen extends ConsumerStatefulWidget {
  const PetCreateScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PetCreateScreen> createState() => _PetCreateScreenState();
}

class _PetCreateScreenState extends ConsumerState<PetCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _microchipController = TextEditingController();
  final _notesController = TextEditingController();
  
  File? _profileImage;
  PetType _selectedType = PetType.dog;
  PetGender _selectedGender = PetGender.unknown;
  DateTime? _birthdate;
  bool _isLoading = false;
  
  final _dateFormat = DateFormat('MMM d, yyyy');
  
  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _microchipController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    
    if (picked != null && picked != _birthdate) {
      setState(() {
        _birthdate = picked;
      });
    }
  }
  
  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) {
        _showError('User not authenticated');
        return;
      }
      
      // Parse weight
      double? weight;
      if (_weightController.text.isNotEmpty) {
        weight = double.tryParse(_weightController.text.trim());
      }
      
      // Create pet object
      final pet = PetModel(
        id: '',
        name: _nameController.text.trim(),
        birthdate: _birthdate,
        type: _selectedType,
        breed: _breedController.text.trim(),
        gender: _selectedGender,
        weight: weight,
        photoUrls: [],
        profilePhotoUrl: null,
        microchipId: _microchipController.text.isEmpty 
            ? null 
            : _microchipController.text.trim(),
        notes: _notesController.text.isEmpty 
            ? null 
            : _notesController.text.trim(),
        medications: [],
        userId: userId,
        householdId: null,
        primaryVetId: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customFields: {},
      );
      
      // Save pet
      final petId = await ref.read(petsProvider.notifier).addPet(pet);
      
      if (petId == null) {
        _showError('Failed to save pet');
        return;
      }
      
      // Upload profile image if selected
      if (_profileImage != null) {
        await ref.read(petsProvider.notifier).uploadProfilePhoto(
          petId,
          _profileImage!,
        );
      }
      
      if (mounted) {
        // Navigate back to home
        context.go('/home');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pet.name} has been added!'),
          ),
        );
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Pet'),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Saving pet...',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile image
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: colorScheme.surfaceVariant,
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!) as ImageProvider
                                  : null,
                              child: _profileImage == null
                                  ? Icon(
                                      AppIcons.pet(_selectedType),
                                      size: 60,
                                      color: colorScheme.primary,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: colorScheme.onPrimary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Pet type selection
                    Text(
                      'Pet Type',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: PetType.values.map((type) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedType = type;
                                });
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: _selectedType == type
                                          ? colorScheme.primary
                                          : colorScheme.surfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      AppIcons.pet(type),
                                      color: _selectedType == type
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getPetTypeName(type),
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: _selectedType == type
                                          ? colorScheme.primary
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Basic information
                    Text(
                      'Basic Information',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Pet Name*',
                        prefixIcon: Icon(Icons.pets),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your pet\'s name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _breedController,
                      decoration: const InputDecoration(
                        labelText: 'Breed*',
                        prefixIcon: Icon(Icons.category),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your pet\'s breed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Gender selection
                    DropdownButtonFormField<PetGender>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: PetGender.values.map((gender) {
                        return DropdownMenuItem<PetGender>(
                          value: gender,
                          child: Text(_getPetGenderName(gender)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Birthdate
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Birthdate',
                            prefixIcon: Icon(Icons.cake),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          controller: TextEditingController(
                            text: _birthdate != null
                                ? _dateFormat.format(_birthdate!)
                                : '',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Weight
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        prefixIcon: Icon(AppIcons.weight),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final weight = double.tryParse(value);
                          if (weight == null || weight <= 0) {
                            return 'Please enter a valid weight';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Additional information
                    Text(
                      'Additional Information',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _microchipController,
                      decoration: const InputDecoration(
                        labelText: 'Microchip ID',
                        prefixIcon: Icon(Icons.memory),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        prefixIcon: Icon(Icons.note),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _savePet,
                        child: const Text('Save Pet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  String _getPetTypeName(PetType type) {
    switch (type) {
      case PetType.dog:
        return 'Dog';
      case PetType.cat:
        return 'Cat';
      case PetType.bird:
        return 'Bird';
      case PetType.fish:
        return 'Fish';
      case PetType.reptile:
        return 'Reptile';
      case PetType.smallPet:
        return 'Small Pet';
      case PetType.other:
        return 'Other';
    }
  }
  
  String _getPetGenderName(PetGender gender) {
    switch (gender) {
      case PetGender.male:
        return 'Male';
      case PetGender.female:
        return 'Female';
      case PetGender.unknown:
        return 'Unknown';
    }
  }
}

extension PetTypeIcons on AppIcons {
  static IconData pet(PetType type) {
    switch (type) {
      case PetType.dog:
        return AppIcons.dog;
      case PetType.cat:
        return AppIcons.cat;
      case PetType.bird:
        return AppIcons.bird;
      case PetType.fish:
        return AppIcons.fish;
      case PetType.reptile:
        return AppIcons.reptile;
      case PetType.smallPet:
        return AppIcons.smallPet;
      case PetType.other:
        return AppIcons.other;
    }
  }
}