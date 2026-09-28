import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_onboarding_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class HomeSessionScreen extends StatefulWidget {
  const HomeSessionScreen({super.key});

  @override
  State<HomeSessionScreen> createState() => _HomeSessionScreenState();
}

class _HomeSessionScreenState extends State<HomeSessionScreen> {
  late Future<bool> _hasHome;

  @override
  void initState() {
    super.initState();
    _hasHome = _loadHomeMembership();
  }

  Future<bool> _loadHomeMembership() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('home_id')
        .eq('id', user.id)
        .maybeSingle();
    final homeId = profile?['home_id'];
    return homeId is String && homeId.isNotEmpty;
  }

  void _retry() {
    setState(() => _hasHome = _loadHomeMembership());
  }

  @override
  Widget build(BuildContext context) {
    if (Supabase.instance.client.auth.currentSession == null) {
      return const LoginScreen();
    }

    return FutureBuilder<bool>(
      future: _hasHome,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ProfileLoadError(onRetry: _retry);
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!
            ? const HomeScreen()
            : const HomeOnboardingScreen();
      },
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProfileLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudo cargar tu perfil.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
