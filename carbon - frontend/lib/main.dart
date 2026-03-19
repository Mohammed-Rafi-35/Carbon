import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'themes/theme.dart';
import 'themes/util.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const CarbonApp());
}

class CarbonApp extends StatelessWidget {
  const CarbonApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = createTextTheme(context, "Inter", "Inter");
    final theme = MaterialTheme(textTheme);
    
    return MaterialApp(
      title: 'Carbon',
      debugShowCheckedModeBanner: false,
      theme: theme.dark(),
      home: const SplashScreen(),
    );
  }
}
