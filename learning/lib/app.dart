import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/home_binding.dart';
import 'features/home/screens/home_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return GetMaterialApp(
      title: 'Expense & Sales Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // Start app based on auth state
      initialRoute: auth.isLoggedIn ? AppRoutes.home : AppRoutes.login,

      getPages: [
        GetPage(name: AppRoutes.login, page: () => LoginScreen()),
        GetPage(name: AppRoutes.register, page: () => RegisterScreen()),
        GetPage(
          name: AppRoutes.home,
          page: () => const HomeScreen(),
          binding: HomeBinding(),
        ),
      ],
    );
  }
}
