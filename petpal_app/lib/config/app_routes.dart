import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/features/auth/providers/auth_provider.dart';
import 'package:petpal/features/auth/screens/login_screen.dart';
import 'package:petpal/features/auth/screens/signup_screen.dart';
import 'package:petpal/features/auth/screens/onboarding_screen.dart';
import 'package:petpal/features/auth/screens/forgot_password_screen.dart';
import 'package:petpal/features/home/screens/home_screen.dart';
import 'package:petpal/features/pets/screens/pet_list_screen.dart';
import 'package:petpal/features/pets/screens/pet_detail_screen.dart';
import 'package:petpal/features/pets/screens/pet_create_screen.dart';
import 'package:petpal/features/pets/screens/pet_edit_screen.dart';
import 'package:petpal/features/journal/screens/journal_list_screen.dart';
import 'package:petpal/features/journal/screens/journal_detail_screen.dart';
import 'package:petpal/features/journal/screens/journal_create_screen.dart';
import 'package:petpal/features/reminders/screens/reminder_list_screen.dart';
import 'package:petpal/features/reminders/screens/reminder_create_screen.dart';
import 'package:petpal/features/analytics/screens/analytics_screen.dart';
import 'package:petpal/features/lost_mode/screens/lost_mode_screen.dart';
import 'package:petpal/features/store/screens/store_screen.dart';
import 'package:petpal/features/settings/screens/settings_screen.dart';
import 'package:petpal/features/chat/screens/chat_list_screen.dart';
import 'package:petpal/features/chat/screens/chat_detail_screen.dart';
import 'package:petpal/widgets/scaffold_with_bottom_nav.dart';

// GoRouter configuration
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// Router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      // If not logged in, redirect to login
      final isLoggedIn = authState.hasValue && authState.value != null;
      final isOnAuthRoute = state.path?.startsWith('/auth') ?? false;
      
      // If not logged in and not on auth route, redirect to login
      if (!isLoggedIn && !isOnAuthRoute) {
        return '/auth/login';
      }
      
      // If logged in and on auth route, redirect to home
      if (isLoggedIn && isOnAuthRoute) {
        return '/home';
      }
      
      // No redirect needed
      return null;
    },
    routes: [
      // Auth routes (outside of bottom navigation)
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/auth/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithBottomNav(child: child),
        routes: [
          // Home tab
          GoRoute(
            path: '/',
            redirect: (context, state) => '/home',
          ),
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
            routes: [
              GoRoute(
                path: 'pet/:petId',
                builder: (context, state) => PetDetailScreen(
                  petId: state.pathParameters['petId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => PetEditScreen(
                      petId: state.pathParameters['petId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'analytics',
                    builder: (context, state) => AnalyticsScreen(
                      petId: state.pathParameters['petId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'lost',
                    builder: (context, state) => LostModeScreen(
                      petId: state.pathParameters['petId']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'add-pet',
                builder: (context, state) => const PetCreateScreen(),
              ),
            ],
          ),
          
          // Journal tab
          GoRoute(
            path: '/journal',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: JournalListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'entry/:entryId',
                builder: (context, state) => JournalDetailScreen(
                  entryId: state.pathParameters['entryId']!,
                ),
              ),
              GoRoute(
                path: 'create',
                builder: (context, state) => const JournalCreateScreen(),
              ),
            ],
          ),
          
          // Reminders tab
          GoRoute(
            path: '/reminders',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReminderListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const ReminderCreateScreen(),
              ),
            ],
          ),
          
          // Store tab
          GoRoute(
            path: '/store',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StoreScreen(),
            ),
          ),
          
          // More tab (includes settings, chat, etc)
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatListScreen(),
            ),
            routes: [
              GoRoute(
                path: ':chatId',
                builder: (context, state) => ChatDetailScreen(
                  chatId: state.pathParameters['chatId']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// Router
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // This is a placeholder until the provider is set up
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    ),
  ],
);