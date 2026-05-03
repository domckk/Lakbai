import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: LakbaiApp()));
}

class LakbaiApp extends StatelessWidget {
  const LakbaiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Lakbai',
        theme: buildAppTheme(),
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      );
}
