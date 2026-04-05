import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pankh/providers/auth_provider.dart';
import 'package:pankh/providers/common_provider.dart';
import 'package:pankh/providers/inbox_type_provider.dart';
import 'package:pankh/providers/layout_provider.dart';
import 'package:pankh/providers/mail_provider.dart';
import 'package:pankh/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'providers/theme_provider.dart';
import 'services/hive_storage.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/security/app_lock_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage.init();
  final authProvider = AuthProvider();
  await authProvider.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CommonProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LayoutProvider()),
        ChangeNotifierProvider(create: (_) => InboxTypeProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<AuthProvider, MailProvider>(
          create: (_) => MailProvider(),
          update: (_, auth, mail) => mail!..updateAuth(auth),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      theme: ThemeData(
        canvasColor: const Color(0xfff7f7fa),
        primaryColor: Colors.blue,
        cardColor: Colors.white,
        dividerColor: const Color(0x76CBCBCB),
        colorScheme: const ColorScheme.light(primary: Colors.blue),
      ),
      darkTheme: ThemeData(
        canvasColor: const Color(0xFF000000),
        cardColor: const Color(0xFF191c24),
        primaryColor: Colors.deepPurple,
        dividerColor: const Color(0x772B2C2F),
        colorScheme: const ColorScheme.dark(primary: Colors.deepPurple),
      ),
      themeMode:
          themeProvider.theme == 'light'
              ? ThemeMode.light
              : themeProvider.theme == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system,
      home: AppLockGate(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}
