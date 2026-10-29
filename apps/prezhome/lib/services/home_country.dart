import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/country.dart';

/// País del hogar actual (`homes.country_code`); España hasta que se lee.
/// Las pantallas que muestran dinero lo leen al pintarse.
class HomeCountry {
  static final ValueNotifier<Country> current = ValueNotifier(
    Country.all.first,
  );

  /// Lee el país del hogar. Si el hogar aún no tiene (recién creado), guarda
  /// el del móvil.
  static Future<void> load(SupabaseClient client) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return;
      final profile = await client
          .from('profiles')
          .select('home_id')
          .eq('id', user.id)
          .maybeSingle();
      final homeId = profile?['home_id'] as String?;
      if (homeId == null) return;
      final home = await client
          .from('homes')
          .select('country_code')
          .eq('id', homeId)
          .maybeSingle();
      final code = home?['country_code'] as String?;
      if (code == null) {
        final device = PlatformDispatcher.instance.locale.countryCode;
        await set(client, homeId, Country.of(device));
      } else {
        current.value = Country.of(code);
      }
    } catch (_) {}
  }

  static Future<void> set(
    SupabaseClient client,
    String homeId,
    Country country,
  ) async {
    await client
        .from('homes')
        .update({'country_code': country.code})
        .eq('id', homeId);
    current.value = country;
  }
}
