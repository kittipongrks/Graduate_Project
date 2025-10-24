import 'package:dahcpplication/theme/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dahcpplication/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dahcpplication/pages/page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dahcpplication/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('chatBox');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'DAHC application Flutter',
          debugShowCheckedModeBanner: false,

          theme: lightThemeData(context),
          darkTheme: darkThemeData(context),

          home: StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data != null) {
                return const ChatDiagnosisPage(); // หรือ NavigationMenu()
              }
              return const LoginPage();
            },
          ),
        );
      },
    );
  }
}
