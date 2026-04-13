import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';
import '../services/auth_provider.dart';

/// Create GoRouter with authentication-based navigation
/// Handles redirects based on login state:
/// - If not logged in: redirect to /login
/// - If logged in: redirect to /home
GoRouter createGoRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: authProvider.isLoggedIn ? '/home' : '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainScreen(),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isGoingToLogin = state.matchedLocation == '/login'; // explain this please : 

      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }

      if (isLoggedIn && isGoingToLogin) {
        return '/home';
      }

      return null;
    },
  );
}
