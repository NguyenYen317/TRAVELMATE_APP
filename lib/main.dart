import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/auth/auth_service.dart';
import 'features/search/provider/search_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    AuthService.instance.setFirebaseAvailability(true);
  } catch (_) {
    // Allow local auth flow even when Firebase is not configured yet.
    AuthService.instance.setFirebaseAvailability(false);
  }

  await AuthService.instance.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        // Bạn có thể thêm các Provider khác ở đây trong tương lai
      ],
      child: const TravelMateApp(),
    ),
  );
}
