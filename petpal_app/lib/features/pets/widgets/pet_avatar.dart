import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:petpal/features/pets/models/pet.dart';
import 'package:petpal/core/constants/app_icons.dart';

class PetAvatar extends StatelessWidget {
  final PetModel pet;
  final double size;
  final bool isSelected;
  final VoidCallback? onTap;
  
  const PetAvatar({
    Key? key,
    required this.pet,
    this.size = 50,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: colorScheme.primary,
                  width: 2,
                )
              : null,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              )
          ],
        ),
        child: ClipOval(
          child: pet.profilePhotoUrl != null && pet.profilePhotoUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: pet.profilePhotoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildPlaceholder(context),
                  errorWidget: (context, url, error) => _buildPlaceholder(context),
                )
              : _buildPlaceholder(context),
        ),
      ),
    );
  }
  
  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Different colors based on pet type
    Color backgroundColor;
    switch (pet.type) {
      case PetType.dog:
        backgroundColor = Colors.brown;
        break;
      case PetType.cat:
        backgroundColor = Colors.orange;
        break;
      case PetType.bird:
        backgroundColor = Colors.blue;
        break;
      case PetType.fish:
        backgroundColor = Colors.lightBlue;
        break;
      case PetType.reptile:
        backgroundColor = Colors.green;
        break;
      case PetType.smallPet:
        backgroundColor = Colors.purple;
        break;
      case PetType.other:
      default:
        backgroundColor = colorScheme.primary;
        break;
    }
    
    // Different icons based on pet type
    IconData petIcon;
    switch (pet.type) {
      case PetType.dog:
        petIcon = AppIcons.dog;
        break;
      case PetType.cat:
        petIcon = AppIcons.cat;
        break;
      case PetType.bird:
        petIcon = AppIcons.bird;
        break;
      case PetType.fish:
        petIcon = AppIcons.fish;
        break;
      case PetType.reptile:
        petIcon = AppIcons.reptile;
        break;
      case PetType.smallPet:
        petIcon = AppIcons.smallPet;
        break;
      case PetType.other:
      default:
        petIcon = AppIcons.other;
        break;
    }
    
    return Container(
      color: backgroundColor,
      child: Center(
        child: Icon(
          petIcon,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
}