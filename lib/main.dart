import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_router.dart';
import 'onboarding_page.dart';
import 'categories_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ggcvjfyqaandjapveftl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdnY3ZqZnlxYWFuZGphcHZlZnRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3NTU0NjYsImV4cCI6MjA4NDMzMTQ2Nn0.etguBa3yG1iwY0hrqXn1fVZyBc5OPxGNsfJz5Sf13-Y',
  );

  runApp(const LimiteMeiApp());
}

class LimiteMeiApp extends StatelessWidget {
  const LimiteMeiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Limite MEI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      routes: {
        '/home': (_) => const HomeRouter(),
        '/onboarding': (_) => const OnboardingPage(),
        '/login': (_) => const LoginPage(),
        '/categories': (_) => const CategoriesPage(),
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // ✅ Checa sessão primeiro (evita travar no "waiting")
        final session = supabase.auth.currentSession;
        if (session != null) return const HomeRouter();

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const LoginPage();
      },
    );
  }
}

/// ----------------------
/// TELA DE LOGIN
/// ----------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro inesperado ao efetuar login');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signup() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro inesperado ao cadastrar');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Limite MEI')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: Text(_loading ? 'Entrando...' : 'Entrar'),
              ),
            ),
            TextButton(
              onPressed: _loading ? null : _signup,
              child: const Text('Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}
