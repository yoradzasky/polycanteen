import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'seller/features/menu/screens/menu_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // ── Mock auth: set token & role agar bisa tes tanpa login ──
  final prefs = await SharedPreferences.getInstance();
  // Ganti token ini dengan token Sanctum yang valid dari backend kamu
  // Cara dapat: POST /api/login via Postman, copy token-nya ke sini
  await prefs.setString(
    'auth_token',
    'T1|uCZxYxnB154JUr9DBkxV12q9hdMCLEQCRgtBCegl9b1e6703',
  );
  await prefs.setString(
    'user_role',
    'pemilik',
  ); // atau 'pegawai' untuk tes role lain

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PolyCanteen - Test Menu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3949AB)),
        useMaterial3: true,
      ),
      home: const MenuListScreen(),
    );
  }
}
