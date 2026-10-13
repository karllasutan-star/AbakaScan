import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_providers.dart';
import '../screens/about_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/classify_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/history_screen.dart';
import '../screens/login_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/public_home_screen.dart';
import '../services/api_services.dart';
import 'theme.dart';

class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String about = '/about';
  static const String classify = '/classify';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String history = '/history';
  static const String admin = '/admin';
}

class AbakaScanApp extends StatefulWidget {
  const AbakaScanApp({super.key});

  @override
  State<AbakaScanApp> createState() => _AbakaScanAppState();
}

class _AbakaScanAppState extends State<AbakaScanApp> {
  late final ApiClient _apiClient;

  late final AuthService _authService;

  late final ClassificationService _classificationService;

  late final AdminService _adminService;

  @override
  void initState() {
    super.initState();

    _apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);

    _authService = AuthService(_apiClient);

    _classificationService = ClassificationService(_apiClient);

    _adminService = AdminService(_apiClient);
  }

  @override
  void dispose() {
    _apiClient.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(_authService),
        ),

        ChangeNotifierProvider<ImageSelectionProvider>(
          create: (_) => ImageSelectionProvider(),
        ),

        ChangeNotifierProvider<ClassificationProvider>(
          create: (_) => ClassificationProvider(_classificationService),
        ),

        ChangeNotifierProvider<HistoryProvider>(
          create: (_) => HistoryProvider(_classificationService),
        ),

        ChangeNotifierProvider<AdminProvider>(
          create: (_) => AdminProvider(_adminService),
        ),
      ],
      child: MaterialApp(
        title: 'ABAKASCAN',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _AuthGate(),
        onGenerateRoute: _generateRoute,
        onUnknownRoute: _unknownRoute,
      ),
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    final routeName = settings.name;

    switch (routeName) {
      case AppRoutes.home:
        return _pageRoute(settings: settings, child: const _AuthGate());

      case AppRoutes.about:
        return _pageRoute(settings: settings, child: const AboutScreen());

      case AppRoutes.classify:
        return _pageRoute(settings: settings, child: const ClassifyScreen());

      case AppRoutes.login:
        return _pageRoute(settings: settings, child: const LoginScreen());

      case AppRoutes.register:
        return _pageRoute(
          settings: settings,
          child: const LoginScreen(startInRegisterMode: true),
        );

      case AppRoutes.dashboard:
        return _pageRoute(
          settings: settings,
          child: const _UserRouteGuard(child: DashboardScreen()),
        );

      case AppRoutes.history:
        return _pageRoute(
          settings: settings,
          child: const _UserRouteGuard(child: HistoryScreen()),
        );

      case AppRoutes.admin:
        return _pageRoute(
          settings: settings,
          child: const _AdminRouteGuard(child: AdminScreen()),
        );

      default:
        return _unknownRoute(settings);
    }
  }

  Route<dynamic> _unknownRoute(RouteSettings settings) {
    return _pageRoute(
      settings: settings,
      child: NotFoundScreen(routeName: settings.name),
    );
  }

  MaterialPageRoute<dynamic> _pageRoute({
    required RouteSettings settings,
    required Widget child,
  }) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => child,
    );
  }
}

// ============================================================
// AUTHENTICATION GATE
// ============================================================

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) {
      return;
    }

    _initialized = true;

    Future.microtask(() {
      if (!mounted) {
        return;
      }

      context.read<AuthProvider>().initializeSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.sessionInitializing ||
        authProvider.status == AuthStatus.initial) {
      return const _StartupScreen();
    }

    switch (authProvider.destination) {
      case AuthDestination.userDashboard:
        return const DashboardScreen();

      case AuthDestination.adminDashboard:
        return const AdminScreen();

      case AuthDestination.publicHome:
        return const PublicHomeScreen();
    }
  }
}

// ============================================================
// USER ROUTE GUARD
// ============================================================

class _UserRouteGuard extends StatelessWidget {
  const _UserRouteGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.sessionInitializing ||
        authProvider.status == AuthStatus.initial) {
      return const _StartupScreen();
    }

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    if (authProvider.isAdmin) {
      return const AdminScreen();
    }

    return child;
  }
}

// ============================================================
// ADMIN ROUTE GUARD
// ============================================================

class _AdminRouteGuard extends StatelessWidget {
  const _AdminRouteGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.sessionInitializing ||
        authProvider.status == AuthStatus.initial) {
      return const _StartupScreen();
    }

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    if (!authProvider.isAdmin) {
      return const DashboardScreen();
    }

    return child;
  }
}

// ============================================================
// STARTUP SCREEN
// ============================================================

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco_outlined,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                Text(
                  'ABAKASCAN',
                  style: AppTypography.label.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.8,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),

                const SizedBox(height: AppSpacing.md),

                const Text(
                  'Preparing your session...',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
