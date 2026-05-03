import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/map/map_screen.dart';
import 'features/destinations/destinations_screen.dart';
import 'features/quests/quest_list_screen.dart';
import 'features/quests/quest_detail_screen.dart';
import 'features/quests/active_quest_screen.dart';
import 'features/leaderboard/leaderboard_screen.dart';
import 'features/passport/passport_screen.dart';
import 'features/rewards/rewards_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/shell/shell_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/destinations', builder: (_, __) => const DestinationsScreen()),
        GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
        GoRoute(
          path: '/quests',
          builder: (_, __) => const QuestListScreen(),
          routes: [
            GoRoute(path: ':id', builder: (_, s) => QuestDetailScreen(id: s.pathParameters['id']!)),
            GoRoute(path: ':id/active', builder: (_, s) => ActiveQuestScreen(id: s.pathParameters['id']!)),
          ],
        ),
        GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
        GoRoute(path: '/passport', builder: (_, __) => const PassportScreen()),
        GoRoute(path: '/rewards', builder: (_, __) => const RewardsScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);
