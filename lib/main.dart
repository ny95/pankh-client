import 'package:flutter/material.dart';
import 'package:projectwebview/providers/common_provider.dart';
import 'package:projectwebview/providers/inbox_type_provider.dart';
import 'package:projectwebview/providers/layout_provider.dart';
import 'package:projectwebview/providers/mail_provider.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'services/hive_storage.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage.init(); // Initialize Hive
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CommonProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LayoutProvider()),
        ChangeNotifierProvider(create: (_) => InboxTypeProvider()),
        ChangeNotifierProvider(create: (_) => MailProvider()),
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
      home: const HomeScreen(),
    );
  }
}
