import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/etudiant/screens/dashboard_etudiant_screen.dart';
import 'features/technicien/screens/taches_screen.dart';
import 'features/direction/screens/dashboard_direction_screen.dart';
import 'features/admin/screens/admin_screen.dart';
import 'features/securite/screens/dashboard_securite_screen.dart';

class UniClaimApp extends ConsumerWidget {
  const UniClaimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    final router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final loggedIn = auth.isAuthenticated;
        final onLogin  = state.matchedLocation == '/login';

        if (!loggedIn && !onLogin) return '/login';
        if (loggedIn  &&  onLogin) {
          switch (auth.user?.role) {
            case 'student'    : return '/etudiant';
            case 'technician' : return '/technicien';
            case 'agent'      : return '/direction';
            case 'admin'      : return '/admin';
            case 'security'   : return '/securite';
          }
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login',
          builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/etudiant',
          builder: (_, __) => const EtudiantDashboard()),
        GoRoute(path: '/technicien',
          builder: (_, __) => const TachesScreen()),
        GoRoute(path: '/direction',
          builder: (_, __) => const DirectionDashboard()),
        GoRoute(path: '/admin',
          builder: (_, __) => const AdminScreen()),
        GoRoute(path: '/securite',
          builder: (_, __) => const SecuriteDashboard()),
      ],
    );

    return MaterialApp.router(
      title         : 'UniClaim',
      debugShowCheckedModeBanner: false,
      theme         : AppTheme.light,
      routerConfig  : router,
    );
  }
}
