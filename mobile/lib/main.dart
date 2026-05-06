import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/orders_provider.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/firebase_service.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/admin_menu_screen.dart';
import 'screens/admin_banners_screen.dart';
import 'screens/admin_products_screen.dart';
import 'screens/admin_orders_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/orders_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  try {
    await FirebaseService.initialize();
  } catch (e) {
    print('⚠️  Aviso: Firebase não inicializado. Continuando sem Firebase.');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late AuthProvider _authProvider;
  late AdminProvider _adminProvider;
  late FavoritesProvider _favoritesProvider;
  late ApiService _apiService;
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeProviders();
    _handleIncomingLinks();
  }

  Future<void> _initializeProviders() async {
    final storageService = StorageService();
    _apiService = ApiService();

    _authProvider = AuthProvider(
      apiService: _apiService,
      storageService: storageService,
    );

    _adminProvider = AdminProvider(apiService: _apiService);
    _favoritesProvider = FavoritesProvider(apiService: _apiService);

    await _authProvider.init();
  }

  void _handleIncomingLinks() {
    // Handle deep links quando o app já está aberto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
      if (uri != '/' && uri.isNotEmpty) {
        _handleDeepLink(Uri.parse(uri));
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'lejdoces' && uri.path == '/reset-password') {
      // Navegar para a tela de reset de senha
      navigatorKey.currentState?.pushNamed('/reset-password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mostrar loading enquanto inicializa
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
            ChangeNotifierProvider<AdminProvider>.value(value: _adminProvider),
            ChangeNotifierProvider<FavoritesProvider>.value(value: _favoritesProvider),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrdersProvider(apiService: _apiService)),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'L&J Doces e Salgados',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            debugShowCheckedModeBanner: false,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                // Mostrar splash screen enquanto carrega
                if (authProvider.isLoading) {
                  return const SplashScreen();
                }

                // O aplicativo sempre iniciará na HomeScreen agora
                return HomeScreen(key: HomeScreen.globalKey);
              },
            ),
            routes: {
              '/signin': (context) => const SignInScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/reset-password': (context) => const ResetPasswordScreen(),
              '/home': (context) => const HomeScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/checkout': (context) => const CheckoutScreen(),
              '/orders': (context) => const OrdersScreen(),
              '/admin': (context) => const AdminMenuScreen(),
              '/admin/banners': (context) => const AdminBannersScreen(),
              '/admin/products': (context) => const AdminProductsScreen(),
              '/admin/orders': (context) => const AdminOrdersScreen(),
            },
            onGenerateRoute: (settings) {
              // Handle deep links
              if (settings.name != null) {
                final uri = Uri.parse(settings.name!);
                if (uri.scheme == 'lejdoces' && uri.path == '/reset-password') {
                  return MaterialPageRoute(
                    builder: (context) => const ResetPasswordScreen(),
                  );
                }
              }
              return null;
            },
          ),
        );
      },
    );
  }
}
