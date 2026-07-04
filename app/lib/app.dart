import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/onboarding_provider.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';

class AbacusApp extends StatelessWidget {
  const AbacusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abacus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: context.watch<OnboardingProvider>().hasOnboarded ? const HomeShell() : const OnboardingScreen(),
    );
  }
}
