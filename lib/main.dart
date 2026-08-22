import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/provider/bottom_navigation_provider.dart';
import 'package:chat_app/provider/theme_provider.dart';
import 'package:chat_app/screens/create_pin.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/screens/pin_input_screen.dart';
import 'package:chat_app/services/app_update_service.dart';
import 'package:chat_app/services/notification_service.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

final navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await FirebaseNotificationService().initialize();
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeProvider themeChangeProvider = ThemeProvider();

  void getCurrentAppTheme() async {
    themeChangeProvider.setDarkTheme = await themeChangeProvider.darkThemePrefs
        .getTheme();
  }

  @override
  void initState() {
    super.initState();
    getCurrentAppTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BottomBarProvider()),
        ChangeNotifierProvider(create: (_) => themeChangeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.getDarkTheme
                ? ThemeMode.dark
                : ThemeMode.light,
            navigatorKey: navigatorKey,
            builder: (context, child) {
              final easyLoadingChild = EasyLoading.init()(context, child);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: easyLoadingChild,
              );
            },
            debugShowCheckedModeBanner: false,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasData && snapshot.data != null) {
                  return UserDataFetcher(uid: snapshot.data!.uid);
                }

                return const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}

class UserDataFetcher extends StatefulWidget {
  final String uid;
  const UserDataFetcher({super.key, required this.uid});

  @override
  State<UserDataFetcher> createState() => _UserDataFetcherState();
}

class _UserDataFetcherState extends State<UserDataFetcher> {
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the Future once when this widget is first created
    _userFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {
          final snapData = snapshot.data!;
          final bool hasPin = snapData.data()?['hasPin'] ?? false;

          if (hasPin) {
            return PinInputScreen(id: widget.uid, userData: snapData);
          } else {
            return CreatePinScreen(id: widget.uid);
          }
        }

        // Fallback if document doesn't exist or fetch failed
        return const LoginScreen();
      },
    );
  }
}
