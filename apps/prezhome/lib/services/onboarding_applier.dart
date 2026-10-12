import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_prefs.dart';
import '../models/onboarding_answers.dart';
import 'offline_provider.dart';

/// Aplica las respuestas del cuestionario inicial (guardadas en el
/// dispositivo antes de crear la cuenta) cuando el usuario ya tiene hogar:
/// - preferencias del perfil (módulos, estilo de cocina, tarjetas de Inicio);
/// - supermercados del hogar, solo si el hogar aún no tiene ninguno.
/// Si todo va bien se borran del dispositivo; si falla, se reintenta en el
/// siguiente arranque.
class OnboardingApplier {
  OnboardingApplier._();

  /// Devuelve true si había respuestas pendientes y se aplicaron.
  static Future<bool> applyIfPending(SupabaseClient client) async {
    final store = OfflineProvider.instance.store;
    final OnboardingAnswers? answers;
    try {
      answers = OnboardingAnswers.decode(
        await store.read(OnboardingAnswers.storageKey),
      );
    } catch (_) {
      return false;
    }
    if (answers == null) return false;

    try {
      final user = client.auth.currentUser;
      if (user == null) return false;
      final row = await client
          .from('profiles')
          .select('home_id, dashboard_prefs')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = row?['home_id'] as String?;
      if (homeId == null) return false; // aún sin hogar: esperar

      final raw = row?['dashboard_prefs'];
      final base = raw is Map
          ? DashboardPrefs.fromJson(Map<String, dynamic>.from(raw))
          : DashboardPrefs.defaults();
      await client
          .from('profiles')
          .update({'dashboard_prefs': answers.applyTo(base).toJson()})
          .eq('id', user.id);

      if (answers.supermarkets.isNotEmpty) {
        final home = await client
            .from('homes')
            .select('supermarkets')
            .eq('id', homeId)
            .maybeSingle();
        final current = home?['supermarkets'];
        if (current is! List || current.isEmpty) {
          await client
              .from('homes')
              .update({'supermarkets': answers.supermarkets})
              .eq('id', homeId);
        }
      }

      await store.remove(OnboardingAnswers.storageKey);
      return true;
    } catch (e) {
      debugPrint('OnboardingApplier error: $e');
      return false;
    }
  }
}
