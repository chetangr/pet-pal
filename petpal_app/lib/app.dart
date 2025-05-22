import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:petpal/config/app_theme.dart';
import 'package:petpal/config/app_routes.dart';
import 'package:petpal/features/auth/providers/auth_provider.dart';
import 'package:petpal/features/settings/providers/settings_provider.dart';

class PetPalApp extends ConsumerWidget {
  const PetPalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);
    
    return MaterialApp.router(
      title: 'PetPal',
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('es', ''), // Spanish
        Locale('fr', ''), // French
        Locale('de', ''), // German
      ],
    );
  }
}