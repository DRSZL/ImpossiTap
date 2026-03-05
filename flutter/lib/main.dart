import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ImpossiTapApp());
}

class ImpossiTapApp extends StatelessWidget {
  const ImpossiTapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImpossiTap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        fontFamily: 'DMSans',
        colorScheme: const ColorScheme.dark(
          background: Color(0xFF0A0A0A),
          primary: Color(0xFFC8F55A),
          surface: Color(0xFF141414),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
