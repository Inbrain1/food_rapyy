// lib/main.dart
import 'package:flutter/material.dart';
import 'package:food_chifa/screeens/waiter_new_screen.dart';
import 'package:provider/provider.dart';
import 'bootstrap/app_booststrap.dart';
import 'controllers/session_controller.dart';
import 'models/app_user.dart';
import 'services/auth_service.dart';
import 'screeens/login_screen.dart';
import 'screeens/register_screen.dart';
import 'screeens/waiter_screen.dart';
import 'screeens/waiter_history_screen.dart';

void main() async {
  await bootstrapApp();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final auth = AuthService();
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionController(auth)),
      ],
      child: MaterialApp(
        title: 'Pedidos (Mozo)',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        navigatorKey: _navKey,
        routes: {
          '/login': (_) => LoginScreen(auth: auth, onLogged: _goByRole),
          '/register': (_) => RegisterScreen(auth: auth, onRegistered: _goByRole),
          '/waiter': (_) => WaiterScreen(auth: auth),
          '/waiter/new': (_) => const WaiterNewOrderScreen(),
          '/waiter/history': (_) => const WaiterHistoryScreen(),
        },
        home: AuthGate(auth: auth, goByRole: _goByRole),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  void _goByRole(AppUser user) {
    final nav = _navKey.currentState;
    const route = '/waiter';
    if (nav == null) return;
    nav.pushNamedAndRemoveUntil(route, (r) => false);
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth, required this.goByRole});
  final AuthService auth;
  final void Function(AppUser) goByRole;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return StreamBuilder(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!session.isLoggedIn) {
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
            return WaiterScreen(auth: auth);
          },
        );
      },
    );
  }
}