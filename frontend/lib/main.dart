import 'package:flutter/material.dart';
import 'login_page.dart';
import 'product_list_page.dart';


void main() {
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      home: ValueListenableBuilder(
        valueListenable: isLoggedIn,
        builder: (context, value, _) {
          return value
              ? ProductListPage()
              : LoginPage(onLoginSuccess: () => isLoggedIn.value = true);
        },
      ),
    );
  }
}


