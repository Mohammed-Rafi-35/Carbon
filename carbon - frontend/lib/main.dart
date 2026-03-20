import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'themes/theme.dart';
import 'themes/util.dart';
import 'core/routing/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'presentation/widgets/offline_banner.dart';

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
  
  runApp(const ProviderScope(child: CarbonApp()));
}

class CarbonApp extends ConsumerWidget {
  const CarbonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = createTextTheme(context, "Inter", "Inter");
    final theme = MaterialTheme(textTheme);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp(
      title: 'Carbon',
      debugShowCheckedModeBanner: false,
      theme: theme.light(),
      darkTheme: theme.dark(),
      themeMode: themeMode,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRouter.splash,
      builder: (context, child) {
        return Column(
          children: [
            const OfflineBanner(),
            Expanded(child: child ?? const SizedBox()),
          ],
        );
      },
    );
  }
}
