import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/perfil_provider.dart';
import 'providers/actualizacion_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://ngcaeweklrqrprhqmdxw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nY2Fld2VrbHJxcnByaHFtZHh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQzMzA3ODgsImV4cCI6MjA5OTkwNjc4OH0.92lGbaD5MT28AccUWTtTxgOkQn_koRtOXZW3jAWR-xU',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PerfilProvider()),
        ChangeNotifierProvider(create: (_) => ActualizacionProvider()),
      ],
      child: MaterialApp(
        title: 'eSports Deck',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),

        home: const LoginScreen(),
      ),
    );
  }
}