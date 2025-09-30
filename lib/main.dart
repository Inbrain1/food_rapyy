import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/models/app_user.dart';
import 'core/services/auth_service.dart';
import 'core/services/kitchen_service.dart';
import 'core/services/orders_service.dart';
import 'features/auth/screeens/kitchen_screen.dart';
import 'features/auth/screeens/login_screen.dart';
import 'features/auth/screeens/register_screen.dart';
import 'features/auth/screeens/waiter_history_screen.dart';
import 'features/auth/screeens/waiter_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<OrdersService>(create: (_) => OrdersService()),
        Provider<KitchenService>(create: (_) => KitchenService()),
      ],
      child: const App(),
    ),
  );
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthService auth;
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    auth = context.read<AuthService>();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pedidos',
      theme: AppTheme.lightTheme,
      navigatorKey: _navKey,
      routes: {
        '/login': (_) => LoginScreen(auth: auth, onLogged: _goByRole),
        '/register': (_) => RegisterScreen(auth: auth, onRegistered: _goByRole),
        '/waiter': (_) => WaiterScreen(auth: auth),
        '/kitchen': (_) => const KitchenScreen(),
        '/waiter/history': (_) => const WaiterHistoryScreen(),
      },
      home: AuthGate(auth: auth, goByRole: _goByRole),
      debugShowCheckedModeBanner: false,
    );
  }

  void _goByRole(AppUser user) {
    final nav = _navKey.currentState;
    if (nav == null) return;
    final route = user.isKitchen ? '/kitchen' : '/waiter';
    nav.pushNamedAndRemoveUntil(route, (r) => false);
  }
}

// --- AuthGate AHORA ESTÁ FUERA DE _AppState ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth, required this.goByRole});
  final AuthService auth;
  final void Function(AppUser) goByRole;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) {
          return LoginScreen(auth: auth, onLogged: goByRole);
        }
        return FutureBuilder<AppUser?>(
          future: auth.currentAppUser(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final user = snap.data;
            if (user == null) {
              return RegisterScreen(auth: auth, onRegistered: goByRole);
            }
            if (user.isKitchen) {
              return const KitchenScreen();
            } else {
              return WaiterScreen(auth: auth);
            }
          },
        );
      },
    );
  }
}