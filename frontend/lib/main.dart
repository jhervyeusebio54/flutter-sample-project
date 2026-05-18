import 'package:flutter/material.dart';
import 'login_page.dart';
import 'product_list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ValueNotifier<bool>(false);
    return ValueListenableBuilder<bool>(
      valueListenable: isLoggedIn,
      builder: (context, value, _) {
        return MaterialApp(
          title: 'Products',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              secondary: Color(0xFF6C63FF),
              surface: Color(0xFF1E1E2E),
              surfaceContainerLowest: Color(0xFF13131F),
            ),
            scaffoldBackgroundColor: const Color(0xFF13131F),
            cardColor: const Color(0xFF1E1E2E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E2E),
              foregroundColor: Colors.white,
              elevation: 0,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF2A2A3E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
              ),
              labelStyle: const TextStyle(color: Color(0xFF9090A8)),
              hintStyle: const TextStyle(color: Color(0xFF9090A8)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
          ),
          home: value
              ? ProductListPage(onLogout: () => isLoggedIn.value = false)
              : LoginPage(onLoginSuccess: () => isLoggedIn.value = true),
        );
      },
    );
  }
}